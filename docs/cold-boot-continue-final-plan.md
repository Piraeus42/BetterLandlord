# 冷启动 Continue — 最终调整方案

## 架构师的致命漏洞指正

上一版方案漏了一个关键问题：**Continue 后内存是空的，但磁盘 JSON 有旧 events。下一次 `save_game()` 触发 dump 会把只有几条新 event 的内存覆盖掉磁盘上完整的旧 JSON。**

必须补上"反向加载"：Continue 时把磁盘 JSON 的 events 回填到 `_bh_events`。

## 又一个必须处理的问题：重复事件

但是简单加载全部 events 会产生重复。原因：

```
game save 时刻:     spin=50, 磁盘 JSON 有 events up to spin=100 (增量 dump 累积的)
force-close 时刻:   spin=100
Continue 恢复:      spin=50 (LBAL.save 的 save 点)
Continue 新 events: spin=50~100 会重新产生

如果直接加载全部 100 条 events:
  old events (spins 1-100) + new events (spins 50-100) = spins 50-100 重复
```

**解决：truncate 到 save 点。** RNG sidecar 里已经存了 `fingerprint: {spins, ...}`。加载磁盘 JSON 时，丢弃 `spin_num > save_spins` 的事件，只保留 save 点之前的。

## 最终方案

### 改动 1: sidecar 增加 `save_spins`

`_bh_save_rng_state()` 中已存储 `fingerprint.spins`。它记录的是 `save_game()` 时刻 Pop-up 的 spins 值——正是 truncate 的边界。

```
rng_state.json:
  {
    fingerprint: { total_runs, spins, coins },  ← spins = 边界
    ...
  }
```

### 改动 2: 新增 `_bh_dump_events()` — 只写不清

```gdscript
func _bh_dump_events():
    # 和 _bh_flush Phase 1-5 完全一致, 最后一步不 clear events
    # ... 构建 record ... 写 JSON ... 不调 _bh_events.clear()
```

### 改动 3: 新增 `_bh_load_events_for_continue()` — 回填 + truncate

```gdscript
func _bh_load_events_for_continue(save_spins):
    var f = File.new()
    var json_path = "user://betterHistory/runs/" + _bh_run_id + ".json"
    if not f.file_exists(json_path):
        return
    # 读 JSON, 提取 events
    # 遍历 events, 只保留 spin_num <= save_spins 的
    # 回填到 _bh_events
```

### 改动 4: SaveGamePatch 追加 dump

```csharp
// SaveGamePatch Postfix
_bh_save_rng_state()      // 已有
_bh_dump_events()          // 新增
```

### 改动 5: ContinueGamePatch 追加 load

```csharp
// ContinueGamePatch Postfix
if spins > 0:
    _bh_load_events_for_continue(saved_spins)   // 新增: 回填 events (truncate 到 save 点)
    _bh_restore_rng_state()                      // 已有
```

Truncate 边界 `saved_spins` 可以从 `rng_state.json` 的 `fingerprint.spins` 读取——在 `_bh_restore_rng_state` 之前先读一下这个值即可。

### 改动 6: `_bh_flush` 改为组合

```gdscript
func _bh_flush():
    _bh_dump_events()
    _bh_events.clear()
```

## 不改的部分

| 组件 | 状态 |
|------|------|
| RNG sidecar (序列化/恢复) | ✅ 不变，已正确 |
| TitlePatch (空) | ✅ 不变 |
| TitleSetFloorPatch (new_game flush) | ✅ 不变 |
| ContinueGamePatch (RNG 恢复) | ✅ 加 load events，其余不变 |
| SaveGamePatch | ✅ 加 dump events |
| seed_config.json | ✅ 不变 |

## 验证路径

```
1. 开一局 → 玩 10 spins → Alt+F4 强杀
2. 冷启动 → Continue → 检查 runs/{run_id}.json 仍然存在（有 10 spins 的 events）
3. 继续玩 5 spins → save_game 触发 → JSON 更新（10+5 spins，无重复）
4. 结束 run → _bh_flush → 完整 JSON
```

## 改动清单汇总

| # | 文件 | 改动 |
|---|------|------|
| 1 | `MainScriptSourceMod` | 新增 `_bh_dump_events()` — 从 `_bh_flush` 抽取只写不清的逻辑 |
| 2 | `MainScriptSourceMod` | 新增 `_bh_load_events_for_continue(save_spins)` — 读磁盘 JSON + truncate 到 save 点 |
| 3 | `MainScriptSourceMod` | `_bh_flush` 改为 `_bh_dump_events()` + `_bh_events.clear()` |
| 4 | `SaveGamePatch` | Postfix 追加 `_bh_dump_events()` |
| 5 | `ContinueGamePatch` | Postfix 追加 `_bh_load_events_for_continue()` (在 restore RNG 之前) |
| 6 | `RngInfrastructureSourceMod` | `_bh_restore_rng_state` 先读 `fingerprint.spins` 暴露给 caller |
