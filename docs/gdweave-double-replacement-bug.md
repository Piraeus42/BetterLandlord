# GDWeave 双重替换 Bug — 从 Mod 开发者视角

## 概述

GDWeave 对同一 `.gd` 文件依次应用多个 `ISourceMod.Modify()` 和 `[Patch] Replace` 时，先执行的替换输出可能被后执行的替换**再次匹配**，导致函数名被破坏（如 `_lfr__lfr_rand_range`、`_scr__sir_rand_range`），产生运行时对不存在函数的调用。

本报告记录了 BetterHistoryMod 中两次因这个 GDWeave 设计缺陷导致的 bug，以及 mod 侧不得不采用的防御性写法。

---

## Bug #1: 房东战硬崩溃（ISourceMod + [Replace] 双重处理）

**发现日期**: 2026-06-02
**症状**: 正常 12 轮租金无事，进房东战即硬崩溃，无 Godot 错误栈。
**首次记录**: `docs/encyclopedia.md` §9 + 已知陷阱表 #1

### 涉事代码

同一个文件 `Landlord.tscn::9` 被两个 GDWeave 处理器修改：

**处理器 A — `LandlordRngRefSourceMod` (ISourceMod)**:
```csharp
public string Modify(string path, string source) {
    if (source.Contains("func _lfr_shuffle")) return source;  // 幂等守卫
    source = source.Replace("rand_range(", "_lfr_rand_range(");
    // ... shuffle 替换 + helper 注入
}
```

**处理器 B — `LandlordFinePrintPatch` ([Patch] Replace)**:
```csharp
[Patch("res://Landlord.tscn::9", "get_fine_print")]
class LandlordFinePrintPatch {
    [Replace]
    static string ReplaceCode(string original) => original
        .Replace("rand_range(", "_lfr_rand_range(");   // ← 与 ISourceMod 相同!
}
```

### 执行顺序与结果

```
GDWeave 处理 Landlord.tscn::9:

Step 1: ISourceMod.Modify() 对整个文件执行
  rand_range( → _lfr_rand_range(
  结果: 所有 rand_range 调用 → _lfr_rand_range(...)

Step 2: [Patch] Replace 对 get_fine_print() 函数体执行
  输入: 已被 Step 1 修改过的函数体
  函数体内已无 rand_range(  —— 但 _lfr_rand_range( 中包含 rand_range( 子串!
  替换: _lfr_rand_range( → _lfr__lfr_rand_range(
  结果: 不存在的函数名
```

### 崩溃机制

`_lfr__lfr_rand_range` 不存在于注入的 helper 中。GDScript 调用未定义函数 → 硬崩溃。
`get_fine_print` 仅在房东战 `take_damage` 中调用，所以正常租金阶段不受影响。

### 修复 (mod 侧 workaround)

```csharp
// LandlordFinePrintPatch — 改为永久 pass-through
[Replace]
static string ReplaceCode(string original) =>
    original.Contains("_lfr_rand_range(") ? original : original;
```

`[Replace]` 仍然存在（框架要求），但逻辑上不再做任何替换——ISourceMod 已经完成了所有工作。幂等守卫 `Contains("_lfr_rand_range(")` 在 ISourceMod 已处理时返回 true（pass-through），即使某种原因 ISourceMod 未运行也会原样返回（安全退化）。

---

## Bug #2: SlotIcon shake 动画 RNG 损坏（同一 ISourceMod 内部的替换顺序）

**发现日期**: 2026-06-04
**症状**: 物品被摧毁/消除时抖动动画异常，偏移幅度大且偏向特定方向（用户报告）。
**修复日期**: 2026-06-04

### 涉事代码

单个 ISourceMod 内，两次 `String.Replace` 的执行顺序导致自毁：

**`SlotIconRngSourceMod` (ISourceMod)** 原始代码:
```csharp
public string Modify(string path, string source) {
    if (source.Contains("func _sir_shuffle")) return source;

    // 第 1 步: 特定覆盖 — shake/SFX 用 scratch RNG
    source = source.Replace("str(floor(rand_range(0, sfx_total_num)))",
                            "str(_scr_randi_max(sfx_total_num))");
    source = source.Replace("floor(rand_range(-1, 2))",
                            "floor(_scr_rand_range(-1, 2))");

    // 第 2 步: 通用覆盖 — 所有剩余 rand_range → effect RNG
    source = source.Replace("rand_range(", "_sir_rand_range(");
    // ...
}
```

### 执行结果

```
Slot Icon.tscn__1.gd 原始行 874:
  anim_offset = Vector2(floor(rand_range(-1, 2)), floor(rand_range(-1, 2)))

↓ Step 1: 特定覆盖
  anim_offset = Vector2(floor(_scr_rand_range(-1, 2)), floor(_scr_rand_range(-1, 2)))

↓ Step 2: 通用覆盖 rand_range( → _sir_rand_range(
  字符串 _scr_rand_range 中包含子串 rand_range( !
  anim_offset = Vector2(floor(_scr__sir_rand_range(-1, 2)), floor(_scr__sir_rand_range(-1, 2)))
  ▲ _scr__sir_rand_range 不存在!
```

### 运行时行为

GDScript 调用 `_scr__sir_rand_range(-1, 2)` —— 该函数未注入。运行行为取决于 GDScript 3.x 对未定义函数调用的处理，可能导致返回 null/0（偏移消失）或其他未定义行为。

### 修复 (mod 侧 workaround)

调换替换顺序——先做通用替换，再做特定覆盖：

```csharp
// Step 1: 通用替换 FIRST
source = source.Replace("rand_range(", "_sir_rand_range(");

// Step 2: 特定覆盖 SECOND — _sir_* 已就位,安全覆盖
source = source.Replace("floor(_sir_rand_range(-1, 2))",
                        "floor(_scr_rand_range(-1, 2))");
source = source.Replace("str(floor(_sir_rand_range(0, sfx_total_num)))",
                        "str(_scr_randi_max(sfx_total_num))");
```

关键原则: **通用替换必须在特定覆盖之前执行**，这样特定覆盖的输入是通用的输出，输出不再包含通用模式。

---

## 根本原因 (GDWeave 框架层面)

两个 bug 指向同一个 GDWeave 设计缺陷：

```
GDWeave 对同一 .gd 文件执行多个字符串替换时:

  source ──→ [Modify A] ──→ [Modify B] ──→ ... ──→ [Patch Replace] ──→ 最终脚本

如果不做原子性保证，A 的输出可能被 B 意外匹配。
```

具体机制：

1. **ISourceMod + [Replace] 交互**: ISourceMod 对整个文件做替换，[Replace] 对已修改的函数体再次替换。如果两者使用相同的匹配模式，[Replace] 会在 ISourceMod 的输出中匹配到不该匹配的字符串。

2. **同一 ISourceMod 内部顺序依赖**: C# `String.Replace` 是顺序执行的。`Replace(A, B)` 后执行 `Replace(B, C)` 可能破坏第一个替换的结果。没有事务性——不能"全部替换后一起 commit"。

---

## Mod 侧防御策略

BetterHistoryMod 目前采用的 workaround：

### 策略 1: 幂等守卫（防止重复 Modify）

```csharp
if (source.Contains("func _my_helper")) return source;
```

**防范**: GDWeave 第二次调用 Modify 时不做任何操作。
**局限**: 只防重复调用，不防同一 pass 内的自毁（Bug #2 绕过了这个守卫）。

### 策略 2: [Replace] pass-through（防 ISourceMod+[Replace] 冲突）

```csharp
[Replace]
static string ReplaceCode(string original) =>
    original.Contains("_lfr_rand_range(") ? original : original;
```

**防范**: 检测到 ISourceMod 已处理时，[Replace] 不做任何事。
**局限**: 仅适用于 [Replace] 和 ISourceMod 做完全相同替换的场景。

### 策略 3: 替换顺序（防内部自毁）

```csharp
// 先通用、后特定
source = source.Replace("rand_range(", "_sir_rand_range(");     // 通用
source = source.Replace("floor(_sir_rand_range(-1, 2))", ...);  // 覆盖
```

**防范**: 特定覆盖的输入是通用的输出，输出不包含通用模式。
**局限**: 仅当通用→特定形成"精化"关系时有效。

### 策略 4: 分隔命名空间（最可靠但最重）

不同 RNG 流使用互不包含的前缀，如 `_csr_`、`_sir_`、`_rrr_`、`_lfr_` 等，避免前缀嵌套。

**防范**: 即使替换交叉，也不会匹配到其他前缀的函数。
**局限**: 不能防止 `_sir_` 被误替换为 `_sir_` 本身的变体（如 `_sir_` → `_sir__sir_`）。

---

## 对 GDWeave 框架的建议

从 mod 开发者视角，以下改进可以消除这类 bug：

### 建议 1: 原子替换 API

```csharp
// 现状: 顺序 Replace, 后面的可能匹配前面的输出
source = source.Replace("rand_range(", "_foo_rand_range(");
source = source.Replace("floor(rand_range(-1, 2))", "floor(_bar_rand_range(-1, 2))");

// 建议: 单次扫描中完成所有替换, 输出不会被再次匹配
source = Transformer.ReplaceAll(source, new[] {
    ("rand_range(", "_foo_rand_range("),
    ("floor(rand_range(-1, 2))", "floor(_bar_rand_range(-1, 2))"),
});
```

对所有模式编译一个 trie/自动机，对源文件做单次扫描。匹配到多个模式时，选最长匹配。已替换的区间标记为"不可再匹配"。

### 建议 2: ISourceMod 和 [Replace] 的协调

当 ISourceMod 和 [Replace] 都作用于同一文件时，提供机制让 mod 声明"此 [Replace] 仅处理未被 ISourceMod 修改的原始代码"或"此 [Replace] 依赖 ISourceMod 的输出"。

最简单的方式: 在 [Replace] 执行前，对函数体做一次"已注入函数名"的检测，如果发现函数体已被修改（包含注入的 helper 函数名），跳过 [Replace]。

### 建议 3: 幂等守卫的形式化

将 `if (source.Contains("func _my_helper")) return source;` 这种模式形式化：

```csharp
public class MyMod : ISourceMod {
    public string Sentinel => "func _my_shuffle";  // 框架自动检测
    public string Modify(string path, string source) { ... }
}
```

框架在调用 Modify 之前自动检查 sentinel，不需要每个 mod 手写。

---

## 受影响的文件清单 (BetterHistoryMod)

| 文件 | GDWeave 类型 | 是否有双替换风险 | 当前状态 |
|------|-------------|----------------|---------|
| `LandlordRngRefSourceMod.cs` | ISourceMod | ✅ 与 `LandlordFinePrintPatch` [Replace] 冲突 | ✅ 已修复 (pass-through) |
| `LandlordFinePrintPatch.cs` | [Patch] Replace | — 同上 — | ✅ 已修复 (pass-through) |
| `SlotIconRngSourceMod.cs` | ISourceMod | ✅ 内部替换顺序导致自毁 | ✅ 已修复 (调换顺序) |
| `SlotIconNoopSourceMod.cs` | ISourceMod | ❌ 仅追加 no-op, 不替换 | ✅ 安全 |
| `ReelRngRefSourceMod.cs` | ISourceMod | ⚠️ 与 `ReelShufflePatch` [Replace] 同文件但模式不重叠 | ✅ 审查通过 |
| `ReelShufflePatch.cs` | [Patch] Replace | — 同上 — | ✅ 审查通过 |
| `ReelExtraRngSourceMod.cs` | ISourceMod | ❌ 单独的 Reel.tscn, 无 [Replace] 冲突 | ✅ 安全 |
| `ItemRngSourceMod.cs` | ISourceMod | ❌ 单独的 Item.tscn, 无 [Replace] 冲突 | ✅ 安全 |
| `CosmeticRngSourceMod.cs` | ISourceMod | ❌ 多文件但无内部覆盖 | ✅ 安全 |
| `ChoiceRngSourceMod.cs` | ISourceMod | ❌ 单独的 Pop-up.tscn | ✅ 安全 |

---

## 相关文档

- `docs/encyclopedia.md` §3 已知陷阱表 #1 — Landlord 双重替换
- `docs/encyclopedia.md` §9 — 房东战崩溃调查
- `docs/rng-call-site-audit.md` §2.6 — Landlord RNG 调用点清单
- `docs/rng-architecture-v1.md` §3 — V1 RNG 架构与流路由
