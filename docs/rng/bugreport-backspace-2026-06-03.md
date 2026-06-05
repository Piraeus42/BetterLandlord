# Backspace 快捷键与种子输入框冲突 Bug Report

> 2026-06-03 · 未解决

## 症状

种子输入框(LineEdit)获得焦点时,按退格键(Backspace):
- **预期**: 删除输入框中的字符
- **实际**: 触发游戏"返回主界面"快捷键,从楼层菜单退出到标题画面

## 已尝试的方案(全部失败)

### 方案 1: `_gui_input` + `accept_event()`

在 LineEdit 的 `gui_input` 信号中捕获 KEY_BACKSPACE 并调用 `accept_event()` 阻止传播。

**失败原因**: 退格键在 Godot 引擎层被 `BaseButton.shortcut` 系统处理,**早于** `_gui_input`。事件传播顺序: Engine shortcut → `_input` → `_gui_input` → `_unhandled_input`。

### 方案 2: Patch `Main._input` 的 Prefix,`return` 跳过

在 `_input` Prefix 中检测种子输入框焦点,`return` 跳过函数体。

**失败原因**: SlotWeave `[Prefix]` 的 `return` 只跳出 Prefix 代码块,**不阻止**原函数体执行。

### 方案 3: Patch `Main._input` 的 Prefix,`event.scancode = 0` 中和事件

在 `_input` Prefix 中将 `event.scancode` 改为 `KEY_UNKNOWN`,使 hotkey 匹配失败。

**失败原因**: 同方案 1 — 退格键的 `BaseButton.shortcut` 处理在引擎层,`_input` Prefix 到达时引擎已触发按钮。

### 方案 4: 临时禁用 `back_button.shortcut`

种子输入框获得焦点时设 `back_button.shortcut = null`,失去焦点时恢复 `back_button.shortcuts = ['deny_cancel']`。

**失败原因**: 需要确认 — `shortcut`/`shortcuts` 属性修改是否即时生效,以及 `Options.back_button` 节点引用是否正确。

## 确认的机制

1. `Title.tscn::6` 中 `back_button.shortcuts = ["deny_cancel"]` (行 666, 798)
2. `Options.hotkeys["deny_cancel"][0]` 映射到某键位(可能是 KEY_BACKSPACE)
3. **Godot 引擎的 `BaseButton.shortcut` 系统**在 `_input` 之前处理快捷键,直接触发 `button.pressed` → `do_call()` → `title()`
4. 常规的 GDScript 事件拦截(`_input` / `_gui_input`)都来不及

## 可能需要探索的方向

1. **修改 `Options.hotkeys["deny_cancel"]`**: 输入框焦点时临时改 hotkey 绑定
2. **SlotWeave 原生层**: 用 C# 在引擎更底层拦截
3. **修改 `back_button` 的 `shortcut_in_tooltip`**: 设为 false 阻止引擎处理
4. **替换 `back_button` 的 `shortcuts` 为空数组而非 null**: `_back.shortcuts = []`
5. **连接 `focus_entered`/`focus_exited` 信号时机**: 确认是否在引擎 shortcut 处理之后
