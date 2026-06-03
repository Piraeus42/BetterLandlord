# 冷启动 Continue 路径 — 保存/恢复缺口分析

## 1. 游戏存档频率

`save_game()` 调用点非常多（确认后不再列出每处）。在 Pop-up 生命周期中，每次 rent 支付、邮件处理、item 效果等都会触发 `save_game()`。单次 run 可能被 save 数十次。

每次 `save_game()` → [SaveGamePatch Postfix] → `_bh_save_rng_state()` → 更新 `rng_state.json`。这意味着 **sidecar 与 LBAL.save 的写入时机是严格同步的**。

## 2. 冷启动 Continue 路径追踪

### 2.1 正常退出（窗口关闭按钮 / 游戏内退出菜单）

```
game playing → 退出触发
  ├─ NOTIFICATION_WM_QUIT_REQUEST (1006)
  │   └─ _bh_end_run("quit") → _bh_flush() → runs/{run_id}.json 写入 ✅
  └─ Mod.Dispose() → Kill WPF + CloseJob

冷启动:
  _ready() → load_game() → 恢复 LBAL.save
  ReadyPatch → _bh_init() → 清 events, 设新 run_id
  title() → TitlePatch (空)

  玩家点 Continue:
  continue_game() → load_data()
  ContinueGamePatch → _bh_restore_rng_state()
    → rng_state.json 存在 ✓
    → 指纹 (total_runs+spins+coins) 匹配 ✓ (与 LBAL.save 同一次 save_game)
    → 19 条流精确恢复 ✓
  → 之前 flush 的 JSON 在 runs/ 目录里 ✓
```

**结论：正常退出路径完全正确，无缺口。**

### 2.2 强制关闭（Alt+F4 / 任务管理器杀进程）

```
game playing → 进程被直接终止
  ├─ NOTIFICATION_WM_QUIT_REQUEST → 可能不发送
  ├─ _bh_end_run("quit") → 可能不执行 → ❌ 无 JSON
  └─ _bh_events → 进程死亡后丢失

冷启动:
  _ready() → load_game() → LBAL.save 恢复 (来自最近一次 save_game)
  ReadyPatch → _bh_init() → _bh_events.clear() → 旧 events 永久丢失 ❌
  title()

  玩家点 Continue:
  continue_game() → load_data()
  ContinueGamePatch → _bh_restore_rng_state()
    → rng_state.json 存在 ✓ (来自同一次 save_game)
    → 指纹匹配 ✓
    → RNG 恢复到 save 时刻的精确位置 ✓

  game playing again → events 从零累积 (pre-close events 已失)
  → end → _bh_flush → runs/{new_run_id}.json
  → run_number 相同 (total_runs), run_id 不同 (unix_time)
```

**结论：RNG 恢复是好的。JSON 丢了半个 run 的事件。**

### 2.3 关键观察

`save_game()` 调用 → `_bh_save_rng_state()` → sidecar 更新。LBAL.save 和 rng_state.json **总是在同一次 `save_game()` 调用中同步写入**，不存在错位。

所以冷启动 Continue 时：
- Game state (LBAL.save) = spin N 时的快照
- RNG state (rng_state.json) = spin N 时的流位置
- 两者严格一致 ✅

**唯一缺口：spin 1 到 spin N 之间的 JSON events 在正常关闭时有 _bh_end_run("quit") 兜底，但强制关闭时无任何持久化。**

## 3. 状态机缺口汇总

| 场景 | JSON events | LBAL.save | rng_state.json | 一致性 |
|------|------------|-----------|----------------|--------|
| 正常退出 (Alt+F4 → 通知触发) | ✅ flush | ✅ 最近 save | ✅ 同 save | ✅ |
| 强制关闭 (任务管理器杀) | ❌ 丢失 | ✅ 最近 save | ✅ 同 save | RNG ✅, Events ❌ |
| 正常结束 (victory/loss) | ✅ flush | ✅ 游戏内频繁 save | ✅ flush 后最终 save | ✅ |
| 正常退出 → Continue | ✅ 有 JSON | ✅ 对应 | ✅ 对应 | ✅ |
| 强制关闭 → Continue | ❌ 丢失 | ✅ 对应 | ✅ 对应 | RNG ✅, Events 不完整 |

## 4. 方案

### 4.1 核心思路

不在 `_bh_end_run` 时才写 JSON——那依赖游戏优雅关闭，不可靠。改为 **每次 `save_game()` 时增量 dump events 到临时文件**。跑完时覆盖为最终版。强制关闭后冷启动，临时文件里的 events 就是能恢复的最好数据。

### 4.2 具体实施

**Step 1: 拆分 `_bh_flush()` 为 dump 和 flush**

```
_bh_dump_events()    ← 构建 JSON + 写 runs/{run_id}.json，不清空 _bh_events
_bh_flush()          ← 调 _bh_dump_events() + _bh_events.clear() (同现在)
```

**Step 2: SaveGamePatch 也调 dump**

保存 sidecar 的同时，dump events（不能 flush——flush 会清空，后续 spin 的 event 就没了）：

```
SaveGamePatch Postfix:
  _bh_save_rng_state()     ← 已有
  _bh_dump_events()        ← 新增：写 JSON 但不清 events
```

**Step 3: _bh_end_run 里 flush 时覆盖**

如果 run 自然结束（victory/loss/quit），`_bh_flush()` 覆盖掉之前的临时 dump。最终文件是完整的。

**Step 4: 冷启动时从临时 JSON 恢复**

`_bh_init()` 中，如果发现 `runs/{_bh_run_id}.json` 已存在（上次 save 时 dump 的），说明这是继续之前没结束的 run。保留该文件，不清 events（但 events 在进程重启后已丢失——用 JSON 里的即可）。

实际上 events 已经在进程死亡时丢失。磁盘上的 JSON 是唯一的历史记录。不需要恢复内存 events——磁盘 JSON 已经够了。

### 4.3 种子可持久化的状态机

```
New Game:
  TitleSetFloorPatch → _bh_start_run → _bh_apply_seed(读 seed_config.json)
    → _bh_init_rng(type, input) → 创建 19 条流
    → 种子信息: _bh_rng_seed_type, _bh_rng_seed_input, _bh_rng_landlord_seed

Save (每次 save_game):
  SaveGamePatch → _bh_save_rng_state()
    → rng_state.json: {seed_type, seed_input, landlord_seed, fingerprint, 19条流(state,inc)}
  + 新增: _bh_dump_events()
    → runs/{run_id}.json (增量, 不覆盖 _bh_events)

Continue (冷启动):
  continue_game → ContinueGamePatch → _bh_restore_rng_state()
    → 读 rng_state.json → 指纹匹配 → 精确恢复 19 条流 + 种子信息
    → RNG 与游戏状态同频 ✅

Normal End:
  WriteLogPatch → _bh_end_run(victory/loss)
    → _bh_flush → _bh_dump_events (覆盖) + clear events

Quit (正常退出):
  _notification(1006) → _bh_end_run(quit)
    → _bh_flush → _bh_dump_events (覆盖) + clear events

Force-close (进程死亡):
  最后一次 save_game 已经 dump 了 events
  → 冷启动时 runs/{run_id}.json 已存在 (覆盖了该 run 已发生的所有 events)
  → _bh_events 在内存中丢失, 但磁盘 JSON 完整到最后一个 save 点
```

### 4.4 改动清单

| # | 文件 | 改动 |
|---|------|------|
| 1 | `MainScriptSourceMod.cs` | 新增 `_bh_dump_events()` — 从 `_bh_flush` 抽取出只写不清理的逻辑 |
| 2 | `MainScriptSourceMod.cs` | `_bh_flush` 改为调 `_bh_dump_events` + clear |
| 3 | `SaveGamePatch.cs` | Postfix 加 `_bh_dump_events()` 调用 |
| 4 | `MainScriptSourceMod.cs` | `_bh_init` — 如果磁盘上已有 JSON 且 _bh_events 为空（冷启动正常），直接跳过 |

### 4.5 不改的部分

- Sidecar 机制不变 — 已经和 save_game 同步，fingerprint 确保一致性
- ContinueGamePatch 不变 — RNG 精确恢复已经工作
- TitlePatch / TitleSetFloorPatch — 不变
- seed_config.json 机制不变
