# BetterHistoryMod — 上线前性能审计

**日期**: 2026-06-05
**审计范围**: 全部 C# 源码 + 注入的 GDScript + WPF UI
**优先级定义**: P0=上线前必须修 | P1=应该修 | P2=建议修 | P3=锦上添花

---

## 总览

| 级别 | 数量 | 关键词 |
|------|------|--------|
| **P0** | 3 | O(n²) 合并循环、文件 I/O 滥调、事件分配热点 |
| **P1** | 4 | 缩进 JSON 浪费、全量 JSON 重读、字符串拼接、manifest 重建 |
| **P2** | 4 | O(n) 扫描、数组 remove O(n²)、ViewModel 重建、图标缓存 |
| **P3** | 3 | 大脚本注入、胜率统计、TipAction 分配 |

---

## P0 — 上线前必须修

### P0-1: `_bh_flush()` Phase 4 的 O(n²) 合并循环

**文件**: `MainScriptSourceMod.cs` 第 543-573 行 (注入到 GDScript)

**现状**:
```gdscript
# 对 destroyed_item_accum 的每个 key，遍历整个 des_it 数组查找匹配
for dk in destroyed_item_accum.keys():
    var _found = false
    for _di in des_it:
        if str(_di.get('id', '')) == str(dk):
            ...found...
    if not _found:
        des_it.append({...})
# destroyed_symbol_accum → des_sym 同样模式
# removed_symbol_accum → rem_sym 同样模式
```

**问题**: 三个独立的 O(n×m) 循环在 GDScript 中运行。GDScript 比 C# 慢约 100 倍。一个 100 事件的 run 中 accum 和 dest 各约 5-30 个条目，实际影响不大；但跑长局（无尽模式 500+ spins）时 accum 可达 50+ 键 × 30+ dest 条目 = 1500 次 GDScript 字典操作。

**修复方向**: 用 GDScript Dictionary 做 O(1) 查找，把 `des_it` 先转成 `{id: index}` 的映射表，然后 O(n) 合并。示例：

```gdscript
var _di_map = {}
for _j in range(des_it.size()):
    _di_map[str(des_it[_j].id)] = _j
for dk in destroyed_item_accum.keys():
    if _di_map.has(dk):
        var _idx = _di_map[dk]
        des_it[_idx].count = int(des_it[_idx].count) + int(destroyed_item_accum[dk])
    else:
        des_it.append({'id': str(dk), 'count': int(destroyed_item_accum[dk])})
```

**影响**: 每局结束时节省 ~0.5-5ms（取决于 run 长度），消除 GDScript O(n²) 热点。

---

### P0-2: `_bh_debug_log()` 每次调用打开/写入/关闭文件

**文件**: `MainScriptSourceMod.cs` 第 84-92 行

**现状**:
```gdscript
func _bh_debug_log(msg: String):
    var _df = File.new()
    if _df.file_exists('user://betterHistory/debug.log'):
        _df.open('user://betterHistory/debug.log', File.READ_WRITE)
        _df.seek_end()
    else:
        _df.open('user://betterHistory/debug.log', File.WRITE)
    _df.store_string(str(OS.get_unix_time()) + ' ' + msg + '\n')
    _df.close()
```

**问题**: 每次 `_bh_flush()` 调用这个方法 **6-7 次**（flush_start, phase1_done, phase2_done, phase25_done, phase3_done, phase4_done, phase5_done）。每次调用都是一次完整的 `File.new()` + `file_exists()` + `open()` + `store_string()` + `close()` 周期。GDScript 的文件 I/O 是同步阻塞的，在 Godot 主线程上运行。

**修复方向**: 
- **短期**: 在生产构建中直接 return（`if true: return` 或检查 debug flag）
- **长期**: 把消息追加到数组，仅在 flush 结束时统一写入一次

**影响**: 每局结束时节省 ~6-7 次文件系统同步调用。对 SSD 影响小（<1ms），但 HDD + 杀毒软件可能造成可感知的卡顿。

---

### P0-3: `_bh_add_event()` 每次事件都分配新 Dictionary + 调用 OS.get_datetime()

**文件**: `MainScriptSourceMod.cs` 第 73-82 行

**现状**:
```gdscript
func _bh_add_event(type_str, payload):
    var tm = OS.get_datetime()
    var ts = _bh_fmt_time(tm)
    _bh_events.append({
        'event_id': _bh_run_id + '_' + str(_bh_events.size()),
        'run_id': _bh_run_id,
        'timestamp': ts,
        'type': type_str,
        'payload': payload
    })
```

**问题**: 
- `OS.get_datetime()` 是系统调用，返回 Dictionary
- `_bh_fmt_time()` 做大量字符串操作（见 P1-3）
- 每次创建新的 event Dictionary（5 个键）
- 典型的一局有 **50-200 个事件**（每个 spin 至少 2-3 个 event），单局总计 150-600 次 OS.get_datetime() 调用

**修复方向**: 
- `_bh_run_id + '_' + str(...)` 预先计算 prefix，避免重复拼接
- `_bh_fmt_time` 结果可缓存（同一秒内的事件共享 timestamp 字符串）

**影响**: 每局 ~100-300 个事件时，节省约 2-5ms。更重要的是减少 GC 压力（GDScript 的 Dictionary 分配是主要 GC 触发源）。

---

## P1 — 应该修

### P1-1: JSON 使用缩进格式输出

**文件**: `MainScriptSourceMod.cs` 第 605 行

```gdscript
f.store_string(JSON.print(record, '  '))   # 2-space indent
```

**问题**: 缩进 JSON 比 compact JSON 大约 20-40% 体积。这些文件只被机器读取（C# HistoryStore / PipeServer），不需要人类可读的缩进。一个典型 run 的 JSON 约 50-100KB，缩进浪费 10-25KB。

**修复**: `JSON.print(record)` 去掉第二个参数即可。

**影响**: 每局 I/O 减少 20-40%，manifest 重建时 `JsonDocument.Parse` 也更快。

---

### P1-2: `BuildRunListJson()` 在已有 manifest 的情况下重读所有 run JSON

**文件**: `GamePipeServer.cs` 第 344-436 行

**问题**: 当 WPF 客户端连接时，`BuildRunListJson()` 遍历 manifest entries，然后**对每个 entry 重新 `File.ReadAllText` + `JsonDocument.Parse`** 来读取可能已变化的字段（endedBy, floor, finalCoins 等）。之后还要扫描目录找不在 manifest 中的新文件。

已有 129 个 run 时，这是 129 次文件读取 + JSON 解析。

**修复方向**:
- 大部分字段（endedBy, floor, coins）只在 run 结束时写入一次，不会"变化"
- "quit" → "loss" 的变化只发生在 Continue 后再结束的情况，此时 manifest 可以在 `UpdateManifestEntry` 中实时更新
- 建议：manifest 已经是权威数据源，从 manifest 直接构建列表；仅在找不到 JSON 时才回退到读取文件

**影响**: WPF 连接时响应时间从 ~500ms 降到 ~50ms（129 runs 场景）。

---

### P1-3: `_bh_fmt_time()` 中的字符串碎片化

**文件**: `MainScriptSourceMod.cs` 第 883-899 行

```gdscript
func _bh_fmt_time(tm):
    var _m = str(tm.month)
    if tm.month < 10:  _m = '0' + _m    # 每次 + 创建新字符串
    var _d = str(tm.day)
    if tm.day < 10:    _d = '0' + _d
    # ... 重复 6 次
    return str(tm.year) + '-' + _m + '-' + _d + 'T' + _h + ':' + _mn + ':' + _s
```

**问题**: GDScript 字符串不可变，每个 `+` 创建新分配。`_bh_fmt_time` 每次调用产生 **至少 13 次字符串分配**（6 次 str() + 6 次条件拼接 + 1 次最终拼接）。每局 50-200 次调用 = 650-2600 次字符串分配。

**修复**: 用 GDScript 的 `%` 格式化或直接构造：
```gdscript
func _bh_fmt_time(tm):
    return '%04d-%02d-%02dT%02d:%02d:%02d' % [tm.year, tm.month, tm.day, tm.hour, tm.minute, tm.second]
```
单次分配，没有条件分支。

**影响**: 每局节省 ~600-2500 次字符串分配。

---

### P1-4: `RebuildManifest()` 全量扫描

**文件**: `HistoryStore.cs` 第 58-101 行

**问题**: 每次 mod 初始化都全量扫描 `runs/` 目录，读取每个 JSON 并 `JsonDocument.Parse`。已有优化（JsonDocument 而非完整反序列化），但 120+ runs 时仍需要 120 次磁盘读取 + JSON 解析。

**修复方向**:
- 正常游戏中 runs 目录很少变化（只有新 run 结束时写入 1 个文件）
- 可以只在 manifest 文件缺失/损坏时才重建，正常路径走增量更新
- 增量: `Directory.GetFiles` 对比 manifest entries，只处理新增/缺失的 runId

**影响**: 冷启动时间减少 ~200-500ms（120 runs），后续启动无感知。

---

## P2 — 建议修

### P2-1: `_bh_count_spins()` O(n) 扫描

**文件**: `MainScriptSourceMod.cs` 第 686-691 行

```gdscript
func _bh_count_spins():
    var n = 0
    for _ev in _bh_events:
        if str(_ev.get('type', '')) == 'spin_start':
            n += 1
    return n
```

**问题**: `_bh_end_run()` 调用它做 ghost-run filter 和 debounce check。每次调用遍历全部 events。简单整数计数器即可替代。

**修复**: 新增 `var _bh_spin_count = 0`，在 `spin_start` 事件处理中 `_bh_spin_count += 1`。

---

### P2-2: `_bh_end_run()` 中 `_bh_events.remove(_i)` 的隐性 O(n²)

**文件**: `MainScriptSourceMod.cs` 第 766-773 行

```gdscript
var _i = _bh_events.size() - 1
while _i >= 0:
    var _ev = _bh_events[_i]
    if str(_ev.get('type', '')) == 'run_end':
        ...
        _bh_events.remove(_i)    # GDScript Array.remove() 触发元素移位
    _i -= 1
```

**问题**: GDScript `Array.remove(index)` 会将后续所有元素向前移动一位，是 O(n) 操作。在循环中调用 → O(n²)。虽然 run_end 事件通常只有 1 个，但逻辑上不够安全。

**修复**: 收集需要保留的事件到新数组，最后赋值替换：
```gdscript
var _new_events = []
for _ev in _bh_events:
    if str(_ev.get('type', '')) != 'run_end':
        _new_events.append(_ev)
_bh_events = _new_events
```
单次遍历 O(n)，且避免了 `remove()` 的元素移位。

---

### P2-3: WPF `TimelineRounds` 在每次选中 run 时重建全部 ViewModel

**文件**: `HistoryViewModel.cs` 第 248-258 行

**问题**: 选中新 run → `CurrentRecord` 变化 → 触发 `OnPropertyChanged(nameof(TimelineRounds))` → 完整重建所有 TimelineRoundViewModel 和 SpinCellViewModel。每个 spin cell 都要构建 TooltipActions 列表（2-10 个 TipAction 对象）。

一个 Floor 12 的 run 有 ~8 个 round × 5-12 spins = 40-96 个 cell，每个 cell 3-10 个 TipAction = 120-960 个小对象。

**影响**: 选中 run 时有 10-50ms UI 线程停顿（用户可感知的卡顿）。WPF 用户量不大时可接受，但属于明显的 UX 瑕疵。

**修复方向**: 
- TooltipActions 延迟构建（仅在 ToolTip 打开时构建，使用 `ToolTipOpening` 事件）
- 或虚拟化 `ItemsControl`（加 `VirtualizingStackPanel`）

---

### P2-4: WPF 图标加载无缓存

**文件**: `Converters/IconConverter.cs`

**问题**: XAML 中大量使用 `{Binding Converter={StaticResource IconImage}}`，每次 binding refresh 时 `IconNameToImageConverter.Convert()` 被调用，每次都 `new BitmapImage(new Uri(...))` 从磁盘加载 PNG。

一个 run 详情页面有 ~100+ 图标引用。每次切换 run 时全部重新加载。

**修复**: 在 converter 中加 `ConcurrentDictionary<string, BitmapImage>` 缓存。游戏图标不会变化，可以永久缓存。

---

## P3 — 锦上添花

### P3-1: 注入的大段 GDScript 源码

**文件**: `MainScriptSourceMod.cs` (~900 行 GDScript) + `RngInfrastructureSourceMod.cs` (~415 行 GDScript)

**问题**: 启动时 `MainScriptSourceMod.Modify()` 把 ~184KB 源码 + ~16KB 注入代码通过 StringBuilder 拼接。这是一次性开销，仅在 `[RELOAD] #31` 时发生。

**评估**: 不需要优化。Godot 编译 200KB 的 GDScript 是毫秒级的，且只发生一次。

---

### P3-2: 胜率统计使用多次 `Count()` 遍历

**文件**: `HistoryViewModel.cs` 第 347-367 行

```csharp
int totalWins = all.Count(r => r.EndedBy == "victory");
var recent = all.Take(200).ToList();
WinRate50 = recent.Take(50).Count(r => r.EndedBy == "victory") ...
```

**问题**: 每次收到 run_list 时遍历多次。129 runs 下完全无感知。

**评估**: 不需要优化。O(n) with n=129，在 <1ms 内完成。

---

### P3-3: SpinCellViewModel 的 TooltipActions + TooltipText 双重构建

**文件**: `HistoryViewModel.cs` 第 545-621 行

**问题**: 每个 spin cell 同时构建 `TooltipActions`（富文本，含图标）和 `TooltipText`（纯文本 fallback）。大部分 cell 的 tooltip 从未被用户看到。

**评估**: 延迟到 ToolTip 实际打开时构建即可节省大量 ViewModel 构造时间。但属于 UX 微优化，当前用户量下不紧急。

---

## 修复优先级路线图

```
Phase 1 (上线前):
├── P0-1: O(n²) 合并循环 → Dictionary lookup
├── P0-2: _bh_debug_log 生产环境禁用
├── P0-3: _bh_fmt_time 用 % 格式化
├── P1-1: JSON.print 去缩进
└── P1-3: _bh_fmt_time 格式化优化（和 P0-3 一起做）

Phase 2 (上线后第一周):
├── P1-2: BuildRunListJson 信任 manifest
├── P1-4: RebuildManifest 增量更新
├── P2-1: _bh_spin_count 计数器
└── P2-2: _bh_events.remove → rebuild array

Phase 3 (上线后优化):
├── P2-3: TimelineRounds 延迟构建 Tooltip
├── P2-4: 图标 BitmapImage 缓存
└── P3-*: 按需处理
```

---

## 性能基准建议

在上线前建议收集以下指标的 baseline：

| 指标 | 测量方式 | 预期值 |
|------|----------|--------|
| `_bh_flush()` 耗时 | `_bh_debug_log` 中加 `OS.get_ticks_msec()` 差值 | <10ms |
| `_bh_add_event()` 单次耗时 | 同上 | <0.1ms |
| WPF run_list 加载 | `StatusText` 更新时间 | <200ms (100 runs) |
| 启动时 manifest 重建 | Mod.cs 日志 | <500ms (120 runs) |
| 单局 JSON 文件大小 | 文件系统 | <50KB compact (当前 ~70KB) |
