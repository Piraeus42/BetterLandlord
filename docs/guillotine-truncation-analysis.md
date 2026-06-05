# Guillotine 结束后 JSON 截断问题 — 静态控制流分析

## 问题摘要

Victory 后继续游玩 → 断头台精华触发游戏结束 → 历史记录 JSON 中 Victory 之后的数据全部丢失。

测试数据 (`docs/log/1780566538.*`)：
- **日志**: 350 次 SPIN，从 17:48 到 18:12，共 17948 行
- **JSON**: 仅 108 次 spin，end_time=17:54:38（VICTORY 时刻），ended_by=victory
- **丢失**: Victory 后约 242 次 spin（18 分钟游戏内容）

---

## 1. 关键 Patch 清单

| 文件 | Hook 目标 | 时机 | 触发条件 |
|------|----------|------|---------|
| `WriteLogPatch.cs` | `write_log()` Prefix | 每次写日志 | `string=="VICTORY"`→`_bh_end_run("victory")` |
| `ResolveEventPatch.cs` | `resolve_event()` Prefix | 事件解析 | `_type=="win"/"ending"`→`_bh_end_run("victory")` |
| `GuillotineEndPatch.cs` | `_process()` Prefix | 每帧 | `guillotine_essence_anim==600`→`_bh_end_run("victory")` |
| `TitlePatch.cs` | `title()` Prefix | 回到主菜单 | `_bh_events.size()>0 and not _bh_run_ended`→flush |
| `TitleSetFloorPatch.cs` | `new_game()` Prefix | 开始新游戏 | `_bh_start_run()`→清空 `_bh_events` |
| `SaveGamePatch.cs` | `save_game()` Postfix | 存档 | `_bh_dump_raw_events()`→写 sidecar |

---

## 2. 核心数据结构 (Main.tscn::1 注入变量)

```gdscript
var _bh_events = []          # 事件缓冲
var _bh_run_id = ''          # 当前 run ID
var _bh_run_ended = false    # ★ 关键守卫变量 — 一次性闩锁
```

---

## 3. 关键函数

### `_bh_end_run(result)` — MainScriptSourceMod.cs:683

```gdscript
func _bh_end_run(result):
    if _bh_run_ended:        # ← 守卫：已结束则跳过
        return
    # 检查是否有 spin 活动 (ghost run 过滤)
    if not _has_spins:
        _bh_events.clear()
        _bh_run_ended = true
        return
    _bh_run_ended = true      # ← 设置闩锁
    # 捕获 Reels + Items 最终状态
    # _bh_add_event('run_end', {...})
    _bh_flush()               # ← 写入 JSON，清空 _bh_events
```

### `_bh_flush()` — MainScriptSourceMod.cs:83

```gdscript
func _bh_flush():
    # Phase 1: 从 _bh_events 构建 all_spins
    # Phase 2: 构建 rent_cycles
    # Phase 3-4: 构建 meta + summary
    # Phase 5: 写入 JSON → user://betterHistory/runs/<run_id>.json
    f.store_string(JSON.print(record, '  '))
    _bh_events.clear()        # ← 清空事件数组！
```

### `_bh_start_run()` — MainScriptSourceMod.cs:52

```gdscript
func _bh_start_run():
    _bh_events.clear()        # ← 无条件清空
    _bh_run_ended = false     # ← 重置闩锁
    _bh_run_id = str(OS.get_unix_time())
```

---

## 4. 正常 Victory 控制流 (无 bug)

```
游戏进程                            Mod 注入
─────────                          ────────
spin 完成
write_log("VICTORY")   ──→  WriteLogPatch.Prefix
                                string=="VICTORY" → _bh_end_run("victory")
                                    _bh_run_ended == false ✓ → 继续
                                    设置 _bh_run_ended = true
                                    捕获 Reels/Items/Coins/Floor
                                    _bh_add_event('run_end', {result:'victory',...})
                                    _bh_flush()
                                      → 构建 JSON (108 spins)
                                      → 写入 runs/<run_id>.json
                                      → _bh_events.clear()
```

**结果**: ✅ JSON 正确写入，结束在 Victory 时刻

---

## 5. Victory → Continue → Guillotine 控制流 (BUG)

### 阶段 1: Victory (同正常流程)

```
write_log("VICTORY")  →  _bh_end_run("victory")
                            _bh_run_ended = true   ← 闩锁设置
                            _bh_flush()             ← 写入第一次 JSON
                            _bh_events.clear()      ← 事件数组清空
```

### 阶段 2: Continue 后继续游戏 (18分钟)

```
SPIN #108 ~ #349 的游戏过程:
  SpinPatch → _bh_add_event("spin_start", ...)     ← 事件正常累积
  WriteLogPatch → _bh_add_event("spin_end", ...)    ← 事件正常累积
  WriteLogPatch → _bh_add_event("item_added", ...)  ← 事件正常累积
  BoardValuePatch → _bh_add_event("board_value", ...) ← 事件正常累积

此时状态:
  _bh_events = [spin_start#108, board_value, ..., item_added, ..., spin_end#349, ...]
  _bh_run_ended = true   ← ★ 闩锁仍为 true！
```

### 阶段 3: 断头台触发

游戏代码 (`Main.tscn__1.gd:515-558`, `Coins.tscn__1.gd:51-52`, `Items.tscn__1.gd:187-188`):

```gdscript
# Coins.tscn 或 Items.tscn 中:
if coins >= guillotine_essence_value:
    $"/root/Main".guillotine_essence_anim = 600   # 启动动画
```

```
guillotine_essence_anim = 600  每帧递减:
  
  Frame anim==600:
    GuillotineEndPatch.Prefix:
      if guillotine_essence_anim == 600:
          if _bh_events.size() > 1 and not _bh_run_ended:
              ↑
              └── _bh_run_ended == true → ★ 守卫拦截！_bh_end_run 不调用
  
  Frame anim==599:  清 tooltip, 淡出音乐
  Frame anim==330:  执行动画, 播放音效
  Frame anim==0:
    reset_values()
    title()   ──→  TitlePatch.Prefix:
                    if _bh_events.size() > 0 and not _bh_run_ended:
                        ↑
                        └── _bh_run_ended == true → ★ 守卫拦截！不 flush
```

### 阶段 4: 返回 Title 后

```
玩家点 New Game:
  TitleSetFloorPatch.Prefix:
    if _bh_events.size() > 0 and not _bh_run_ended:
        _bh_end_run("quit")         ← 守卫拦截
    _bh_start_run()                 ← ★ 无守卫！执行
      _bh_events.clear()            ← ★ 所有 post-victory 事件被清空！
      _bh_run_ended = false
```

**结果**: ❌ Post-victory 的 242 次 spin 永远丢失

---

## 6. 根因分析图

```
                    ┌──────────────────────────────────┐
                    │     _bh_run_ended = true          │
                    │     (一次性闩锁, Victory时设置)     │
                    └──────────┬───────────────────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
   ┌────────────────┐ ┌──────────────┐ ┌──────────────────┐
   │ GuillotineEnd  │ │  TitlePatch  │ │ ResolveEvent     │
   │ Patch          │ │              │ │ Patch            │
   │                │ │              │ │                  │
   │ anim==600 时   │ │ title() 时   │ │ game_over/win 时 │
   │                │ │              │ │                  │
   │ guard:         │ │ guard:       │ │ guard:           │
   │ not _bh_run_   │ │ not _bh_run_ │ │ _bh_end_run()    │
   │ ended → FALSE  │ │ ended→ FALSE │ │ 内部 guard:      │
   │                │ │              │ │ if _bh_run_ended │
   │ ❌ 不调用      │ │ ❌ 不 flush  │ │ → return         │
   │ _bh_end_run    │ │              │ │ ❌ 不执行        │
   └────────────────┘ └──────────────┘ └──────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │  _bh_start_run()     │
                    │  (下次 New Game 时)   │
                    │                      │
                    │  _bh_events.clear()  │
                    │  ★ 数据永久丢失 ★     │
                    └──────────────────────┘
```

---

## 7. 守卫位置汇总

所有检查 `_bh_run_ended` 的位置：

| 位置 | 条件 | 行为 |
|------|------|------|
| `_bh_end_run()` L684 | `if _bh_run_ended: return` | 阻止重复 flush |
| `GuillotineEndPatch` L20 | `not _bh_run_ended` | 阻止断头台 flush |
| `TitlePatch` L18 | `not _bh_run_ended` | 阻止 title flush |
| `TitleSetFloorPatch` L23 | `not _bh_run_ended` (for quit) | 阻止 quit flush |
| `ResolveEventPatch` L12-14 | 调用 `_bh_end_run`，内部 guard | 阻止二次 end_run |

**仅有一处不检查**: `TitleSetFloorPatch` L26 — `_bh_start_run()` **无条件清空** `_bh_events`。

---

## 8. 证据对照

### 测试数据 (1780566538)

| 指标 | JSON 记录值 | 日志实际值 | 结论 |
|------|-----------|-----------|------|
| total_spins | 108 | 350 (SPIN #0~#349) | 丢失 242 spins |
| end_time | 17:54:38 | 18:12:11 (最后一行) | 丢失 ~18 分钟 |
| ended_by | victory | 断头台 death (推断) | 截断在 Victory |
| final_coins | 1267 | 4.26×10²¹ (溢出) | 未捕获后续状态 |

### 日志关键时间线

```
17:48:58  游戏开始
17:54:33  --- SPIN #107 --- (Victory 前最后一 spin)
17:54:38  VICTORY ← WriteLogPatch 在此触发 _bh_end_run
17:54:49  --- SPIN #108 --- (Continue 后第一 spin，未记录)
   ...
18:12:07  --- SPIN #349 --- (最后一 spin，未记录)
18:12:11  Coin total is now 4264656645540726964224 (溢出，未记录)
[日志结束，无 GAME OVER — 符合 guillotine→title() 的行为]
```

---

## 9. 影响范围

该 bug 影响**所有** Victory 后继续游玩并再次结束的场景：

- ✅ 正常 Victory (不继续) — 不受影响
- ❌ Victory → Continue → Guillotine 死亡 — 全部 post-victory 数据丢失
- ❌ Victory → Continue → 金币归零 (正常输) — 全部 post-victory 数据丢失
- ❌ Victory → Continue → 手动回 Title — TitlePatch flush 被拦截
- ❌ Victory → Continue → 强退游戏 (Alt+F4) — 内存中事件丢失

---

## 10. 修复方向建议

核心问题: `_bh_run_ended` 是单向闩锁，设置后没有路径能在同一 run 内重置。

### 方案 A: Victory 后重置 `_bh_run_ended`（最小改动）

在成功 flush 后（例如在 `_bh_flush()` 的 `_bh_events.clear()` 之前保存事件副本），当检测到游戏继续时重置 `_bh_run_ended = false`。

**风险**: 需要可靠检测「游戏已继续」的信号。可能的 hook 点：下一个 `spin_start` 事件到达时。

### 方案 B: GuillotineEndPatch 中忽略守卫（热修复）

```gdscript
# GuillotineEndPatch — 移除 not _bh_run_ended 条件
if guillotine_essence_anim == 600 and has_method("_bh_end_run"):
    if _bh_events != null and _bh_events.size() > 1:
        _bh_end_run("victory")
```

**风险**: 如果 Victory 的 `_bh_end_run` 也在同一帧触发，可能双重 flush。但 Victory 已经 flush 过一次并清空了 `_bh_events`，所以第二次 flush 只会包含 post-victory 数据——这会导致**覆盖**第一次的完整 JSON，只留下 post-victory 部分。

### 方案 C: `_bh_flush()` 不清空事件，改为追加模式（架构改动）

将 `_bh_flush()` 从"写入完整 JSON"改为"追加写入"，允许多次 flush 合成为最终 JSON。

**风险**: 架构改动较大，影响所有现有存储逻辑。

### 方案 D: 组合方案（推荐）

1. Victory 的 `_bh_end_run("victory")` 正常执行，写入首次 JSON
2. `_bh_flush()` 完成后**不** clear `_bh_events`（或保存到备份变量 `_bh_pre_victory_events`）
3. 重置 `_bh_run_ended = false`，允许后续再次 end_run
4. 第二次 `_bh_end_run` 时，合并 `_bh_pre_victory_events` + 当前 `_bh_events`，重新 flush 完整 JSON
5. 第二次 flush 覆盖第一次的文件（相同的 `_bh_run_id`）

**优点**: 既保留了首次 Victory flush 的数据完整性（可回退），又支持后续结束时的完整重写。

---

# 第二部分：完整状态机模型

## S1. 状态定义

Mod 维护三个核心变量，定义了一个隐式状态机：

| 变量 | 类型 | 语义 |
|------|------|------|
| `_bh_events` | `Array` | 事件缓冲，`_bh_add_event()` 无条件追加 |
| `_bh_run_ended` | `bool` | **一次性闩锁**：true = run 已结束，禁止再次 end_run |
| `_bh_run_id` | `String` | 当前 run 标识，作为 JSON 文件名 |

### S1.1 显式状态（代码中有意建模的）

```
┌─────────────────────────────────────────────────────────────────────┐
│  状态名          _bh_events    _bh_run_ended   含义                   │
├─────────────────────────────────────────────────────────────────────┤
│  UNINIT          []            false           Mod 刚加载             │
│  IDLE            []            false           主菜单，无活跃 run      │
│  RUNNING         non-empty     false           游戏中，事件收集中      │
│  ENDED           []            true            Run 已 flush，空闲      │
└─────────────────────────────────────────────────────────────────────┘
```

### S1.2 隐式状态（代码未建模但游戏会产生）

```
┌─────────────────────────────────────────────────────────────────────┐
│  状态名               _bh_events    _bh_run_ended   含义              │
├─────────────────────────────────────────────────────────────────────┤
│  ENDED_CONTINUING     non-empty     true             Victory 后继续   │
│  事件在累积，但闩锁阻止任何 flush                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**ENDED_CONTINUING 是本 bug 的根本原因**：状态机在 ENDED 之后没有定义合法的出边，但游戏允许玩家在 Victory 后继续游玩，创造了这个"幽灵"状态。

---

## S2. 完整状态转移图

```
                    ┌──────────────────────────────────────────┐
                    │                                          │
                    ▼                                          │
    ┌─────────┐  T1   ┌────────┐  T2   ┌──────────┐  T3   ┌──────┐
    │ UNINIT  │──────→│  IDLE  │──────→│ RUNNING  │──────→│ENDED │
    └─────────┘       └────────┘       └──────────┘       └──────┘
                          ▲                ▲    ▲             │  │
                          │                │    │             │  │
                          │  T4            │ T6 │ T5          │  │
                          │                │    │             │  │
                          │          ┌─────┘    └─────────────┘  │
                          │          ▼ (Continue)                │
                          │    ┌─────────────────────┐           │
                          │    │ ENDED_CONTINUING    │← T7 ─────┘
                          │    │ (幽灵状态，无法 flush) │
                          │    └─────────┬───────────┘
                          │              │
                          │              │ T8 (New Game → _bh_start_run)
                          │              │ ★ 事件在此永久丢失
                          └──────────────┘
```

### S2.1 所有转移详解

| # | 转移 | 触发器 | 代码位置 | `_bh_run_ended` 变化 |
|---|------|--------|---------|---------------------|
| **T1** | UNINIT→IDLE | `_ready()` Postfix | ReadyPatch → `_bh_init()` | → false |
| **T2** | IDLE→RUNNING | `new_game()` Prefix | TitleSetFloorPatch → `_bh_start_run()` + `_bh_add_event("run_start")` | → false |
| **T3** | RUNNING→ENDED | `write_log("VICTORY"/"GAME OVER")` 或 `resolve_event("win"/"game_over")` | WriteLogPatch / ResolveEventPatch → `_bh_end_run()` | → true |
| **T4** | RUNNING→IDLE | `title()` Prefix (回主菜单但不结束游戏) | TitlePatch: snapshot flush + preserve events | → false |
| **T5** | ENDED→RUNNING | Cold-boot Continue (sidecar 加载) | ContinueGamePatch → `_bh_restore_rng_state()` → `_bh_load_events_for_continue()` | false (已由 `_bh_init` 设置) |
| **T6** | ENDED→RUNNING | Warm Continue (同 session 内继续，RNG state 未被清理) | 游戏继续，新事件自动通过 `_bh_add_event` 累积 | 保持 true (★ 问题) |
| **T7** | ENDED→ENDED_CONTINUING | Victory 后继续游玩 | 无 mod hook；Spins/items 继续触发 `_bh_add_event` | 保持 true |
| **T8** | ENDED_CONTINUING→IDLE | `new_game()` 或 `title()` 后 start new game | TitleSetFloorPatch → `_bh_start_run()` → `.clear()` | → false |
| — | ENDED_CONTINUING→ENDED | **缺失！** Guillotine / coin loss / title return 被 latch 拦截 | 所有路径的 guard 都检查 `not _bh_run_ended` | — |

---

## S3. 触发器全景

### S3.1 游戏事件 → Mod 反应矩阵

```
游戏事件                      Mod Hook              最终调用                  守卫结果
─────────────────────────────────────────────────────────────────────────────────────
_ready()                   ReadyPatch           _bh_init()                  无守卫
title() (主菜单)            TitlePatch           snapshot flush + preserve    _bh_run_ended==false
title() (via guillotine)   TitlePatch           无操作                       ★ 被 latch 拦截
new_game() (floor 已选)    TitleSetFloorPatch    _bh_start_run() + seed      仅 quit flush 有守卫
new_game() (floor 未选)    TitleSetFloorPatch    无操作                      floor_selected==false
continue_game()            ContinueGamePatch     _bh_restore_rng_state()     无守卫
write_log("VICTORY")       WriteLogPatch         _bh_end_run("victory")      if _bh_run_ended: return
write_log("GAME OVER")     WriteLogPatch         _bh_end_run("loss")         if _bh_run_ended: return
write_log(other)           WriteLogPatch         _bh_add_event(...)          无守卫 (★)
resolve_event("win")       ResolveEventPatch     _bh_end_run("victory")      if _bh_run_ended: return
resolve_event("game_over") ResolveEventPatch     _bh_end_run("loss")         if _bh_run_ended: return
save_game()                SaveGamePatch         _bh_dump_raw_events()       无守卫 (★)
                                                   + _bh_save_rng_state()
_process (每帧)            GuillotineEndPatch    _bh_end_run("victory")      ★ 被 latch 拦截
_process (每帧)            ClipboardMonitorPatch _bh_clip_sample()           无守卫
spin()                     SpinPatch             _bh_add_event("spin_start") 无守卫 (★)
check_values()             BoardValuePatch       _bh_add_event("board_value")无守卫 (★)
update_rent_values()       RentUpdatePatch       _bh_add_event("rent_updated")无守卫 (★)
_notification(1006)        (window close)        _bh_end_run("quit")         ★ 被 latch 拦截
```

**关键观察**: `_bh_add_event()` 无守卫（标 ★ 的行）—— 事件在 ENDED_CONTINUING 状态下**可以**正常积累。问题是积累后无法 flush。

### S3.2 为什么有两个 victory/loss 检测点？

```
Victory 发生时，游戏调用顺序:
  1. write_log("VICTORY")     ─→  WriteLogPatch      ─→  _bh_end_run("victory")  [先到]
  2. resolve_event("win")     ─→  ResolveEventPatch  ─→  _bh_end_run("victory")  [被 latch 拦截]

Loss 发生时:
  1. write_log("GAME OVER")   ─→  WriteLogPatch      ─→  _bh_end_run("loss")     [先到]
  2. resolve_event("game_over")─→ ResolveEventPatch  ─→  _bh_end_run("loss")     [被 latch 拦截]
```

**`_bh_run_ended` 的设计意图**: 防止 WriteLogPatch 和 ResolveEventPatch 在同一 victory/loss 中重复触发 `_bh_end_run`。无论哪个先到，另一个会被 `if _bh_run_ended: return` 拦截。

**设计评价**: 这个守卫**正确**解决了同帧双重触发的问题，但**过度泛化**——它也拦截了所有后续的合法 end_run（断头台、金币归零、强退等）。

---

## S4. `_bh_run_ended` 守卫的原始设计意图

### S4.1 它要解决的问题（设计文档推导）

原始架构的隐含假设：
```
┌─────────────────────────────────────────────────────────┐
│  假设 1: "Victory/Loss 就是 run 的终点"                    │
│  假设 2: "结局通知 (write_log + resolve_event) 可能重复"    │
│  假设 3: "title() 之后 run 就结束了，新游戏会重置一切"       │
│  假设 4: "如果 run 没正常结束就回了 title，用 snapshot 保留" │
└─────────────────────────────────────────────────────────┘
```

1. **假设 1** 在游戏设计层面就不成立——LBaLL 允许 Victory 后继续。
2. **假设 2** 成立，`_bh_run_ended` 成功解决了这个问题。
3. **假设 3** 部分成立——但 `_bh_start_run()` 的无条件 `.clear()` 会在未 flush 时丢弃数据。
4. **假设 4** 通过 TitlePatch 的 snapshot flush 实现，设计正确，但同样被 latch 拦截。

### S4.2 守卫的层次结构

```
第一层守卫 (_bh_end_run 内部):
  if _bh_run_ended: return     ← 阻止重复 end_run

第二层守卫 (调用方):
  GuillotineEndPatch:  ... and not _bh_run_ended
  TitlePatch:          ... and not _bh_run_ended
  TitleSetFloorPatch:  ... and not _bh_run_ended
  _notification(1006): ... and not _bh_run_ended
```

第一层守卫已经足够防止重复 flush。第二层守卫是**冗余的**——它们存在是为了在"run 已经结束后就不该再有 events"的假设下提前短路。但这个假设在 Victory→Continue 场景下不成立。

### S4.3 `_bh_flush()` 中 `_bh_events.clear()` 的副作用

```
_bh_end_run("victory")
  └─ _bh_flush()
       ├─ 构建 JSON (包含当前 _bh_events 中所有事件)
       ├─ 写入文件
       └─ _bh_events.clear()     ← ★ 清空事件缓冲

Continue 之后:
  SpinPatch / WriteLogPatch / BoardValuePatch
    └─ _bh_add_event(...)        ← 新事件重新累积
       _bh_events 又非空了
```

**后果**: 如果现在移除 latch 让第二次 `_bh_end_run` 通过，`_bh_flush()` 构建的 JSON **只包含 post-victory 事件**（因为 pre-victory 事件已经被 `.clear()` 清空了）。第二次 flush 会**覆盖**第一次的完整 JSON。

---

## S5. 路径逐条分析

### S5.1 正常 Victory（不继续）✅ 正确

```
RUNNING → (write_log "VICTORY") → ENDED → (title) → (new_game) → IDLE
                                       ↑
                                  TitlePatch 检测到 _bh_run_ended==true
                                  → 跳过 snapshot flush (正确，已 flush)
                                       ↑
                                  _bh_start_run() 检测到 _bh_events==[]
                                  → 正常初始化新 run
```

### S5.2 正常 Loss ✅ 正确

```
RUNNING → (write_log "GAME OVER") → ENDED → (同 Victory)
```

### S5.3 Mid-run 回 Title → Continue ✅ 正确

```
RUNNING → (title) → IDLE → (continue) → RUNNING
            ↑                      ↑
       TitlePatch:            ContinueGamePatch:
       _bh_events 非空         _bh_restore_rng_state()
       _bh_run_ended==false    loads RNG from sidecar
       → snapshot flush        _bh_run_ended 保持 false
       → restore events        → 游戏继续，事件累积
       → dump to sidecar
       → _bh_run_ended=false
```

**这是设计最好的路径**。TitlePatch 正确地在不丢失数据的前提下切换了 run 状态。

### S5.4 Victory → Continue → Guillotine ❌ BUG

```
RUNNING → (VICTORY) → ENDED → (continue playing) → ENDED_CONTINUING
                         ↑                              ↑
                    _bh_end_run:                   T6 转移 (隐式)
                    latch=true                     events 累积但无法 flush
                    events cleared
                                                         │
                    ┌────────────────────────────────────┘
                    │
                    ▼
              (guillotine_essence_anim=600)
                    │
                    ▼
              GuillotineEndPatch:
                guard: not _bh_run_ended → FALSE → 跳过
                    │
                    ▼
              (anim 结束 → title())
                    │
                    ▼
              TitlePatch:
                guard: not _bh_run_ended → FALSE → 跳过
                    │
                    ▼
              (玩家点 New Game)
                    │
                    ▼
              _bh_start_run():
                _bh_events.clear()  →  ★ 数据永久丢失
                _bh_run_ended=false
```

### S5.5 Victory → Continue → 金币归零 ❌ BUG（同类问题）

```
ENDED_CONTINUING → (coins ≤ 0) → resolve_event("game_over")
                                    → _bh_end_run("loss")
                                    → if _bh_run_ended: return ★
```

### S5.6 Cold Boot Continue (Victory 后的存档) ⚠️ 部分正确

```
游戏重启:
  _ready() → _bh_init()          → IDLE (_bh_run_ended=false, events=[])
  title() → TitlePatch           → events 为空，跳过
  continue_game() → load_data()  → 恢复 Persist 节点
  ContinueGamePatch:
    _bh_restore_rng_state()
      → 加载 sidecar (rng_state.json)
      → _bh_load_events_for_continue(save_spins)
        → guard: if _bh_events.size()>0: return  ← 空数组，通过
        → 从 events_<run_id>.json 加载事件
        → 截断到 save_spins
      → _bh_run_ended 保持 false ★ (已由 _bh_init 设置)
  
  状态 = RUNNING (_bh_run_ended=false, events 从 sidecar 恢复)
  
  如果此时 guillotine 触发:
    → _bh_run_ended==false → 通过!
    → _bh_end_run("victory") 正常执行
    → 但 flush 的 JSON 可能不完整 (取决于 sidecar 何时保存)
```

**此路径 latch 正常但数据可能不完整**: sidecar 如果是在 Victory flush 之后保存的（`_bh_dump_raw_events` 只含 post-victory 新增事件），则加载回来的 events 不含 pre-victory 部分。如果 sidecar 是在 Victory flush 之前保存的，则 events 被截断到 save_spins。

---

## S6. 架构评估

### S6.1 设计正确的地方

| 设计元素 | 评价 |
|---------|------|
| `_bh_end_run` 内部 latch | ✅ 正确防止 WriteLog+ResolveEvent 双重触发 |
| TitlePatch snapshot flush | ✅ 正确保留 mid-run 回 title 的数据，支持 Continue |
| sidecar 持久化 (RNG + events) | ✅ Cold boot Continue 的恢复路径设计合理 |
| `_bh_add_event` 无守卫 | ✅ 事件总是被捕获，不会因 latch 而丢失采集 |

### S6.2 设计缺陷

| 缺陷 | 影响 | 严重度 |
|------|------|--------|
| latch 单向不可逆 | ENDED → ENDED_CONTINUING 后无法再 flush | ★ 致命 |
| `_bh_flush().clear()` 不可恢复 | 无法合并 pre+post-victory 事件 | ★ 高 |
| 调用方守卫冗余 | 增加死路径，使 bug 更难发现 | 中 |
| `_bh_start_run().clear()` 无条件 | 幽灵状态下的事件被静默丢弃 | ★ 高 |
| 缺少 "game continued" 信号 | ENDED→ENDED_CONTINUING 转移无 hook | ★ 致命 |
| 缺少 "run truly ended" 语义 | flush 后就假设 run 结束，无后续处理 | ★ 致命 |
| 无事件持久化备份 | flush 前的 events 只在内存中，clear 后无法恢复 | 高 |

### S6.3 为什么架构没考虑到 Continue-After-Victory

```
架构师的隐含状态机:              游戏的实际状态机:

  [开始]                          [开始]
    │                               │
    ▼                               ▼
  [游戏中]                        [游戏中]
    │                               │
    ├── Victory ──→ [结束]         ├── Victory ──→ [Victory!]
    ├── Loss ────→ [结束]         │                 │
    └── Quit ────→ [结束]         │    ┌─ Continue ─┤
                                  │    │            │
                                  │    ▼            ▼
                  不同之处→       │  [继续游戏]   [回 Title]
                                  │    │
                                  │    ├── Guillotine → [结束]
                                  │    ├── Coins=0 ──→ [结束]
                                  │    └── Title ────→ [结束]
                                  │
                                  ├── Loss ────→ [结束]
                                  └── Quit ────→ [结束]
```

架构师假设 Victory 是终态，但游戏设计允许 Victory 后继续。这个**同一 run 内的多阶段生命周期**需要一个新的状态模型。

---

## S7. 正确的状态机模型

### S7.1 新的状态定义

```
┌──────────────────────────────────────────────────────────────────┐
│  状态            _bh_events    _bh_ended   含义                   │
├──────────────────────────────────────────────────────────────────┤
│  UNINIT          []            false       初始                   │
│  IDLE            []            false       主菜单                 │
│  RUNNING         non-empty     false       游戏中 (pre-victory)   │
│  WON_CONTINUING  non-empty     false★      Victory 后继续        │
│  COMPLETED       written       true        最终 JSON 已写入       │
└──────────────────────────────────────────────────────────────────┘
```

关键改变：将 `_bh_run_ended` 的语义从 "run 已结束" 改为 **"JSON 已写入"**，并引入 `WON_CONTINUING` 作为显式的可 flush 状态。

### S7.2 正确的转移图

```
                    T1         T2         T3
    ┌─────────┐ ────→ ┌────┐ ────→ ┌──────────┐ ────→ ┌───────────┐
    │ UNINIT  │       │IDLE│       │ RUNNING  │       │ COMPLETED │
    └─────────┘ ←──── └────┘ ←──── └──────────┘ ←──── └───────────┘
                    T9         T4         │  T10             ↑
                                          │                  │
                                          │ T5               │ T8
                                          ▼                  │
                                   ┌──────────────┐         │
                                   │WON_CONTINUING│─────────┘
                                   └──────────────┘
                                          │
                                          │ T6 / T7
                                          ▼
                                   ┌───────────┐
                                   │ COMPLETED │ (re-flush, merge events)
                                   └───────────┘
```

### S7.3 转移表

| # | 转移 | 触发器 | 操作 |
|---|------|--------|------|
| T1 | UNINIT→IDLE | `_ready()` | `_bh_init()` |
| T2 | IDLE→RUNNING | `new_game()` | `_bh_start_run()` + seed + run_start |
| T3 | RUNNING→COMPLETED | Victory/Loss | `_bh_end_run()` → flush (first write) |
| T4 | RUNNING→IDLE | title() mid-run | TitlePatch snapshot flush + preserve |
| T5 | RUNNING→WON_CONTINUING | Victory → player continues | **新增**: 检测到第一个 post-victory spin_start |
| T6 | WON_CONTINUING→COMPLETED | Guillotine / coin loss | `_bh_end_run()` → re-flush (merge events) |
| T7 | WON_CONTINUING→COMPLETED | title() | TitlePatch snapshot (但合并全部 events) |
| T8 | COMPLETED→WON_CONTINUING | Continue after victory via cold boot | sidecar 加载后检测到 run 曾有 victory |
| T9 | IDLE→UNINIT (or stay) | game exit | cleanup |
| T10 | COMPLETED→IDLE | new_game / title | `_bh_start_run()` (只清 ID，不伤已完成 JSON) |

### S7.4 核心语义改变

**旧模型**: `_bh_run_ended = true` 意味着 "不许再 end_run"，用于防止重复 flush。
**新模型**: `_bh_run_ended = true` 只意味着 "JSON 已写"，但在 `WON_CONTINUING` 状态下可以被重新设为 false。

具体：
1. 第一次 Victory flush 后，如果检测到游戏继续（spin_start 事件在 `_bh_run_ended==true` 时到达），自动进入 `WON_CONTINUING` 状态。
2. 在 `WON_CONTINUING` 状态下，保存第一次 flush 的 events 快照（`_bh_pre_victory_events`）。
3. 第二次 end_run 时，合并 `_bh_pre_victory_events` + 当前 `_bh_events`，重新 flush 完整 JSON，覆盖第一次的文件。
4. TitlePatch 在 `WON_CONTINUING` 状态下改为执行完整 flush（合并 events）而非 snapshot。

---

## S8. 修复方案对照

### 方案 E: 最小修复（基于状态机模型，推荐）

**只改 2 处：**

#### 改动 1: `_bh_end_run` — Victory 后保存快照 + 重置 latch

```gdscript
var _bh_pre_victory_events = []   # 新增变量

func _bh_end_run(result):
    if _bh_run_ended:
        return
    # ... 现有逻辑 ...
    _bh_run_ended = true
    _bh_add_event('run_end', {...})
    
    # ★ 改动: flush 前保存事件快照 (用于后续合并)
    _bh_pre_victory_events = _bh_events.duplicate(true)
    _bh_flush()
    # _bh_flush 内部仍然 clear，不影响
    
    # ★ 改动: Victory 后检查是否可能继续
    if result == "victory":
        # 延迟重置 — 如果游戏继续，在下一个 spin_start 时进入 WON_CONTINUING
        pass  # latch 暂时保持，等 spin_start 检测
```

#### 改动 2: SpinPatch — 检测 post-victory continue

```gdscript
# SpinPatch Prefix, 在 _bh_add_event("spin_start") 之前:
if _bh_run_ended and _bh_events.size() >= 0:
    # 检测到 Victory 后继续 — 进入 WON_CONTINUING 状态
    _bh_run_ended = false
    # _bh_pre_victory_events 已在上次 end_run 中保存
```

#### 改动 3: `_bh_flush` — 支持合并模式

```gdscript
func _bh_flush():
    # ★ 改动: 如果有 pre_victory_events，合并到 _bh_events 前面
    var _all_events = _bh_events
    if _bh_pre_victory_events.size() > 0:
        _all_events = _bh_pre_victory_events + _bh_events
        _bh_pre_victory_events.clear()
    
    # Phase 1: 使用 _all_events 而非 _bh_events 构建 spins
    for ev in _all_events:   # ← 改为遍历合并后的事件
        # ... 现有 Phase 1-4 逻辑不变 ...
    
    # Phase 5: 写入 JSON (覆盖第一次的)
    # ... 现有写入逻辑不变 ...
    _bh_events.clear()
```

**改动量**: 约 15 行 GDScript，3 个位置。
**风险**: 低——只在 Victory 后继续的场景下触发新逻辑，不影响现有正常流程。
**回退**: 如果 `_bh_pre_victory_events` 为空（正常路径），行为与修改前完全一致。

### 方案对比

| 标准 | 方案 A (检测 continue) | 方案 B (移除 guard) | 方案 D (备份+合并) | **方案 E (状态机)** |
|------|----------------------|-------------------|------------------|-------------------|
| 改动量 | 小 | 极小 | 大 | 小 (~15行) |
| 覆盖所有 post-victory 结局 | ✅ | ⚠️ 仅 guillotine | ✅ | ✅ |
| 不丢失 pre-victory 数据 | ⚠️ 依赖实现 | ❌ 覆盖为部分 | ✅ | ✅ |
| 不影响正常流程 | ✅ | ✅ | ⚠️ 大改动 | ✅ |
| 与现有架构一致 | 部分 | 否 | 是 | 是 |
| 向后兼容 (旧 JSON) | ✅ | ❌ | ✅ | ✅ |
| 状态机可理解性 | 中 | 低 | 高 | **高** |
| 支持 cold boot continue | ⚠️ | ❌ | ✅ | ✅ |

---

# 第三部分：已实施的修复 (2026-06-04)

## 时间线

```
2026-06-04  ─  静态分析确认根因 (_bh_run_ended 单向闩锁)
2026-06-04  ─  架构师提出"非破坏性 flush + spin-count 去抖"方案
2026-06-04  ─  代码审查 → 修正 → 实施 → 构建通过
2026-06-04  ─  commit a18ebd3
2026-06-04  ─  测试发现残余问题 (本报告第四部分)
```

## 实施的方案

采用**非破坏性 flush + spin-count 去抖**（见第二部分 S7-S8 的方案 E 改良版）。

### commit a18ebd3 摘要

```
refactor: replace _bh_run_ended latch with non-destructive flush + spin-count debounce

Core changes:
- Replace _bh_run_ended with _bh_flushed_at_spin (debounce marker) and
  _bh_victory_achieved (semantic flag, persisted to rng_state sidecar)
- _bh_flush() no longer clears _bh_events — flush is read-only
- _bh_end_run() uses spin-count debounce instead of permanent latch
- Removed all second-layer not _bh_run_ended guards from call sites
- Temp events file cleanup moved to _bh_start_run()
```

### 改动文件

| 文件 | 改动 |
|------|------|
| `MainScriptSourceMod.cs` | 变量替换 + `_bh_count_spins`(新) + `_bh_flush` 非破坏化 + `_bh_end_run` 重写 + `_bh_start_run` temp 清理 |
| `GuillotineEndPatch.cs` | 删除 `not _bh_run_ended` guard |
| `TitlePatch.cs` | 删除 guard + 去 save/restore 舞蹈 |
| `TitleSetFloorPatch.cs` | 删除 guard |
| `RngInfrastructureSourceMod.cs` | sidecar 持久化 `victory_achieved` + 冷启恢复 + `_notification` 删 guard |

**5 files, +89 / -36 lines.**

### 验证状态

| 场景 | 预期 | 测试状态 |
|------|------|---------|
| 正常 Victory (不继续) | 单次 flush | 待测 |
| Victory → Continue → Guillotine | re-flush 覆盖完整 JSON | ⚠️ 见第四部分 |
| Victory → Continue → Coin-loss | re-flush | 待测 |
| Victory → Continue → Alt+F4 | `_notification` flush | 待测 |
| Cold-boot Continue | sidecar 恢复 + re-flush | 待测 |

---

# 第四部分：残余问题 — Summary 快照停滞在 Victory (2026-06-04)

## 发现

commit a18ebd3 部署后，测试数据 (`docs/log/1780582974.*`) 显示：**spin 数据已完整（278 spins），但 summary 中的储物间快照、DPT 快照、摧毁符号列表全部停留在 Victory 时刻。**

## 测试数据证据

| 字段 | Victory 时刻 (spin ~107) | 最终状态 (spin 277) | JSON 实际值 | 来源 |
|------|------------------------|-------------------|------------|------|
| `total_spins` | ~108 | 278 | **278** ✅ | `all_spins.size()` (全量 spin_start 事件) |
| `final_coins` | 947 | 27,980,657,662 | **27,980,657,662** ✅ | 最后 spin_end 事件的 `coin_total` |
| `destroyed_items` | 5 种 | 8 种 | **8** ✅ | `item_destroyed` 事件合并 + run_end |
| `end_time` | 22:30:51 | ≈22:40 | **22:30:51** ❌ | run_end 事件 `timestamp` |
| `summary.items` | 17 种 | 59 种 | **17** ❌ | run_end 事件 `final_items` |
| `summary.symbols` | 10 种 | ? | **10** ❌ | run_end 事件 `final_symbols` |
| `summary.destroyed_symbols` | 70 个 | 104 个 | **[] 空** ❌ | run_end 事件 `destroyed_symbols` |

## 数据流诊断

```
字段分类:

  从 spin 事件派生的 ──── 全部正确 ──── total_spins, final_coins, destroyed_items(合并)
       ↑                                              ↑
       │ 累加器从全部 _bh_events 重建                 │ 确认 re-flush 执行了
       
  从 run_end 事件读取的 ── 全部停滞 ── end_time, items, symbols, destroyed_symbols
       ↑
       │ 这些值由 _bh_end_run() 读取实时 $'Reels' / $'Items' 写入
       │ 如果 re-flush 执行了但读到的节点已空 → 停留在旧 run_end 的值
```

## 根因

`_bh_end_run` 在构建 summary 数据时，直接读取 Godot 实时节点：

```gdscript
func _bh_end_run(result):
    # ...
    for r in $'Reels'.reels:        # ← 读取当前棋盘
        for i in r.icons:           # ← 可能已被 guillotine 清空
            fs.append(...)
    for it in $'Items'.items:       # ← 读取当前储物间
        fi.append(...)              # ← 可能已被 guillotine 清空
```

guillotine 触发时 (`guillotine_essence_anim = 600`)：

1. `Coins.update()` 或 `Items` 设置 `anim = 600`
2. 同一帧或下一帧，GuillotineEndPatch Prefix 触发 `_bh_end_run("victory")`
3. `_bh_end_run` 读取 `$'Reels'` / `$'Items'` —— **此时棋盘/储物间可能已被 guillotine 动画首帧清空**
4. 读到的 `fs`/`fi` 是空或残缺的
5. 旧的 victory run_end 被 strip 掉，新的 run_end 带着**残缺的 snapshot** 写入 `_bh_events`
6. `_bh_flush` 处理此残缺 run_end → summary 数据错误

**核心矛盾**：`_bh_end_run` 依赖实时节点快照来构建 summary，但 guillotine 场景下节点状态在 `_bh_end_run` 被调用时已不可靠。re-flush 正确地重建了 spin 数据（来自事件），但 summary 数据被实时节点读取污染。

## 修复方向

**不从实时节点读快照，改为从 `_bh_events` 自身的事件中重建 summary。**

| summary 字段 | 当前来源 (不可靠) | 替代来源 (_bh_events 事件) |
|-------------|-------------------|--------------------------|
| `symbols` 列表 | `$'Reels'.reels` | 最后一份 `board_value` 事件的 `values[]` |
| `symbols[].total_value/dpt_*` | DPT 累加器 | 不变 (已正确) |
| `items` 列表 | `$'Items'.items` | `item_accum` (Phase 1 已从 `item_added`/`item_destroyed` 累加) |
| `destroyed_symbols` | `destroyed_symbol_types` | Phase 1 新增 `destroyed_symbol_accum` (与已有 `destroyed_item_accum` 对称) |
| `removed_symbols` | `removed_symbol_types` | 同上思路 |
| `coins` | `$'Coins'.coins` | 最后 `spin_end` 事件的 `coin_total` |
| `floor` | `$'Pop-up Sprite/Pop-up'.current_floor` | 最后 `rent_updated` 事件 |

这样 `_bh_end_run` 不再需要读取任何 Godot 实时节点来构建 summary，完全从事件缓冲重建。**re-flush 变成真正幂等的——无论何时调用、棋盘处于什么状态，输出的 JSON 都由事件内容唯一决定。**

## 时间线

```
2026-06-04 17:48  ─  第一份测试数据 (1780566538) — JSON 完全截断在 Victory, 108 spins
2026-06-04 19:30  ─  静态分析开始
2026-06-04 20:00  ─  根因确认: _bh_run_ended 单向闩锁
2026-06-04 20:30  ─  状态机模型 + 修复方案 (本文档第一、二部分)
2026-06-04 21:00  ─  架构师提出"非破坏性 flush + 去抖"
2026-06-04 21:30  ─  代码审查 → 实施 → commit a18ebd3
2026-06-04 22:22  ─  第二份测试数据 (1780582974) — spins 已完整, summary 停滞
2026-06-04 22:50  ─  诊断: summary 数据源 (实时节点) 与 spin 数据源 (事件) 不同步
2026-06-04 23:00  ─  修复方向: summary 改为从事件重建 (本文档第四部分)
```
