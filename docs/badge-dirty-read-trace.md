# 角标（badge）数据脏读时序追踪

> 现象：历史记录显示界面中，没有 multiplier 的符号被错误标记 *2 或 *1.5  
> 调查方向：时序问题 / 脏读  
> 本文档只追溯代码控制流和数据流，不做修改，不下结论

---

## 1. 数据来源：三个 `displayed_*` 字段

### 1.1 字段声明

**文件：** `game_source_code/Slot Icon.tscn__1.gd:119-121`

```gdscript
var displayed_text_value = ""
var displayed_multiplier_value = ""
var displayed_bonus_value = ""
```

这三个字段是 Slot Icon 节点的**实例变量**，每个图标有自己的一份。

### 1.2 字段赋值（唯一赋值点）

**文件：** `game_source_code/Slot Icon.tscn__1.gd:1373-1503` — 函数 `update_value_text()`

```gdscript
func update_value_text():
    # ... 根据符号类型计算 text_value, permanent_multiplier, permanent_bonus ...

    # line 1457 — 文本角标
    displayed_text_value = get_child(1).parse_num_str(str(text_value))
    # line 1460 — 清空
    displayed_text_value = ""

    # line 1475-1479 — 倍数角标
    if permanent_multiplier >= 10:
        displayed_multiplier_value = get_child(2).parse_num_str(str(round(permanent_multiplier))) + "x"
    elif permanent_multiplier > 0:
        displayed_multiplier_value = get_child(2).parse_num_str(str(stepify(permanent_multiplier, 0.1))) + "x"
    else:
        displayed_multiplier_value = ""

    # line 1489-1500 — 加成角标
    displayed_bonus_value = get_child(3).parse_num_str(str(permanent_bonus + ...))
    # 或...
    displayed_bonus_value = ""
```

**关键事实：** `displayed_*` 只在 `update_value_text()` 中被写入。没有其他代码直接赋值这三个字段。

**关键不对称：** 三个 `displayed_*` 变量的清空行为不一致：

`displayed_text_value` — **正确清空**（行 1457-1460）：
```gdscript
if text_value > 0 and text_value != reset_value and not destroyed and not tbd:
    displayed_text_value = get_child(1).parse_num_str(str(text_value))
else:
    get_child(1).raw_string = ""
    displayed_text_value = ""                   # ← 清空
```

`displayed_bonus_value` — **正确清空**（行 1490-1500）：
```gdscript
elif permanent_bonus != 0:
    displayed_bonus_value = ...
else:
    get_child(3).raw_string = ""
    displayed_bonus_value = ""                 # ← 清空
```

`displayed_multiplier_value` — **未清空**（行 1461-1481）：
```gdscript
if permanent_multiplier != 1:
    if permanent_multiplier >= 10:
        displayed_multiplier_value = get_child(2).parse_num_str(str(round(permanent_multiplier))) + "x"
    elif permanent_multiplier > 0:
        displayed_multiplier_value = get_child(2).parse_num_str(str(stepify(permanent_multiplier, 0.1))) + "x"
    else:
        displayed_multiplier_value = ""
else:
    get_child(2).raw_string = ""               # raw_string 清了
    # displayed_multiplier_value 未清空！       # ← 保留旧值 (如 "2x", "1.5x")
```

这是脏读的直接来源：当 `permanent_multiplier` 从非 1 变为 1 后，`displayed_multiplier_value` 保留上一次 `update_value_text()` 写入的值。

### 1.3 `change_type()` 不重置 `displayed_*`

**文件：** `game_source_code/Slot Icon.tscn__1.gd:346-476` — 函数 `change_type()`

该函数在 `overwrite_values == true` 时会重置 `permanent_bonus = 0`（行 419）和 `permanent_multiplier = 1`（行 423），但**不重置** `displayed_text_value`、`displayed_multiplier_value`、`displayed_bonus_value`。

```gdscript
# line 419-423
permanent_bonus = 0
reroll_token_permanent_bonus = 0
removal_token_permanent_bonus = 0
essence_token_permanent_bonus = 0
permanent_multiplier = 1
# displayed_* 未清空！
```

这意味着符号类型改变后，`displayed_*` 会保留旧类型的值，直到下一次 `update_value_text()` 被调用。

---

## 2. 第一个捕获点：BoardValuePatch（每局）

### 2.1 钩子位置

**文件：** `Piraeus.BetterLandlord/Patches/BoardValuePatch.cs:10-11`

```csharp
[Patch("res://Main.tscn::4", "check_values")]
class BoardValuePatch
{
    [Postfix]
    static string PostfixCode() => ...
```

`check_values()` 是游戏**每局**评估面板值的函数。BoardValuePatch 以 **Postfix** 形式挂载——在 `check_values()` 执行**之后**运行。

### 2.2 读取的字段

**文件：** `Piraeus.BetterLandlord/Patches/BoardValuePatch.cs:27-32`

```gdscript
if typeof(_icon.displayed_text_value) == TYPE_STRING and _icon.displayed_text_value != '':
    _entry['badge_text'] = str(_icon.displayed_text_value)
if typeof(_icon.displayed_multiplier_value) == TYPE_STRING and _icon.displayed_multiplier_value != '' and _icon.get_child(2).raw_string != '':
    _entry['badge_mult'] = str(_icon.displayed_multiplier_value)
if typeof(_icon.displayed_bonus_value) == TYPE_STRING and _icon.displayed_bonus_value != '':
    _entry['badge_bonus'] = str(_icon.displayed_bonus_value)
```

`_icon` 来自 `displayed_icons[y][x]`——**可见网格**上的图标引用。

**注意行 131 的额外守卫：** `_icon.get_child(2).raw_string != ''`。因为 `update_value_text()` 在 `permanent_multiplier == 1` 分支确实清空了 `raw_string`（行 1481），这个守卫防止了脏的 `displayed_multiplier_value` 进入每局 `board_value` 事件。但 `_bh_end_run()`（第 3.2 节）**没有这个守卫**。

### 2.3 `check_values()` 内部不调 `update_value_text()`

**文件：** `game_source_code/Main.tscn__4.gd:1169-1248` — 函数 `check_values()`

`check_values()` 调用 `displayed_icons[y][x].get_value("coin")` 获取数值，但**不调用** `update_value_text()`。因此 BoardValuePatch 运行时，`displayed_*` 的值反映的是**上一次** `update_value_text()` 被调用时的状态。

### 2.4 `update_value_text()` 的调用时机

`update_value_text()` 在 Slot Icon 上被调用的位置：

| 文件:行号 | 触发条件 |
|-----------|---------|
| `Slot Icon.tscn__1.gd:665` | 相邻图标效果变化后 |
| `Slot Icon.tscn__1.gd:2389` | 物品添加到图标后 |
| `Slot Icon.tscn__1.gd:2408` | 另一种物品添加路径 |
| `Slot Icon.tscn__1.gd:3846` | 全局更新循环中遍历所有 displayed_icons |
| `Slot Icon.tscn__1.gd:3854` | 物品 saved_value 变化后 |

**行 3846 的全局更新**最关键——它在效果解析阶段遍历整个 `displayed_icons` 网格。但这是在 `check_values()` **之前**执行的（spin 效果解析流程先于面板评估）。

---

## 3. 第二个捕获点：`_bh_end_run()`（终局快照）

### 3.1 触发时机

**文件：** `Piraeus.BetterLandlord/Patches/ResolveEventPatch.cs:10-15`

```csharp
[Patch("res://Pop-up.tscn::1", "resolve_event")]
class ResolveEventPatch
{
    [Prefix]
    static string PrefixCode() => ...
```

```gdscript
if _type == "game_over" or _type == "out_of_money":
    $"/root/Main"._bh_end_run("loss")
elif _type == "win" or _type == "ending":
    $"/root/Main"._bh_end_run("victory")
```

这是 **Prefix** 钩子——在游戏的 `resolve_event()` 执行**之前**调用 `_bh_end_run()`。

### 3.2 读取的字段和遍历范围

**文件：** `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:771-793`

```gdscript
var _reels = $'Reels'
for _r in _reels.reels:          # 遍历所有 reel
    for i in _r.icons:            # 遍历每个 reel 上的所有图标（含屏幕外的）
        if i.type != 'empty' and i.type != 'dud':
            # ...
            var _bt = str(i.displayed_text_value)
            var _bm = str(i.displayed_multiplier_value)
            var _bb = str(i.displayed_bonus_value)
            if _bt != '': entry['badge_text'] = _bt
            if _bm != '': entry['badge_mult'] = _bm
            if _bb != '': entry['badge_bonus'] = _bb
            fs.append(entry)
```

**关键差异：** `_bh_end_run()` 遍历的是 `Reels.reels[].icons[]`——**所有**图标数组（含屏幕外的），而 BoardValuePatch 遍历的是 `displayed_icons[][]`——**仅可见网格**。

**关键缺失：** BoardValuePatch（行 131）读取 `badge_mult` 时有 `_icon.get_child(2).raw_string != ''` 守卫——因为 `update_value_text()` 在 multiplier=1 分支清空了 `raw_string`，这个守卫阻止了脏值进入每局事件。但 `_bh_end_run()`（行 191-194）只用 `_bm != ''` 判空，`raw_string` 已清空但 `displayed_multiplier_value` 未清空的情况下，脏值通过。

### 3.3 屏幕外图标的 `displayed_*` 状态

屏幕外的图标：
- 不在 `displayed_icons[][]` 中引用
- 不会在行 3846 的全局 `update_value_text()` 循环中被更新
- 其 `displayed_*` 值保留在**上次出现在屏幕上时**的状态
- 如果图标自那以后经历了 `change_type()`（比如被摧毁/替换），`displayed_*` 没有被重置

---

## 4. 数据汇聚与分组：`_bh_flush()` Phase 4

### 4.1 复合键构建

**文件：** `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:457-460`

```gdscript
var skey = sid
if _bt != '' or _bm != '' or _bb != '':
    skey = sid + '|t=' + _bt + '|b=' + _bb + '|m=' + _bm
```

`skey` 是符号的复合标识符——**type + badge tuple**。不同角标的同类型符号被分到不同桶中。如果 `_bm` 是脏读的旧值，该符号会被错误分组。

### 4.2 分桶与计数

**文件：** `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:461-462`

```gdscript
sym_counts[skey] = sym_counts.get(skey, 0) + 1
```

### 4.3 最终写入

**文件：** `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:480-506`

```gdscript
var entry = {'id': sid, 'count': sym_counts[skey]}
if b.get('saved_value', 0) > 0:
    entry['saved_value'] = b.saved_value
if b.get('item_count', 0) > 0:
    entry['item_count'] = b.item_count
# badge 字段从 sym_badges 读取，而 sym_badges 也是从 fs 条目构建的
if _badge_text != '': entry['badge_text'] = _badge_text
if _badge_mult != '': entry['badge_mult'] = _badge_mult
if _badge_bonus != '': entry['badge_bonus'] = _badge_bonus
```

---

## 5. C# 模型与 JSON 序列化

### 5.1 SymbolInSummary 模型

**文件：** `Piraeus.BetterLandlord\Model\RunSummary.cs:53-136`

```csharp
public class SymbolInSummary
{
    public string Id { get; set; }
    public int Count { get; set; }
    public string? BadgeTextValue { get; set; }   // JSON: badge_text
    public string? BadgeMultValue { get; set; }    // JSON: badge_mult
    public string? BadgeBonusValue { get; set; }   // JSON: badge_bonus
}
```

### 5.2 UI 显示逻辑

**文件：** `Piraeus.BetterLandlord\Model\RunSummary.cs:94-109`

```csharp
[JsonIgnore]
public string BadgeText
{
    get
    {
        // 优先级: badge_text > badge_bonus > badge_mult
        if (!string.IsNullOrEmpty(BadgeTextValue)) return BadgeTextValue;
        if (!string.IsNullOrEmpty(BadgeBonusValue)) return BadgeBonusValue;
        if (!string.IsNullOrEmpty(BadgeMultValue)) return BadgeMultValue;
        return "";
    }
}

[JsonIgnore]
public string? BadgeTextSecondary =>
    !string.IsNullOrEmpty(BadgeTextValue) && !string.IsNullOrEmpty(BadgeBonusValue) ? BadgeBonusValue : null;
```

`BadgeText` 属性决定了 UI 显示的角标文字。如果 `BadgeMultValue`（对应 JSON `badge_mult`）有非空脏值，且 `BadgeTextValue` 和 `BadgeBonusValue` 都为空（正常符号本应如此），则脏的 `badge_mult` 值（如 "2x"）会被当作角标显示。

---

## 6. 时序全景图

```
Spin N 执行
  │
  ├─ 效果解析阶段
  │   ├─ Slot Icon 效果触发
  │   ├─ change_type() 被调用 → permanent_multiplier 重置为 1
  │   │                         → displayed_multiplier_value 保持旧值 ✗
  │   ├─ update_value_text() 在 affected icons 上调用
  │   └─ 行 3846: 全局 update_value_text() 遍历 displayed_icons
  │       → 仅更新可见网格中的图标
  │       → 屏幕外图标的 displayed_* 不变
  │
  ├─ check_values() 执行
  │   ├─ get_value() 在每个可见图标上调用
  │   ├─ update_value_text() 没有被调用
  │   └─ BoardValuePatch Postfix 触发
  │       → 读取 displayed_icons[][] 的 displayed_* 字段
  │       → 发出 "board_value" 事件（含 badge_mult, badge_text, badge_bonus）
  │
  └─ resolve_event("win"/"loss") 触发（游戏结束）
      └─ ResolveEventPatch Prefix 触发
          └─ _bh_end_run() 调用
              → 遍历 Reels.reels[].icons[]（所有图标，含屏幕外）
              → 读取 i.displayed_text_value, i.displayed_multiplier_value, i.displayed_bonus_value
              → 屏幕外图标的 displayed_* 可能是上次出现在屏幕上的旧值
              → 将值写入 run_end 事件的 fs 条目
              └─ _bh_flush() Phase 4
                  → 按 id + badge tuple 分组
                  → 脏的 badge_mult 导致符号被分到错误的桶
                  → 写入 runs/<id>.json
                      └─ HistoryStore 反序列化 → SymbolInSummary.BadgeMultValue
                          └─ UI: BadgeText 优先显示 badge_mult → "2x" / "1.5x"
```

---

## 7. 脏读窗口的具体场景

### 场景 A：屏幕外图标携带旧类型角标

1. 图标 A（类型 X，有 multiplier *2 → `displayed_multiplier_value = "2x"`）被推到屏幕外
2. 图标 A 停止被 `update_value_text()` 更新
3. 图标 A 的 `displayed_multiplier_value = "2x"` 保持不变
4. 之后图标 A 可能经历 `change_type()` → `permanent_multiplier` 被重置但 `displayed_multiplier_value` 未动
5. `_bh_end_run()` 遍历 `reels[].icons[]` 时读到屏幕外图标 A，其 `displayed_multiplier_value` 仍是 "2x"
6. 图标 A 当前类型 Z 没有 multiplier → 却被记录为有 "2x" 角标

### 场景 B：`change_type()` 与 `update_value_text()` 之间

1. 符号 X（有 multiplier）在 `check_values()` 之前被 `change_type()` 变为符号 Y（无 multiplier）
2. `change_type()` 行 423: `permanent_multiplier = 1`（正确）
3. `change_type()` 不清空 `displayed_multiplier_value`（仍为 "2x"）
4. 如果 `update_value_text()` 没来得及在 `check_values()` 之前运行（或 `update_value_text()` 的相邻图标触发没覆盖到）
5. BoardValuePatch 的 Postfix 读到 `displayed_multiplier_value = "2x"` → 错误记录

### 场景 C：`check_values()` 在 `update_value_text()` 之前

效果解析阶段结束后 `check_values()` 立即执行。如果某个图标在效果解析阶段的末尾才被修改（比如某效果的连锁反应），该图标的 `update_value_text()` 可能被排入延迟队列或尚未触发，导致 `check_values()` 时 `displayed_*` 是旧的。

---

## 8. 涉及的全部文件

| 文件 | 角色 |
|------|------|
| `game_source_code/Slot Icon.tscn__1.gd:119-121` | `displayed_*` 字段声明 |
| `game_source_code/Slot Icon.tscn__1.gd:1373-1503` | `update_value_text()` — 唯一赋值点 |
| `game_source_code/Slot Icon.tscn__1.gd:346-476` | `change_type()` — 不重置 displayed_* |
| `game_source_code/Slot Icon.tscn__1.gd:665` | `update_value_text()` 调用点（相邻图标） |
| `game_source_code/Slot Icon.tscn__1.gd:3846` | `update_value_text()` 全局调用点 |
| `game_source_code/Main.tscn__4.gd:1169-1248` | `check_values()` — 不调 update_value_text |
| `Piraeus.BetterLandlord/Patches/BoardValuePatch.cs:10-39` | 每局角标捕获 (Postfix on check_values) |
| `Piraeus.BetterLandlord/Patches/ResolveEventPatch.cs:10-15` | 终局触发 (Prefix on resolve_event) |
| `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:771-793` | `_bh_end_run()` — 终局快照读取 |
| `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:457-506` | `_bh_flush()` Phase 4 — 分组合并 |
| `Piraeus.BetterLandlord/Model/RunSummary.cs:53-136` | C# 模型与 UI 显示逻辑 |
