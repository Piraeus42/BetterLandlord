# DPT 旧格式迁移报告

## 第 1 步：迁移逻辑

### 位置

**`RunRecord.MigrateDptIfNeeded()`** — 模型层公共方法。

调用点：
1. `HistoryStore.Load()` — 文件加载后立即调用（行 42-43）
2. `HistoryViewModel.CurrentRecord` setter — IPC 加载后兜底调用（行 55）

### 触发条件（三连与）

```csharp
if (s.DptSummary.Count > 0) return;  // 已有数据 → 跳过（幂等）
if (syms == null || syms.Count == 0) return;  // 无符号 → 跳过
if (!hasDpt) return;  // 无 total_value > 0 的条目 → 跳过
```

### 重建逻辑

```csharp
// 按 base ID 分组，每个 base 取 total_value 最大的一条
var best = new Dictionary<string, SymbolInSummary>();
foreach (var sym in syms)
{
    if (string.IsNullOrEmpty(sym.Id)) continue;
    if (best.TryGetValue(sym.Id, out var cur))
    {
        if (sym.TotalValue > cur.TotalValue)
            best[sym.Id] = sym;      // 取 max，不求和
    }
    else
    {
        best[sym.Id] = sym;
    }
}

// 每个 base ID 生成一条 DptEntry
foreach (var kv in best)
{
    var sym = kv.Value;
    s.DptSummary.Add(new DptEntry
    {
        Id = sym.Id,
        TotalValue = sym.TotalValue,
        TurnsPresent = sym.TurnsPresent,
        TurnsContributing = sym.TurnsContributing,
        DptActual = sym.DptActual,
        DptEffective = sym.DptEffective,
        Departed = false   // 旧格式无法追踪离场符号
    });
}
```

### 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 取 max vs 求和 | **取 max** | 旧格式两代：第一代在每个 badge 变体上重复同一份 DPT（求和翻倍），第二代只一条非 0 其余为 0。取 max 同时兼容 |
| 整条取 vs 逐字段取 max | **整条取** | 保持 `total_value` / `turns_present` / `turns_contributing` 内部一致性 |
| departed | **一律 false** | 旧格式中途离场符号不在 symbols[] 中（旧缺陷 B），无法恢复 |
| 内存 vs 持久化 | **纯内存** | 不篡改历史 JSON，避免不可逆破坏。迁移开销极小（遍历一次） |
| 迁移位置 | **HistoryStore.Load + ViewModel setter 双重覆盖** | 覆盖文件加载和 IPC 加载两条路径 |

---

## 第 3 步：验证

### 构建

```bash
dotnet build Piraeus.BetterLandlord/Piraeus.BetterLandlord.csproj -c Release   # 0 warnings, 0 errors
dotnet build Piraeus.BetterLandlord.UI/Piraeus.BetterLandlord.UI.csproj -c Release  # 0 warnings, 0 errors
```

### 测试样本

| 样本 | 格式 | 描述 |
|------|------|------|
| GEN1 | 最早格式 | cat 出现两次（普通 + 2x badge 变体），两条 total_value 都是 300 |
| GEN2 | 过渡格式 | cat 出现两次，只有普通变体有 total_value=300，badge 变体无 DPT 字段 |
| GEN3 | 新格式 | dpt_summary 已有数据，迁移不触发 |

### 结果

| 样本 | 迁移触发 | cat total_value | 验证 |
|------|---------|----------------|------|
| GEN1 (dup) | ✅ | **300**（非 600） | 不翻倍 |
| GEN2 (single) | ✅ | **300**（取到非 0 条） | 正常 |
| GEN3 (new) | ❌ 跳过 | 300（原生数据） | 不重复迁移 |

---

## 第 4 步：改动文件

| 文件 | 改动 |
|------|------|
| `Model/RunRecord.cs:28-95` | 新增 `MigrateDptIfNeeded()` 方法 |
| `Storage/HistoryStore.cs:42-43` | `Load()` 中 post-deserialize 调用迁移 |
| `ViewModels/HistoryViewModel.cs:55` | `CurrentRecord` setter 中兜底调用迁移 |

## 无法恢复

- 旧格式中途被摧毁/移除/转化的离场符号 — 旧缺陷 B 导致它们根本不在 `symbols[]` 中，无法迁移。这是旧数据固有的数据丢失，新格式 run 已修复

## 风险

- 旧 JSON 的 DPT 数据质量取决于序列化时的状态。如果旧 JSON 的 `total_value` 本身就是 0（异常情况），迁移后 DPT 为空——这是正确的行为
- `MigrateDptIfNeeded()` 在 setter 中被调用，意味着每次切换 record 都会幂等检查一次，开销可忽略
