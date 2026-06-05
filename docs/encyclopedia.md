# BetterHistoryMod 开发百科全书

> Luck be a Landlord 全功能历史记录 Mod — 架构 · SlotWeave 模式 · 陷阱 · 参考

---

## 1. 架构

```
Game (Godot 3.4.4)                    UI (WPF .NET 8)
├── 12× ISourceMod                    ├── MainWindow.xaml
├── 8× [Patch]                        ├── HistoryViewModel.cs
├── GamePipeServer ──Named Pipe──→    └── UiPipeClient
├── HistoryStore / MigrationRunner
└── PCGRng (17 persistent + 3 per-spin)
```

### 补丁清单 (27 个文件)

| 文件 | 类型 | 目标 | 作用 |
|------|------|------|------|
| `MainScriptSourceMod` | ISourceMod | Main.tscn::1 | 事件捕获: `_bh_add_event`, `_bh_flush`(Phase1-5), `_bh_end_run` |
| `RngInfrastructureSourceMod` | ISourceMod | Main.tscn::1 | PCGRng 类 + 17 实例 + djb2/fnv1a |
| `ChoiceRngSourceMod` | ISourceMod | Pop-up.tscn::1 | 三选一 RNG 替换(18 处) + `_bh_c_pick_symbol/item` helpers |
| `BoardValuePatch` | Postfix | Main.tscn::4 `check_values` | DPT + 角标采集 |
| `SpinPatch` | Prefix | Main.tscn::4 `spin` | `spin_start` + `_bh_begin_spin_rng` |
| `WriteLogPatch` | Prefix | Main.tscn::1 `write_log` | `spin_end`/item/VICTORY 拦截 |
| `ResolveEventPatch` | Prefix | Pop-up.tscn::1 `resolve_event` | choice 记录 + 终局拦截 |
| `LandlordRngRefSourceMod` | ISourceMod | Landlord.tscn::9 | 房东 RNG(5 fine print + 1 fate) |
| `LandlordFinePrintPatch` | [Replace] | Landlord.tscn::9 `get_fine_print` | **已禁用**(pass-through) |
| `ReelRngRefSourceMod` | ISourceMod | Main.tscn::4 | Reel RNG |
| `ReelShufflePatch` | [Replace] | Main.tscn::4 `shuffle_tiles` | 洗牌 RNG |
| `ReelExtraRngSourceMod` | ISourceMod | Main.tscn::4 | Reel 额外 RNG |
| `SlotIconRngSourceMod` | ISourceMod | Slot Icon.tscn::1 | Effect RNG(50+ 处) |
| `SlotIconNoopSourceMod` | ISourceMod | Slot Icon.tscn::1 | 防脚本重载(no-op) |
| `ItemRngSourceMod` | ISourceMod | Item.tscn::1 | Item RNG(20+ 处) |
| `CosmeticRngSourceMod` | ISourceMod | Cosmetic | 音乐/SFX/动画 RNG |
| `TitleSeedSourceMod` | ISourceMod | Main.tscn::6 | 种子 UI(Button + LineEdit) |
| `TitleToggleSourceMod` | ISourceMod | Main.tscn::6 | IPC toggle helpers |
| `TitlePatch` | Prefix | Main.tscn::1 `title` | quit flush + `_bh_start_run` |
| `TitleSetFloorPatch` | Prefix | Main.tscn::1 `new_game` | 种子应用 + `run_start` |
| `TitleDrawSeedPatch` | Postfix | Main.tscn::6 `draw` | 种子 UI 每帧绘制 |
| `FloorMenuSeedPatch` | Postfix | Floor Menu | 种子 UI 可见性更新 |
| `HistoryButtonPatch` | Postfix | Main.tscn::6 `draw` | 历史按钮 |
| `ReadyPatch` | Postfix | Main.tscn::1 `_ready` | 初始化 `_bh_init()` |
| `ClipboardPreserveMod` | ISourceMod | TT Button.tscn::1 | `OS.set_clipboard("")` → 保存/恢复 |
| `ClipboardMonitorPatch` | Postfix | Main.tscn::1 `_process` | 剪贴板采样(诊断用) |
| `GdscriptUtil` | 工具 | — | Tabify 缩进处理 |

---

## 2. SlotWeave 模式

### ISourceMod

```csharp
public class MyMod : ISourceMod {
    public bool ShouldRun(string path) => path == "res://Target.tscn::1";
    public string Modify(string path, string source) {
        if (source.Contains("func _my_helper")) return source; // 幂等!
        source = source.Replace("rand_range(", "_my_rand_range(");
        source = Regex.Replace(source, @"\.shuffle\(\)", "_my_shuffle($1)");
        return source + "\n" + HelpersGdscript + "\n";
    }
}
```

### [Patch] 三种模式

```csharp
[Prefix]  — 函数体之前。变量不与 Postfix 共享!
[Postfix] — 函数体之后。早期 return 路径上**不执行**!
[Replace] — 完全替换函数体。拿到的是已被 ISourceMod 修改后的源码。
```

### GDScript 字符串

```csharp
// verbatim: " → "" , { } 是字面量, ' 不需要转义
const string Code = @"
func foo():
    var x = $""/root/Main"".coins    // "" = 一个 "
    var path = 'user://dir'          // 单引号更安全
";
```

**Godot 3 陷阱**: 没有 `x if cond else y`,用 `cond and x or y`(x 不能为 falsy)。

### RNG 确定性替换

17 个跨回合 PCGRng 实例 + 每 spin 2 个临时。所有 `custom_shuffle` 包装必须有 `typeof(arr) != TYPE_ARRAY` 守卫。

### Tabify

`GdscriptUtil.Tabify("...")` 处理缩进,必须用。

---

## 3. 已知陷阱

| # | 陷阱 | 症状 | 根因 | 修复 |
|---|------|------|------|------|
| 1 | ISourceMod+[Replace] 双重替换 | `_lfr__lfr_rand_range` → 房东战 crash | [Replace] 对已修改源码再次替换 | 删 [Replace] 或加幂等守卫 |
| 2 | Postfix 不执行 | 剪贴板恢复无效 | `do_call()` 有早期 return | ISourceMod 替换调用本身 + call_deferred |
| 3 | `_bh_end_run` 时棋盘已空 | 角标全 0 | 房东死 160 帧后才调用,棋盘已 reset | `check_values` Postfix 采集 |
| 4 | 幽灵 Run | 未开始游戏就产生 JSON | 2 个启动事件绕过 `<=1` 守卫 | 检查 `spin_start` 存在而非计数 |
| 5 | Manifest 过期 | 最新 run 列表不显示 | GDScript 直接写文件,不更新 manifest | 扫描文件系统补漏 |
| 6 | 剪贴板被游戏清空 | 复制种子后进入游戏就丢 | TTButton.do_call() 首行 `OS.set_clipboard("")` | ISourceMod 替换为保存/恢复 |
| 7 | WPF ToolTip 白底白字 | 储物间 hover 看不见 | 裸 TextBlock,默认白色背景 | `<ToolTip Background="#1E2030">` |
| 8 | Godot 单元素数组 quirk | 1 条 end_actions 反序列化失败 | JSON.print `[{}]` → `{}` | `SingleOrArrayConverter<T>` |

---

## 4. 事件管线

```
spin() → SpinPatch → _bh_begin_spin_rng() → spin_start 事件
       → check_values() → BoardValuePatch → board_value 事件 (DPT+角标)
       → resolve_event → ResolveEventPatch → _bh_record_choice/cards
       → write_log("Coin total...") → WriteLogPatch → spin_end 事件
```

### 事件类型

| 事件 | 触发点 | 关键 payload |
|------|--------|-------------|
| `run_start` | `new_game()` | `run_number` |
| `spin_start` | `spin()` guard pass | `spin_num`, `coins`, `floor` |
| `spin_end` | `write_log("Coin total...")` | `coin_total` |
| `board_value` | `check_values()` | `values[{id, value, badge_text?, badge_bonus?, badge_mult?}]` |
| `item_added` | `_bh_record_choice` | `item`, `source`, `skipped[]`, `choice_idx` |
| `item_destroyed` | `write_log("Destroyed...")` | `item` |
| `run_end` | `_bh_end_run` | `result`, `floor`, `coins`, `seed_*` |

### Phase 管线

```
Phase 1: 事件 → spin frames (spin_start/spin_end → SpinEntry)
Phase 2: spin frames → rent_cycles (按 cut 值切分)
Phase 2.5: extra_actions → end_actions (item 提取,按 choice_idx 分组)
Phase 3: meta 构造
Phase 4: summary 构造 (符号/物品聚合 + DPT + 角标)
Phase 5: JSON 写入
```

---

## 5. 符号角标

游戏在 `SlotIcon.update_value_text()` 中为每个符号类型用不同公式计算。**直接读已渲染字符串,不要自己算原始值:**

| 角标 | 字段 | 典型符号 |
|------|------|---------|
| child1 主计数器 | `displayed_text_value` | coal(20→0), thief(倍数), light_bulb(充能), snail(剩余回合) |
| child2 乘数 | `displayed_multiplier_value` | permanent_multiplier ≠ 1 时显示 |
| child3 加成 | `displayed_bonus_value` | diver(+N), archaeologist(+N), eldritch_beast(+N) |

采集时机: `BoardValuePatch` 在 `check_values()` 后读取 `displayed_icons[_y][_x]`,此时所有属性存活。

显示优先级: child1 → child3 → child2。

---

## 6. DPT 统计

| 指标 | 算法 | 说明 |
|------|------|------|
| Total Value | Σ final_value | 全场上屏 coin 总和 |
| DPT (实际) | total_value / turns_present | 含未上屏回合的每 spin 均值 |
| DPT (有效) | total_value / turns_contributing | 仅上屏回合的每 spin 均值 |

采集: `board_value` 事件的 `{id, value}`。`turns_present` 由首次/末次 spin 号推算。

---

## 7. RNG 系统

### 种子输入 → RNG 派生

```
玩家输入(或随机生成 10 位 [0-9A-Z])
  → FNV-1a hash → landlord_seed (31-bit int)
    → djb2(seed, "spin")    → SpinRNG
    → djb2(seed, "sym_common") → SymbolCommonRNG
    → ... (共 17 个持久实例)
    → seed(landlord_seed)   → 捕获 Godot 全局 RNG
```

### 每稀有度独立分轨

```
SymbolCommonRNG, SymbolUncommonRNG, SymbolRareRNG, SymbolVeryRareRNG
ItemCommonRNG, ItemUncommonRNG, ItemRareRNG, ItemVeryRareRNG
EssenceCommonRNG, EssenceUncommonRNG, EssenceRareRNG, EssenceVeryRareRNG
```

rarity_bonus 只改变"抽哪个稀有度"的频率,不改变各稀有度池内的抽取序列。

### 每 spin 临时隔离

```
SpinRNG.next() → spin_N_value
  → derive(spin_N_value, "reel")  → ReelRNG_N   (spin 结束丢弃)
  → derive(spin_N_value, "effect") → EffectRNG_N (spin 结束丢弃)
```

spin N 加效果只影响 spin N,spin N+1 不受影响。

### PCGRng API

```gdscript
var rng = PCGRng.new(seed)
rng.randf()              # [0, 1)
rng.randi_max(n)         # [0, n)
rng.rand_range(min, max) # [min, max)
rng.custom_shuffle(arr)  # Fisher-Yates
```

64-bit PCG 状态,跨平台一致。

---

## 8. JSON 格式 (v2.0)

```json
{
  "history_version": "2.0",
  "run_id": "1780405902",
  "is_legacy_log": false,
  "meta": {
    "run_number": 83, "ended_by": "victory", "final_coins": 1943,
    "total_spins": 102, "floor": 20,
    "seed_type": "random", "seed_input": "A3F7K2M9P1", "landlord_seed": 2874653291,
    "start_time": "2026-06-02T21:11:42", "end_time": "2026-06-02T21:23:56"
  },
  "summary": {
    "symbols": [{ "id": "diver", "count": 1, "total_value": 145,
                  "turns_present": 60, "turns_contributing": 42,
                  "dpt_actual": 2.4, "dpt_effective": 3.5,
                  "badge_text": null, "badge_bonus": "+3" }],
    "items": [{ "id": "lunchbox", "item_count": 2 }],
    "destroyed_symbols": [{ "id": "dud", "count": 3 }]
  },
  "rent_cycles": [{
    "cycle_index": 1, "rent_required": 25, "spins_in_cycle": 5,
    "spins": [{ "spin_num": 1, "main_symbol": "bee", "skipped_options": ["cat"],
                "extra_actions": [{ "action": "added", "type": "item", "id": "lunchbox" }] }],
    "end_actions": [{ "action": "added", "type": "item", "id": "frying_pan", "source": "choice", "choice_idx": 0 }],
    "rent_payment": { "paid_successfully": true, "coins_left_after_pay": 10 }
  }]
}
```

### 字段说明

| 字段 | 说明 |
|------|------|
| `end_actions[].choice_idx` | 同一次 choice 的 added+skipped 共享,UI 分组用 |
| `badge_text/badge_mult/badge_bonus` | 游戏已渲染的角标字符串,非原始值 |
| `single_or_array` | Godot 3 单元素数组 quirk — 用 `SingleOrArrayConverter` 兼容 `{}` 和 `[{}]` |
| `is_legacy_log: true` | 从旧 log 解析,非 live mod 产出 |

---

## 9. 房东战崩溃调查 (2026-06-02)

**症状**: 房东战开始/结束时硬崩溃,无 Godot 错误栈,稳定复现。

**根因**: `LandlordFinePrintPatch`([Replace]) + `LandlordRngRefSourceMod`(ISourceMod) 双重替换 `rand_range(` → `_lfr__lfr_rand_range`(不存在的函数)。`get_fine_print` 只在房东战 `take_damage` 中调用,所以正常 12 轮租金无事,一进房东战就崩。

**修复**: `LandlordFinePrintPatch` 设为永久 pass-through + 幂等守卫。
