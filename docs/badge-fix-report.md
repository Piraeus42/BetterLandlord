# 角标脏读修复报告

## 第 0 步：核实结论

| 假设 | 位置 | 核实结果 |
|------|------|---------|
| `displayed_multiplier_value` else 分支漏清空 | `Slot Icon.tscn__1.gd:1480-1481` | **成立。** `get_child(2).raw_string = ""` 被清空，`displayed_multiplier_value` 未动。`displayed_text_value`（行 1460）和 `displayed_bonus_value`（行 1500）正确清空 |
| `change_type()` 不重置 `displayed_*` | `Slot Icon.tscn__1.gd:346-476` | **成立。** `overwrite_values` 分支重置 `permanent_multiplier=1`（行 423），但不碰 `displayed_*` |
| BoardValuePatch 有 `raw_string` 守卫 | `BoardValuePatch.cs:29` | **成立。** `_icon.get_child(2).raw_string != ''` 守卫存在 |
| `_bh_end_run()` 缺少守卫 | `MainScriptSourceMod.cs:787-792` | **成立。** 仅 `_bm != ''` 判空 |
| 屏幕外图标逃离 `update_value_text()` 刷新 | `Slot Icon.tscn__1.gd:3846` | **成立。** 全局刷新只遍历 `displayed_icons[][]`（可见网格） |

**可改性判定：**
- `game_source_code/` — **只读反编译参考**，不参与运行时注入。通过 mod 的 `ISourceMod` / `[Patch]` 机制修改运行时脚本
- `MainScriptSourceMod.cs` — **直接可改**（mod C# 源码）
- `BadgeFixSourceMod.cs` — **新建** ISourceMod，注入到 `Slot Icon.tscn::1`

## 第 1 步：分层修复

### 修复 1：源头层 — 补全 `displayed_multiplier_value` 清空逻辑

**文件：** `Piraeus.BetterLandlord/Patches/BadgeFixSourceMod.cs`（新建）

**机制：** ISourceMod 注入到 `res://Slot Icon.tscn::1`，在 `update_value_text()` 的 `permanent_multiplier == 1` 分支追加 `displayed_multiplier_value = ""`，与 `displayed_text_value` / `displayed_bonus_value` 行为对齐。

**注入点（原版代码 `Slot Icon.tscn__1.gd:1480-1481`，1 tab / 2 tabs 缩进）：**
```gdscript
	else:
		get_child(2).raw_string = ""
```
→ 替换为：
```gdscript
	else:
		get_child(2).raw_string = ""
		displayed_multiplier_value = ""  # BH-FIX: clear stale multiplier
```

tab 数量已通过 `cat -A` 验证：`else:` 前 `^I`（1 tab），`get_child(2)` 前 `^I^I`（2 tabs）。新增行的缩进为 2 tabs（else 体内）。

### 修复 2：捕获层 — `_bh_end_run()` 以实时状态为真相来源

**文件：** `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:787-792`

**改动前：**
```gdscript
var _bt = str(i.displayed_text_value)
var _bm = str(i.displayed_multiplier_value)
var _bb = str(i.displayed_bonus_value)
if _bt != '': entry['badge_text'] = _bt
if _bm != '': entry['badge_mult'] = _bm
if _bb != '': entry['badge_bonus'] = _bb
```

**改动后：**
```gdscript
var _bt = str(i.displayed_text_value)
# Use permanent_multiplier as truth source, not displayed string.
# change_type() reliably resets permanent_multiplier but not
# displayed_multiplier_value, so the string can be stale.
var _bm = ''
if i.permanent_multiplier != 1:
    _bm = str(i.displayed_multiplier_value)
var _bb = str(i.displayed_bonus_value)
if _bt != '': entry['badge_text'] = _bt
if _bm != '': entry['badge_mult'] = _bm
if _bb != '': entry['badge_bonus'] = _bb
```

**取舍理由：** `i.permanent_multiplier` 是实时数值，`change_type()`（行 423）和 `_init` 都可靠地重置为 1，不依赖字符串缓存。`displayed_multiplier_value` 仅作为格式化装饰——只有当 `permanent_multiplier != 1`（确实有倍数）时才信任其字符串用于记录。BoardValuePatch 的每局捕获已有 `raw_string` 守卫，无需改。

### 修复 3：注册新 SourceMod

**文件：** `Piraeus.BetterLandlord/Mod.cs:32`

在 `SlotIconRngSourceMod` 之后、`HoverIconRemovalSourceMod` 之前插入：
```csharp
_modInterface.RegisterSourceMod(new BadgeFixSourceMod());
```

### 未触及的部分

- **BoardValuePatch** — 已有 `raw_string` 守卫，每局事件不会被脏值污染
- **`change_type()`** — 注入 `overwrite_values` 分支清空 `displayed_*` 需要修改 `Slot Icon.tscn::1` 中约 100+ 行的函数体中特定位置，锚点不唯一，风险高于收益。两个已实施的修复覆盖了其脏值传播路径
- **`_bh_flush()` Phase 4 分组** — 上游不再产生脏值，分组自动修复

## 第 2 步：构建与自测

### 构建

```bash
dotnet build Piraeus.BetterLandlord/Piraeus.BetterLandlord.csproj -c Release
```

结果：**0 个警告，0 个错误。** 构建成功。

### 部署

DLL 已拷贝到 `D:/steam/.../SlotWeave/mods/Piraeus.BetterLandlord/`。

### 手动验证路径

| 场景 | 预期 | 验证方式 |
|------|------|---------|
| 场景 A：屏幕外旧角标 | 离线图标回到屏幕上后，角标不复存在 | 游戏内多次 spin 后触发终局，检查 history JSON 中不该有 phantom `badge_mult` 条目 |
| 场景 B：change_type 后 | 符号类型变后 multiplier 清空 | 如 Hex of Destruction 摧毁带 multiplier 的符号，新符号无角标 |
| 场景 C：正常 multiplier 符号 | 仍然正确显示 | Telescope 等带 *2 效果的符号角标不变 |
| 场景 D：无 multiplier 符号 | 不再出现 *2/*1.5 | 检查 runs JSON 中 `badge_mult` 字段仅出现在有倍数的符号上 |

### 风险与行为差异

- **源头层修复**：仅在一个 else 分支内追加一行赋值，不改变控制流，不引入新逻辑路径
- **捕获层修复**：`i.permanent_multiplier` 在 Slot Icon 上始终存在（实例变量声明于 `Slot Icon.tscn__1.gd` 顶部），不会产生 nil 引用错误。用 `!= 1` 与游戏原生 `update_value_text()` 判定完全一致
- **没有行为差异**：正确 multiplier 的符号仍会被记录；错误 multiplier 不再被记录
- **可逆性**：删除 `BadgeFixSourceMod.cs` + 回滚 `MainScriptSourceMod.cs` 两行即可完全撤销

## 涉及文件清单

| 文件 | 改动 |
|------|------|
| `Piraeus.BetterLandlord/Patches/BadgeFixSourceMod.cs` | **新建** — 源头层 ISourceMod |
| `Piraeus.BetterLandlord/Patches/MainScriptSourceMod.cs:787-792` | **修改** — `_bh_end_run()` 捕获层守卫 |
| `Piraeus.BetterLandlord/Mod.cs:32` | **修改** — 注册新 SourceMod |
