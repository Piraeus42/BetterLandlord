# DPT v2 — 独立 base 维度聚合视图

## 第 2 步：JSON 承载形式选择

**选择：在 `summary` 下新增 `dpt_summary` 数组。**

```json
{
  "summary": {
    "symbols": [...],
    "dpt_summary": [
      {"id": "cat", "total_value": 450, "turns_present": 5, "turns_contributing": 4, "dpt_actual": 90.0, "dpt_effective": 112.5},
      {"id": "dog", "total_value": 120, "turns_present": 3, "turns_contributing": 2, "dpt_actual": 40.0, "dpt_effective": 60.0, "departed": true}
    ]
  }
}
```

**理由：**
- `dpt_summary` 独立于 `symbols` 数组，职责清晰——symbols 描述终局快照（含 badge 变体），dpt_summary 描述全局统计（per base ID）
- 不污染 symbol 条目（symbol 不再带 DPT 字段）
- 顶层独立数组意味着反序列化到 `List<DptEntry>` 自然映射，无需额外解析逻辑
- 新增字段不影响旧 JSON 解析——旧文件没有该键 → 反序列化为空列表，UI 显示"无 DPT 数据"

**向后兼容：**
- `SymbolInSummary` 保留 DPT 字段（`TotalValue`、`TurnsPresent`、`TurnsContributing`、`DptActual`、`DptEffective`、`Departed`），均标记 `WhenWritingDefault`——新 run 不写，旧 run 反序列化时出现也不报错
- 旧 JSON 有 `total_value` 在 symbol 上 → 仍然能反序列化到 `SymbolInSummary`，但这些字段不再被 UI 消费
- `DptSummary` 列表为空时 → UI DPT 排名显示空（旧 run 无 DPT 数据）
- 影响范围：历史 run 的 DPT 排名为空，符号列表和 timeline 不受影响

---

## 改动清单

### 文件 1：`MainScriptSourceMod.cs` — Phase 4 重构

**改动前：** DPT 字段挂在 `sym_summary` 的某条 badge 变体上，`_dpt_written` 控制单变体，离场符号混在 `sym_summary` 末尾

**改动后：**
1. `sym_summary` 回归纯粹——终局符号 + badge 变体 + count，不带 DPT
2. 新增独立 `dpt_summary` 数组，per base ID，覆盖全部有 DPT 数据的符号（含离场）
3. 写入 `summary.dpt_summary`

```gdscript
# sym_summary 循环 — 只写 badge/count，不写 DPT
var sym_summary = []
for skey in sym_counts.keys():
    ...
    entry = {'id': sid, 'count': sym_counts[skey], ...badge fields...}
    sym_summary.append(entry)

# dpt_summary — 独立 base 维度
var dpt_summary = []
var _dpt_seen = {}
# 先在 f_symbols 中的
for skey in sym_counts.keys():
    _sid = base id
    if not _dpt_seen.has(_sid):
        dpt_summary.append({id, total_value, turns_present, turns_contributing, dpt_actual, dpt_effective})
        _dpt_seen[_sid] = true
# 离场符号
for _sid in symbol_present_count.keys():
    if not _dpt_seen.has(_sid):
        dpt_summary.append({id, ..., departed: true})
        _dpt_seen[_sid] = true

# summary 字典
var summary = {
    'symbols': sym_summary,
    ...
    'dpt_summary': dpt_summary
}
```

### 文件 2：`RunSummary.cs` — 新增 `DptEntry` 类

```csharp
// RunSummary 新增
[JsonPropertyName("dpt_summary")]
public List<DptEntry> DptSummary { get; set; } = new();

// 新增类
public class DptEntry
{
    public string Id { get; set; }
    public double TotalValue { get; set; }
    public int TurnsPresent { get; set; }
    public int TurnsContributing { get; set; }
    public double DptActual { get; set; }
    public double DptEffective { get; set; }
    public bool Departed { get; set; }           // WhenWritingDefault
    public string DptDisplay => ...;
}
```

`SymbolInSummary` 保留 DPT 字段（`WhenWritingDefault`）用于旧 JSON 反向兼容，新代码不写入。

### 文件 3：`HistoryViewModel.cs` — 简化 RefreshRanking

**改动前：** 72 行合并逻辑——从 `Symbols` 按 base ID 聚合、求和 TotalValue、取 Max TurnsPresent、传播 Departed，中间使用 `SymbolInSummary` 作为合并容器

**改动后：** 12 行直接消费 `DptSummary`

```csharp
var dpt = _currentRecord?.Summary?.DptSummary;
if (dpt == null || dpt.Count == 0) return;

var ranked = dpt.OrderByDescending(GetValue).Take(10).ToList();
// ... build DptRankEntry from DptEntry directly
```

不再需要从 `SymbolInSummary` 合并、不再需要 `TurnsContributing` 取 Max 的 workaround。`DptRankEntry.Count` 设为 0（DPT 是 base 维度，没有 badge 计数）。

---

## 第 4 步：清理确认

| 移除项 | 位置 |
|--------|------|
| `_dpt_written` 字典 | `MainScriptSourceMod.cs` Phase 4 — 改为 `_dpt_seen`（仅用于 dpt_summary 去重） |
| `sym_summary` 上的 DPT 字段写入 | 整段替换为 badge-only |
| `HistoryViewModel` 的 `SymbolInSummary` 合并逻辑 | 整段替换为直接消费 `DptEntry` |
| `TurnsContributing` 取 Max 的 workaround | 随合并逻辑一起移除 |

| 保留项 | 原因 |
|--------|------|
| `SymbolInSummary` DPT 字段声明 | 旧 JSON 反序列化兼容 |
| `symbol_present_count` / `symbol_contributing_count` | `dpt_summary` 构建的直接数据源 |
| `_sn > 0` spin 0 排除 | 保持不变 |

---

## 第 5 步：构建与验证

### 构建

```bash
dotnet build Piraeus.BetterLandlord/Piraeus.BetterLandlord.csproj -c Release   # 0 warnings, 0 errors
dotnet build Piraeus.BetterLandlord.UI/Piraeus.BetterLandlord.UI.csproj -c Release  # 0 warnings, 0 errors
```

### 手动验证路径

| 场景 | 预期 | 核对字段 |
|------|------|---------|
| 多 badge 变体 → DPT 一条 | 3 个 `cat` + 1 个 `cat\|m=2x` 在 symbols 里，但 dpt_summary 只有一条 `cat` | 检查 `dpt_summary[].id` 无重复 |
| 摧毁符号 → departed | 被摧毁符号的 DPT 条目有 `departed: true`，symbols 里不存在 | 检查 `dpt_summary` 中 `.departed == true` 的条目 |
| spin 0 排除 | 初始 5 符号的 `dpt_actual` 和 `dpt_effective` 非 0 | 检查 `turns_present >= 1` 且 `dpt_actual > 0` |
| 旧 JSON 加载 | 历史 run 文件加载不崩，DPT 排名为空 | 打开旧 run 的 history viewer |
| 新 run | `symbols[].total_value` 等 DPT 字段不存在，DPT 数据全在 `dpt_summary` | 对比新旧 JSON 结构 |

### 无法验证

- 真实游戏完整跑分（无自动化框架）
- 特殊类型符号的 DPT（如 dud/empty 被过滤，coin 等边缘类型）

---

## 第 6 步：风险与行为变化

- **旧 run DPT 排名为空** — 新格式 DPT 在 `dpt_summary`，历史 JSON 无此字段 → 旧 run 的 DPT 排名显示空白。Timeline、符号列表、物品列表不受影响
- **`DptRankEntry.Count = 0`** — UI 可能对 count=0 做过滤。当前 UI 逻辑仅用 Count 做 tooltip 显示，不参与过滤；如果未来加了 `Count > 0` 过滤器需同步调整
- **新 run `symbols[].total_value` 不再出现** — JSON 体积略微减小，无功能影响
