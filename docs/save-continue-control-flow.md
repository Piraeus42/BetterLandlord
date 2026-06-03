# Save / Continue 控制流分析 — BetterHistoryMod

## 1. 游戏原生启动 + 存档流程

### 1.1 `_ready()` — 游戏启动入口

Main.tscn::1 : `_ready()` (line 324-403)
```
_initialize_Steam()
load_game()              ← 从 user://LBAL.save 恢复 Persist 节点
load_sandbox()
load_options()
load_stats()
title()                  ← 进入主菜单
```

### 1.2 `save_game()` — 存档机制

Main.tscn::1 : `save_game()` (line 1895-1911)
```gdscript
func save_game():
    var save_game = File.new()
    save_game.open(save_string, File.WRITE)
    var save_nodes = get_tree().get_nodes_in_group("Persist")
    for node in save_nodes:
        var node_data = node.call("save")
        save_game.store_line(to_json(node_data))
    save_game.close()
```
**关键**：只保存标记了 "Persist" group 的节点（Pop-up、Reels、Items、Landlord、Coins 等）。Main 节点上的**自定义 GDScript 变量（_bh_events, _bh_rng_* 等）不在 Persist 里，不会被保存。**

### 1.3 `load_game()` — 读档机制

Main.tscn::1 : `load_game()` (line 2916-2959)
```gdscript
func load_game():
    # 逐行读取 JSON，对每个节点调 n.set(key, value)
    for each line in save file:
        var node_data = parse_json(line)
        var n = get_node(node_data["path"])
        for i in node_data.keys():
            n.set(i, node_data[i])          ← 只恢复节点属性
    # 如果正在 spinning，触发 spin
    # 恢复 rarity_chances (非持久数据)
```
**关键**：`n.set(i, node_data[i])` 只能恢复节点上的导出属性，不能恢复我们的 GDScript 变量。

### 1.4 `title()` — 进入主菜单

Main.tscn::1 : `title()` (line 1330-1341)
```gdscript
func title():
    $"Title".draw()
    sandbox_reloading = false
    load_data(true, false, true)    ← 重新加载存档数据
    load_sandbox()
```

### 1.5 `new_game()` — 新游戏

Main.tscn::1 : `new_game()` (line 1546-1648)
```gdscript
func new_game():
    # 如果 floor 已选或 demo:
    reset_values()           ← 重置所有游戏状态
    $"Title".remove()        ← 移除 Title UI
    # ... 设置 reels, items, 初始事件 ...
    $"Pop-up Sprite/Pop-up".floor_selected = true

    # 如果 floor 未选:
    $"Title".floor_menu()    ← 先进入 floor 选择
```

### 1.6 `continue_game()` — 继续游戏

Main.tscn::1 : `continue_game()` (line 1670-1729)
```gdscript
func continue_game():
    if $"Pop-up Sprite/Pop-up".spins > 0:    ← 有存档
        load_data(false, true, true)          ← 从磁盘恢复状态
        load_mods()
        # 恢复 modded floor 信息
        $"Title".remove()
        # 恢复 items, reels, rarity 等
        write_log("--- CONTINUING RUN #... ---")
```
**关键**：`continue_game()` **不调 `new_game()`，不调 `reset_values()`，不调 `_bh_init_rng()`**。

---

## 2. Mod 注入的控制流

### 2.1 注入点总览

| Patch 文件 | Hook 目标 | 时机 | 作用 |
|-----------|----------|------|------|
| `ReadyPatch.cs` | `_ready()` Postfix | 游戏启动 | 调 `_bh_init()` 清 events |
| `TitlePatch.cs` | `title()` **Prefix** | 进入主菜单 | 调 `_bh_end_run("quit")` + **`_bh_start_run()`** |
| `TitleSetFloorPatch.cs` | `new_game()` **Prefix** | 新游戏 | 调 `_bh_apply_seed()` + `_bh_add_event("run_start")` |
| `WriteLogPatch.cs` | `write_log()` Prefix | 日志写入 | 捕获 spin_start/spin_end/victory/loss/item 事件 |
| `SpinPatch.cs` | `spin()` Prefix | 每次 spin | 调 `_bh_begin_spin_rng()` + 记录 spin_start |
| `BoardValuePatch.cs` | `check_values()` Postfix | board 评估后 | 记录 board_value |
| `GuillotineEndPatch.cs` | `_process()` Prefix | 断头台动画 | 调 `_bh_end_run("victory")` |

### 2.2 关键注入代码

#### ReadyPatch — _ready() Postfix
```csharp
// ReadyPatch.cs — line 10-13
if $"/root/Main".has_method("_bh_init"):
    $"/root/Main"._bh_init()       // 清 events，设 run_id
```

#### TitlePatch — title() Prefix ⚠️ 问题核心
```csharp
// TitlePatch.cs — line 14-19
if $"/root/Main".has_method("_bh_start_run"):
    if $"/root/Main".get("_bh_events") != null and $"/root/Main"._bh_events.size() > 0:
        $"/root/Main"._bh_end_run("quit")     // 先 flush 残留 events
    $"/root/Main"._bh_start_run()             // ← 无条件调！
```

#### TitleSetFloorPatch — new_game() Prefix
```csharp
// TitleSetFloorPatch.cs — line 12-21
if has_method("_bh_apply_seed"):
    _bh_apply_seed()                  // 读 seed_config.json → _bh_init_rng(...)
if has_method("_bh_add_event"):
    _bh_add_event("run_start", {
        "run_number": $'Pop-up Sprite/Pop-up'.total_runs,
        "version": version_str
    })
```

---

## 3. GDScript 注入 — 事件 & RNG 管理

### 3.1 变量声明

所有以下变量被注入到 Main.tscn::1（Main 节点），**不在 "Persist" group 里，存档不会保存它们**：

```gdscript
# MainScriptSourceMod — EventCaptureHelpers
var _bh_events = []               # 事件缓冲
var _bh_run_id = ''               # 当前 run ID
var _bh_run_ended = false         # run 是否已结束

# RngInfrastructureSourceMod — RNG 状态
var _bh_rng_seed_type: String = ''     # 'random' | 'custom'
var _bh_rng_seed_input: String = ''    # 具体的种子字符串
var _bh_rng_landlord_seed: int = 0     # FNV-1a 哈希结果

# 19 个 PCGRng 持久实例 (null 直到 _bh_init_rng 被调)
var _bh_rng_spin: PCGRng = null
var _bh_rng_rarity: PCGRng = null
var _bh_rng_reel: PCGRng = null
# ... 共 19 个
```

### 3.2 `_bh_start_run()` — 启动新 run ⚠️ 问题核心

```gdscript
// MainScriptSourceMod.cs — line 52-61
func _bh_start_run():
    _bh_events.clear()
    _bh_run_ended = false
    _bh_run_id = str(OS.get_unix_time()) + '_' + str($'Pop-up Sprite/Pop-up'.total_runs)
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
    _bh_init_rng('random', '')      // ← 无条件设为随机种子！
```

### 3.3 `_bh_init()` — 首次初始化

```gdscript
// MainScriptSourceMod.cs — line 45-50
func _bh_init():
    _bh_events.clear()
    _bh_run_id = str(OS.get_unix_time())
    _bh_run_ended = false
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
    // 注意：不调 _bh_init_rng()
```

### 3.4 `_bh_init_rng()` — RNG 初始化

```gdscript
// RngInfrastructureSourceMod.cs — line 152-211
func _bh_init_rng(seed_type: String, seed_input: String):
    _bh_rng_seed_type = seed_type
    _bh_rng_seed_input = seed_input
    seed_input = seed_input.replace('O', '0').replace('I', '1')

    if seed_type == 'random' or seed_input == '':
        _bh_rng_seed_input = _bh_generate_random_seed()   // 生成新的随机种子！
        _bh_rng_seed_type = 'random'
    else:
        _bh_rng_seed_input = seed_input
        _bh_rng_seed_type = 'custom'

    var landlord_seed: int = _bh_fnv1a(_bh_rng_seed_input)

    // Phase 1: 创建 19 个新 PCGRng 实例
    _new_spin = PCGRng.new(_bh_derive_seed(s, 'spin'))
    // ... 共 19 个 ...

    // Phase 2: 原子赋值
    _bh_rng_spin = _new_spin
    // ...

    seed(landlord_seed)   // 同步 Godot 全局 RNG
```

### 3.5 `_bh_apply_seed()` — 从 seed_config.json 读取并初始化 RNG

```gdscript
// RngInfrastructureSourceMod.cs — line 236-245
func _bh_apply_seed():
    var title = $"/root/Main/Title"
    var cfg = title._bh_get_seed_config()     // 读 seed_config.json
    _bh_init_rng(str(cfg['type']), str(cfg['input']))
```

### 3.6 `_bh_get_seed_config()` — 读种子配置

```gdscript
// TitleSeedSourceMod.cs — line 26-44
func _bh_get_seed_config():
    # 读 user://betterHistory/seed_config.json
    # 返回 {'type': 'custom'|'random', 'input': '...'}
```

---

## 4. 种子状态流 — 完整对照

### 4.1 New Game 流程（正常）

```
游戏启动
  → _ready()
  → load_game()           [恢复 Persist 节点]
  → [ReadyPatch] _bh_init()            ← 清 events，不触 RNG
  → title()               [进入主菜单]
  → [TitlePatch] _bh_start_run()       ← ⚠️ _bh_init_rng('random', '') 设随机种子
  → Title.draw()          [显示按钮]
  → [Timer] _bh_on_seed_timer()
  → 进入 floor_menu → 重置 seed_config.json → button = "Seed: OFF"

用户选 floor，点 New Game:
  → new_game()
  → [TitleSetFloorPatch] _bh_apply_seed()
    → 读 seed_config.json
    → 如果是 custom:   _bh_init_rng('custom', 'ABC123')  ← 覆盖随机
    → 如果是 random:   _bh_init_rng('random', '')        ← 生成新随机
  → reset_values()
  → 开始游戏

种子结果: ✅ 正确 — 用户设的 custom seed 或新 random seed
```

### 4.2 Continue Game 流程（故障）

```
游戏启动
  → _ready()
  → load_game()           [恢复 Persist 节点: Pop-up, Reels, Items ...]
  → [ReadyPatch] _bh_init()            ← 清 events
  → title()               [进入主菜单]
  → [TitlePatch] _bh_start_run()       ← ⚠️ _bh_init_rng('random', '')
                                        ← ⚠️ 生成全新随机种子 "X9K2M..."
                                        ← ⚠️ 19 个 PCGRng 全部基于此新种子

用户点 Continue:
  → continue_game()
  → load_data(false, true, true)       ← 恢复 Pop-up 状态（coins, spins...）
  → 没有任何 hook 调 _bh_apply_seed()  ← ❌ RNG 保持 TitlePatch 设的随机值
  → 开始继续游戏

种子结果: ❌ 错误 — RNG 是步骤2的随机种子 "X9K2M..."，与原始存档的种子不同
```

### 4.3 已保存游戏的种子永久丢失

```gdscript
// 持久化状态 vs. 非持久状态对比：

保存在 LBAL.save 里（Persist group）:
  $"Pop-up Sprite/Pop-up".coins
  $"Pop-up Sprite/Pop-up".spins
  $"Pop-up Sprite/Pop-up".current_floor
  $"Pop-up Sprite/Pop-up".times_rent_paid
  $"Reels".displayed_icons
  $"Items".items
  ... (所有导出属性)

不保存（Main 节点上的 GDScript 变量）:
  _bh_rng_seed_type          ← 丢失！
  _bh_rng_seed_input         ← 丢失！（random 时的随机字符串）
  _bh_rng_landlord_seed      ← 丢失！
  _bh_rng_spin               ← 丢失！（19 个 PCGRng 实例）
  _bh_rng_rarity             ← 丢失！
  ... (所有 _bh_* 变量)      ← 全部丢失！
```

---

## 5. 三个冲突点

### 冲突 1: TitlePatch 在 title 时无条件调用 _bh_init_rng('random', '')

**位置**: `TitlePatch.cs` → `_bh_start_run()` → `_bh_init_rng('random', '')`

**影响**: 
- New Game: 随机种子被生成，随后被 `_bh_apply_seed()` 覆盖 → 无持续影响但浪费
- Continue: 随机种子被生成，**没有被覆盖** → 存档的种子被永久替换

**严重程度**: 对 Continue 是破坏性的

### 冲突 2: continue_game() 没有任何 RNG 恢复 hook

**位置**: `continue_game()` 没有 Patch hook

**影响**: 即使 seed_config.json 存了 custom seed，`_bh_apply_seed()` 也不会被调。random seed 的原始值更不可能恢复。

**严重程度**: 对 Continue 是破坏性的

### 冲突 3: 种子状态（_bh_rng_* 变量 + PCGRng 实例）不在游戏存档系统里

**位置**: `save_game()` 只保存 Persist group 节点，Main 节点不在其中

**影响**: 
- 原始 random seed 字符串在游戏 reload 后永远消失
- 19 个 PCGRng 实例在 game reload 后变成 null，直到下次 _bh_init_rng() 创建新实例
- Continue 后的前几个 RNG 调用可能因为 PCGRng 为 null 而崩溃（取决于 async 初始化时序）

**严重程度**: 结构性的 — 这是跨进程模型（GDScript 变量 → 存档文件）的固有矛盾

---

## 6. 影响范围

| 症状 | 触发条件 | 根因 |
|------|---------|------|
| Continue 后种子变了 | 任何 Continue 操作 | 冲突 1 + 2 |
| Continue 后前几个 spin 不一致 | random seed 的 Continue | 冲突 3 (PCGRng 丢失) |
| Custom seed 在 Continue 后丢失 | custom seed + Continue | 冲突 2 |
| _bh_events 在 title 时被清空 | 回到 title（正常行为） | TitlePatch 设计如此 |
