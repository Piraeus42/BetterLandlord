# Guillotine 截断 Bug — 完整实施方案

基于"非破坏性 flush + 去抖"架构的逐文件修改计划。
改动范围: 4 个文件, ~40 行净变化。

---

## 改动概览

```
MainScriptSourceMod.cs      核心状态机重写 (变量 + 4 函数)
GuillotineEndPatch.cs       移除 latch guard (1 行)
TitlePatch.cs               移除 latch guard + 简化 (3 行)
TitleSetFloorPatch.cs       移除 latch guard (1 行)
RngInfrastructureSourceMod.cs  移除 latch guard + cold-boot 恢复 (2 处)
WriteLogPatch.cs            无需改动
ResolveEventPatch.cs        无需改动
SaveGamePatch.cs            无需改动
ContinueGamePatch.cs        无需改动
```

---

## 文件 1: MainScriptSourceMod.cs

### 改动 1.1 — 变量声明 (第 26-31 行)

**旧:**
```gdscript
var _bh_events = []
var _bh_run_id = ''
var _bh_run_ended = false
var _bh_pending_choice = {}
var _bh_just_recorded_item = ''
var _bh_choice_idx = 0
```

**新:**
```gdscript
var _bh_events = []
var _bh_run_id = ''
var _bh_flushed_at_spin = -1
var _bh_victory_achieved = false
var _bh_pending_choice = {}
var _bh_just_recorded_item = ''
var _bh_choice_idx = 0
```

**理由**: `_bh_run_ended` 被拆分为两个正交变量:
- `_bh_flushed_at_spin`: 去抖标记 — "上次 flush 时的 spin 计数"，-1 表示从未 flush
- `_bh_victory_achieved`: 语义标记 — "此 run 是否达成过 victory"

---

### 改动 1.2 — `_bh_init()` (第 45-50 行)

**旧:**
```gdscript
func _bh_init():
    _bh_events.clear()
    _bh_run_id = str(OS.get_unix_time())
    _bh_run_ended = false
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
```

**新:**
```gdscript
func _bh_init():
    _bh_events.clear()
    _bh_run_id = str(OS.get_unix_time())
    _bh_flushed_at_spin = -1
    _bh_victory_achieved = false
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
```

---

### 改动 1.3 — `_bh_start_run()` (第 52-60 行)

**旧:**
```gdscript
func _bh_start_run():
    _bh_events.clear()
    _bh_run_ended = false
    # Always include run_number to prevent collisions across sessions.
    # Never reuse run_timestamp from a previous run.
    _bh_run_id = str(OS.get_unix_time())
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
    # RNG is NOT initialized here — that belongs to new_game / continue_game hooks.
```

**新:**
```gdscript
func _bh_start_run():
    _bh_events.clear()
    _bh_flushed_at_spin = -1
    _bh_victory_achieved = false
    # Always include run_number to prevent collisions across sessions.
    # Never reuse run_timestamp from a previous run.
    _bh_run_id = str(OS.get_unix_time())
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
    # RNG is NOT initialized here — that belongs to new_game / continue_game hooks.
```

**理由**: 这是**唯一**的 run 边界重置点（New Game 路径）。Continue 永远不经过这里。

---

### 改动 1.4 — 新增 `_bh_count_spins()` 辅助函数

**位置**: 插入在 `_bh_lookup_actual_rent` 之后 (第 634 行之后)

**新代码:**
```gdscript
# Count completed spins from _bh_events (spin_start events).
# Used as the debounce key — two flushes at the same spin count
# are duplicate notifications for the same game state.
func _bh_count_spins():
    var n = 0
    for _ev in _bh_events:
        if str(_ev.get('type', '')) == 'spin_start':
            n += 1
    return n
```

---

### 改动 1.5 — `_bh_flush()` 变量区 (第 117 行附近)

在 `_end_time` 声明后添加:

```gdscript
    var victory_achieved = false
```

完整上下文:
```gdscript
    var _start_time = ''
    var _end_time = ''
    var victory_achieved = false
```

---

### 改动 1.6 — `_bh_flush()` Phase 1 run_end 处理 (第 262-264 行)

**旧:**
```gdscript
        elif et == 'run_end':
            _end_time = str(ev.get('timestamp', ''))
            ended_by = str(pl.get('result', 'loss'))
            final_coins = float(pl.get('coins', final_coins))
```

**新:**
```gdscript
        elif et == 'run_end':
            _end_time = str(ev.get('timestamp', ''))
            ended_by = str(pl.get('result', 'loss'))
            victory_achieved = bool(pl.get('victory_achieved', false))
            final_coins = float(pl.get('coins', final_coins))
```

---

### 改动 1.7 — `_bh_flush()` Phase 2 最终周期逻辑 (第 375-386 行)

**旧:**
```gdscript
        if ended_by == 'victory':
            cyc['rent_payment'] = {
                'paid_successfully': true,
                'coins_left_after_pay': max(0, float(last_sp.coins_after) - float(cyc.rent_required))
            }
        elif ended_by == 'loss':
            cyc['rent_payment'] = {
                'paid_successfully': false,
                'coins_left_after_pay': 0
            }
        else:
            cyc['rent_payment'] = null
```

**新:**
```gdscript
        if ended_by == 'victory' or victory_achieved:
            cyc['rent_payment'] = {
                'paid_successfully': true,
                'coins_left_after_pay': max(0, float(last_sp.coins_after) - float(cyc.rent_required))
            }
        elif ended_by == 'loss':
            cyc['rent_payment'] = {
                'paid_successfully': false,
                'coins_left_after_pay': 0
            }
        else:
            cyc['rent_payment'] = null
```

**理由**: 如果 run 曾经 victory（即使最终因 guillotine/quit 重新 flush），最终周期的 rent 仍应标记为已支付。

---

### 改动 1.8 — `_bh_flush()` Phase 3 meta (第 413-424 行)

**旧:**
```gdscript
    var meta = {
        'run_number': end_run_number if end_run_number > 0 else run_number,
        'start_time': _start_time,
        'end_time': _end_time,
        'ended_by': ended_by,
        'final_coins': final_coins,
        'total_spins': total_spins,
        'floor': floor_num,
        'seed_type': seed_type,
        'seed_input': seed_input,
        'landlord_seed': landlord_seed
    }
```

**新:**
```gdscript
    var meta = {
        'run_number': end_run_number if end_run_number > 0 else run_number,
        'start_time': _start_time,
        'end_time': _end_time,
        'ended_by': ended_by,
        'victory_achieved': victory_achieved,
        'final_coins': final_coins,
        'total_spins': total_spins,
        'floor': floor_num,
        'seed_type': seed_type,
        'seed_input': seed_input,
        'landlord_seed': landlord_seed
    }
```

---

### 改动 1.9 — `_bh_flush()` Phase 5 (第 558 行)

**旧:**
```gdscript
    f.store_string(JSON.print(record, '  '))
    f.close()
    _bh_debug_log('phase5_done json_written')
    _bh_events.clear()
    # Clean up temp events dump — run is complete, no need for recovery file
    var _d2 = Directory.new()
    var _tmp_path = 'user://betterHistory/events_' + _bh_run_id + '.json'
    if _d2.file_exists(_tmp_path):
        _d2.remove(_tmp_path)
```

**新:**
```gdscript
    f.store_string(JSON.print(record, '  '))
    f.close()
    _bh_debug_log('phase5_done json_written')
    # Events persist in memory — flush is non-destructive.
    # Clean up is now the responsibility of _bh_start_run() (New Game boundary).
    # Temp events dump is no longer removed at flush time; it stays as
    # cold-boot recovery data alongside the complete JSON.
```

**理由**: 
1. **删除 `_bh_events.clear()`** — 这是核心改动。flush 不再清空事件缓冲，后续 flush 可以重建完整记录。
2. **删除 temp dump 清理** — sidecar 现在包含完整 run 历史（因为 events 不清空），保留它支持 cold-boot 恢复。

---

### 改动 1.10 — `_bh_end_run()` (第 683-794 行) — 重写

**旧:**
```gdscript
func _bh_end_run(result):
    if _bh_run_ended:
        return
    # Don't flush ghost runs — a real game needs spin_start/spin_end events.
    # run_start + startup popups can accumulate 2-3 events without any spins.
    # Check for actual spin activity rather than a fixed event count.
    var _has_spins = false
    for _ev in _bh_events:
        if str(_ev.get('type', '')) == 'spin_start':
            _has_spins = true
            break
    if not _has_spins:
        _bh_events.clear()
        _bh_run_ended = true
        return
    _bh_run_ended = true
    _bh_debug_log('endrun_start result=' + result)

    var fs = []
    var fi = []
    if typeof($'Reels') != TYPE_NIL:
        _bh_debug_log('endrun_reading_reels')
        for r in $'Reels'.reels:
            for i in r.icons:
                if i.type != 'empty' and i.type != 'dud':
                    var iv = 0
                    if typeof(i.value) == TYPE_REAL:
                        iv = int(i.value)
                    var sv = 0
                    if typeof(i.saved_value) == TYPE_INT or typeof(i.saved_value) == TYPE_REAL:
                        sv = int(i.saved_value)
                    var ic = 0
                    if typeof(i.item_count) == TYPE_INT or typeof(i.item_count) == TYPE_REAL:
                        ic = int(i.item_count)
                    var entry = {'id': str(i.type), 'value': iv, 'saved_value': sv}
                    if ic > 0:
                        entry['item_count'] = ic
                    # Badge data is now captured in board_value events
                    # (at _bh_end_run time the board is already cleared)
                    fs.append(entry)
    if typeof($'Items') != TYPE_NIL:
        for it in $'Items'.items:
            var itv = 0
            if typeof(it.value) == TYPE_REAL:
                itv = int(it.value)
            # Item has BOTH item_count and saved_value
            var ic = 0
            var has_ic = false
            if typeof(it.item_count) == TYPE_INT or typeof(it.item_count) == TYPE_REAL:
                ic = int(it.item_count)
                has_ic = true
            var sv = 0
            var has_sv = false
            if typeof(it.saved_value) == TYPE_INT or typeof(it.saved_value) == TYPE_REAL:
                sv = int(it.saved_value)
                has_sv = true
            var entry = {'id': str(it.type), 'value': itv}
            if has_ic: entry['item_count'] = ic
            if has_sv: entry['saved_value'] = sv
            fi.append(entry)
    var fl = 0
    if typeof($'Pop-up Sprite/Pop-up') != TYPE_NIL:
        fl = $'Pop-up Sprite/Pop-up'.current_floor
    var cc = 0
    if typeof($'Coins') != TYPE_NIL:
        cc = $'Coins'.coins
    # Read actual run_number from game at end time (not start, when save may not be loaded)
    var _actual_rn = 0
    if typeof($'Pop-up Sprite/Pop-up') != TYPE_NIL:
        _actual_rn = $'Pop-up Sprite/Pop-up'.total_runs
    var _ds = []
    var _di = []
    var _rs = []
    if typeof($'Pop-up Sprite/Pop-up') != TYPE_NIL:
        var _popup = $'Pop-up Sprite/Pop-up'
        # destroyed_symbol_types accumulates globally across the run (SlotIcon pushes on destroy)
        if _popup.has('destroyed_symbol_types'):
            var _ds_counts = {}
            for _s in _popup.destroyed_symbol_types:
                var _sk = str(_s)
                _ds_counts[_sk] = _ds_counts.get(_sk, 0) + 1
            for _k in _ds_counts.keys():
                _ds.append({'id': _k, 'count': _ds_counts[_k]})
        # removed_symbol_types accumulates globally across the run
        if _popup.has('removed_symbol_types'):
            var _rs_counts = {}
            for _s in _popup.removed_symbol_types:
                var _sk = str(_s)
                _rs_counts[_sk] = _rs_counts.get(_sk, 0) + 1
            for _k in _rs_counts.keys():
                _rs.append({'id': _k, 'count': _rs_counts[_k]})
    # destroyed_item_types lives on $/root/Main/Items, not Pop-up
    if typeof($'/root/Main/Items') != TYPE_NIL:
        var _items_node = $'/root/Main/Items'
        if _items_node.has('destroyed_item_types'):
            var _di_counts = {}
            for _s in _items_node.destroyed_item_types:
                var _sk = str(_s)
                _di_counts[_sk] = _di_counts.get(_sk, 0) + 1
            for _k in _di_counts.keys():
                _di.append({'id': _k, 'count': _di_counts[_k]})
    _bh_debug_log('endrun_before_flush')
    _bh_add_event('run_end', {
        'result': result, 'floor': fl, 'coins': cc,
        'final_symbols': fs, 'final_items': fi,
        'destroyed_symbols': _ds, 'destroyed_items': _di, 'removed_symbols': _rs,
        'run_number': _actual_rn,
        'seed_type': _bh_rng_seed_type,
        'seed_input': _bh_rng_seed_input,
        'landlord_seed': _bh_rng_landlord_seed
    })
    _bh_flush()
```

**新:**
```gdscript
func _bh_end_run(result):
    # --- Ghost-run filter (unchanged logic) ---
    var spins = _bh_count_spins()
    if spins == 0:
        _bh_events.clear()
        _bh_flushed_at_spin = -1
        return

    # --- Debounce: skip duplicate notifications for the same game state ---
    # Both write_log("VICTORY") and resolve_event("win") fire for the same
    # victory.  The second one arrives with no new spin data — skip it.
    if spins == _bh_flushed_at_spin:
        return

    # --- Track victory achievement ---
    # Once a run has won, record it permanently so re-flushes after
    # guillotine / coin-loss / quit still carry victory_achieved=true.
    if result == 'victory':
        _bh_victory_achieved = true

    # --- Strip any stale run_end events ---
    # A previous flush may have appended a run_end.  Remove all of them
    # so exactly one exists, at the tail, for this flush.  While stripping,
    # preserve victory_achieved knowledge from any prior run_end.
    var _i = _bh_events.size() - 1
    while _i >= 0:
        var _ev = _bh_events[_i]
        if str(_ev.get('type', '')) == 'run_end':
            if str(_ev.get('payload', {}).get('result', '')) == 'victory':
                _bh_victory_achieved = true
            _bh_events.remove(_i)
        _i -= 1

    _bh_debug_log('endrun_start result=' + result)

    # --- Capture final board state ---
    var fs = []
    var fi = []
    if typeof($'Reels') != TYPE_NIL:
        _bh_debug_log('endrun_reading_reels')
        for r in $'Reels'.reels:
            for i in r.icons:
                if i.type != 'empty' and i.type != 'dud':
                    var iv = 0
                    if typeof(i.value) == TYPE_REAL:
                        iv = int(i.value)
                    var sv = 0
                    if typeof(i.saved_value) == TYPE_INT or typeof(i.saved_value) == TYPE_REAL:
                        sv = int(i.saved_value)
                    var ic = 0
                    if typeof(i.item_count) == TYPE_INT or typeof(i.item_count) == TYPE_REAL:
                        ic = int(i.item_count)
                    var entry = {'id': str(i.type), 'value': iv, 'saved_value': sv}
                    if ic > 0:
                        entry['item_count'] = ic
                    fs.append(entry)
    if typeof($'Items') != TYPE_NIL:
        for it in $'Items'.items:
            var itv = 0
            if typeof(it.value) == TYPE_REAL:
                itv = int(it.value)
            var ic = 0
            var has_ic = false
            if typeof(it.item_count) == TYPE_INT or typeof(it.item_count) == TYPE_REAL:
                ic = int(it.item_count)
                has_ic = true
            var sv = 0
            var has_sv = false
            if typeof(it.saved_value) == TYPE_INT or typeof(it.saved_value) == TYPE_REAL:
                sv = int(it.saved_value)
                has_sv = true
            var entry = {'id': str(it.type), 'value': itv}
            if has_ic: entry['item_count'] = ic
            if has_sv: entry['saved_value'] = sv
            fi.append(entry)
    var fl = 0
    if typeof($'Pop-up Sprite/Pop-up') != TYPE_NIL:
        fl = $'Pop-up Sprite/Pop-up'.current_floor
    var cc = 0
    if typeof($'Coins') != TYPE_NIL:
        cc = $'Coins'.coins
    var _actual_rn = 0
    if typeof($'Pop-up Sprite/Pop-up') != TYPE_NIL:
        _actual_rn = $'Pop-up Sprite/Pop-up'.total_runs
    var _ds = []
    var _di = []
    var _rs = []
    if typeof($'Pop-up Sprite/Pop-up') != TYPE_NIL:
        var _popup = $'Pop-up Sprite/Pop-up'
        if _popup.has('destroyed_symbol_types'):
            var _ds_counts = {}
            for _s in _popup.destroyed_symbol_types:
                var _sk = str(_s)
                _ds_counts[_sk] = _ds_counts.get(_sk, 0) + 1
            for _k in _ds_counts.keys():
                _ds.append({'id': _k, 'count': _ds_counts[_k]})
        if _popup.has('removed_symbol_types'):
            var _rs_counts = {}
            for _s in _popup.removed_symbol_types:
                var _sk = str(_s)
                _rs_counts[_sk] = _rs_counts.get(_sk, 0) + 1
            for _k in _rs_counts.keys():
                _rs.append({'id': _k, 'count': _rs_counts[_k]})
    if typeof($'/root/Main/Items') != TYPE_NIL:
        var _items_node = $'/root/Main/Items'
        if _items_node.has('destroyed_item_types'):
            var _di_counts = {}
            for _s in _items_node.destroyed_item_types:
                var _sk = str(_s)
                _di_counts[_sk] = _di_counts.get(_sk, 0) + 1
            for _k in _di_counts.keys():
                _di.append({'id': _k, 'count': _di_counts[_k]})
    _bh_debug_log('endrun_before_flush')
    _bh_add_event('run_end', {
        'result': result,
        'victory_achieved': _bh_victory_achieved,
        'floor': fl, 'coins': cc,
        'final_symbols': fs, 'final_items': fi,
        'destroyed_symbols': _ds, 'destroyed_items': _di, 'removed_symbols': _rs,
        'run_number': _actual_rn,
        'seed_type': _bh_rng_seed_type,
        'seed_input': _bh_rng_seed_input,
        'landlord_seed': _bh_rng_landlord_seed
    })
    _bh_flush()
    _bh_flushed_at_spin = spins
```

**关键改动总结:**
1. 移除 `if _bh_run_ended: return` — 替换为 spin-count 去抖
2. 移除 `_bh_run_ended = true` — 不再需要
3. 新增 stale `run_end` 清理循环 — 保证事件数组中只有一个 run_end
4. 新增 `victory_achieved` 追踪 — 在清理 stale run_end 时检测旧 victory
5. `run_end` payload 新增 `victory_achieved` 字段
6. flush 后设置 `_bh_flushed_at_spin = spins` — 这是新的"上次 flush 点"

---

## 文件 2: GuillotineEndPatch.cs

### 改动 2.1 — 移除 latch guard (第 19-21 行)

**旧:**
```csharp
[Prefix]
static string PrefixCode() => GdscriptUtil.TabifyIndent("""
    # Guillotine death: flush events at animation start (anim just set to 600).
    # Direct variable access — `get()` does not work for injected script vars in Godot 3.x.
    if guillotine_essence_anim == 600 and has_method("_bh_end_run"):
        if _bh_events != null and _bh_events.size() > 1 and not _bh_run_ended:
            _bh_end_run("victory")
    """);
```

**新:**
```csharp
[Prefix]
static string PrefixCode() => GdscriptUtil.TabifyIndent("""
    # Guillotine death: flush events at animation start (anim just set to 600).
    # Direct variable access — `get()` does not work for injected script vars in Godot 3.x.
    # _bh_end_run is re-entrant and debounced — safe to call unconditionally.
    if guillotine_essence_anim == 600 and has_method("_bh_end_run"):
        if _bh_events != null and _bh_events.size() > 1:
            _bh_end_run("victory")
    """);
```

**改动**: 删除 `and not _bh_run_ended` + 更新注释。

---

## 文件 3: TitlePatch.cs

### 改动 3.1 — 移除 latch guard + 简化 (第 17-26 行)

**旧:**
```csharp
/// <summary>
/// Snapshot flush: when returning to title mid-run, write the current events
/// to JSON (so WPF history refreshes as "Quit"), but preserve events in memory
/// and on disk so Continue (warm or cold) picks up seamlessly.
///
/// _bh_flush() deletes the temp events file as part of its cleanup.  We
/// re-dump it immediately after restoring memory so cold-boot Continue
/// still has recovery data.
/// </summary>
[Patch("res://Main.tscn::1", "title")]
class TitlePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_flush") and has_method("_bh_dump_raw_events"):
            if _bh_events.size() > 0 and not _bh_run_ended:
                var _saved = _bh_events.duplicate(true)
                _bh_flush()
                _bh_events = _saved
                _bh_dump_raw_events()
                _bh_run_ended = false
        """);
}
```

**新:**
```csharp
/// <summary>
/// Snapshot flush: when returning to title mid-run, write the current events
/// to JSON (so WPF history refreshes as "Quit"), then dump to sidecar for
/// cold-boot Continue recovery.
///
/// _bh_flush() is now non-destructive — events remain in memory, so the
/// old save/restore dance is unnecessary.  Any later ending (guillotine,
/// coin-loss, Force-Close) re-flushes the full buffer in place.
/// </summary>
[Patch("res://Main.tscn::1", "title")]
class TitlePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_flush") and has_method("_bh_dump_raw_events"):
            if _bh_events.size() > 0:
                _bh_flush()
                _bh_dump_raw_events()
        """);
}
```

**改动**:
1. 删除 `and not _bh_run_ended` guard
2. 删除 `var _saved = ...` / `_bh_events = _saved` 存取/恢复舞蹈（flush 不再清空，无此必要）
3. 删除 `_bh_run_ended = false`
4. 更新注释

---

## 文件 4: TitleSetFloorPatch.cs

### 改动 4.1 — 移除 latch guard (第 16-32 行)

**旧:**
```csharp
[Prefix]
static string PrefixCode() => GdscriptUtil.TabifyIndent("""
    if has_method("_bh_end_run") and has_method("_bh_start_run") and has_method("_bh_apply_seed"):
        # new_game() is called twice: once on button click (floor not selected →
        # shows floor menu), once after floor selection (actually starts game).
        # Only flush+init on the second call when a run is really about to begin.
        if $'Pop-up Sprite/Pop-up'.floor_selected or demo:
            # Flush any dangling events from a previous saved game
            if _bh_events.size() > 0 and not _bh_run_ended:
                _bh_end_run("quit")
            # Fresh bookkeeping for the new run
            _bh_start_run()
            # Apply seed from UI / config
            _bh_apply_seed()
            _bh_add_event("run_start", {
                "run_number": $'Pop-up Sprite/Pop-up'.total_runs,
                "version": version_str
            })
    """);
```

**新:**
```csharp
[Prefix]
static string PrefixCode() => GdscriptUtil.TabifyIndent("""
    if has_method("_bh_end_run") and has_method("_bh_start_run") and has_method("_bh_apply_seed"):
        # new_game() is called twice: once on button click (floor not selected →
        # shows floor menu), once after floor selection (actually starts game).
        # Only flush+init on the second call when a run is really about to begin.
        if $'Pop-up Sprite/Pop-up'.floor_selected or demo:
            # Flush any dangling events from a previous run.
            # _bh_end_run is debounced — safe to call even if already flushed.
            if _bh_events.size() > 0:
                _bh_end_run("quit")
            # Fresh bookkeeping for the new run
            _bh_start_run()
            # Apply seed from UI / config
            _bh_apply_seed()
            _bh_add_event("run_start", {
                "run_number": $'Pop-up Sprite/Pop-up'.total_runs,
                "version": version_str
            })
    """);
```

**改动**: 删除 `and not _bh_run_ended` + 更新注释。

---

## 文件 5: RngInfrastructureSourceMod.cs

### 改动 5.1 — `_notification(1006)` (第 393-396 行)

**旧:**
```gdscript
# Called by Godot when the window is closed mid-run.
# NOTIFICATION_WM_QUIT_REQUEST = 1006
func _notification(what: int):
    if what == 1006:
        if _bh_events.size() > 0 and not _bh_run_ended:
            _bh_end_run("quit")
```

**新:**
```gdscript
# Called by Godot when the window is closed mid-run.
# NOTIFICATION_WM_QUIT_REQUEST = 1006
# _bh_end_run is re-entrant and debounced — safe to call unconditionally.
func _notification(what: int):
    if what == 1006:
        if _bh_events.size() > 0:
            _bh_end_run("quit")
```

---

### 改动 5.2 — `_bh_restore_rng_state()` cold-boot 恢复 (第 333-336 行)

**旧:**
```gdscript
    # Load pre-close events from temp dump, truncated to save point
    if has_method("_bh_load_events_for_continue"):
        var _save_spins = int(fp.get("spins", 0))
        _bh_load_events_for_continue(_save_spins)
```

**新:**
```gdscript
    # Load pre-close events from temp dump, truncated to save point
    if has_method("_bh_load_events_for_continue"):
        var _save_spins = int(fp.get("spins", 0))
        _bh_load_events_for_continue(_save_spins)
        # Force the next ending to flush — sidecar may contain events
        # from a run that was already flushed once.
        _bh_flushed_at_spin = -1
```

**理由**: 冷启动 Continue 后，events 从 sidecar 恢复，但 `_bh_flushed_at_spin` 是进程内变量（由 `_bh_init()` 设为 -1）。显式 reset 到 -1 确保即使有其他初始化路径干扰，下一个 ending 一定会 flush。

---

## 不改动的文件（验证）

| 文件 | 原因 |
|------|------|
| `WriteLogPatch.cs` | `_bh_end_run("victory"/"loss")` 调用点不变；去抖在 callee 内部 |
| `ResolveEventPatch.cs` | 同上；去抖自动处理 WriteLog 重复通知 |
| `SaveGamePatch.cs` | `_bh_dump_raw_events()` 现在 dump 完整 buffer（非破坏性 flush），自然包含全部 events |
| `ContinueGamePatch.cs` | 调用 `_bh_restore_rng_state()`，改动在 callee 内部 |
| `ReadyPatch.cs` | `_bh_init()` 签名不变 |
| `SpinPatch.cs` | `_bh_add_event()` 无守卫，无需改动 |
| `BoardValuePatch.cs` | 同上 |
| `RentUpdatePatch.cs` | 同上 |

---

## 测试验证清单

对应分析报告 §9 的每一条:

| # | 场景 | 预期 | 验证点 |
|---|------|------|--------|
| 1 | 正常 Victory，不继续 | 单次 flush，去抖跳过 ResolveEvent 重复 | `_bh_flushed_at_spin` 从 -1 变为 spin_count；第二次调用被 `spins == _bh_flushed_at_spin` 拦截 |
| 2 | Victory → 继续 → Guillotine | 第一次 flush at 108 spins；第二次 flush at 349 spins 覆盖 | JSON 包含全部 349 spin，`ended_by`="victory"，`victory_achieved`=true |
| 3 | Victory → 继续 → 金币归零 | flush at victory point，re-flush at loss point | JSON 包含全部数据，`ended_by`="loss"，`victory_achieved`=true |
| 4 | Victory → 继续 → 手动回 Title | TitlePatch flush → 完整 JSON | events 保留在内存，可继续 |
| 5 | Victory → 继续 → Alt+F4 | `_notification(1006)` → `_bh_end_run("quit")` | sidecar dump 包含全部 events |
| 6 | Cold-boot Continue (victory 后) | sidecar 恢复 events，`_bh_flushed_at_spin=-1`，下一 ending flush | 完整 JSON |
| 7 | Mid-run 回 Title → Continue | TitlePatch flush，events 保留，Continue 无缝衔接 | 同现有行为，更简洁 |
| 8 | 正常 Loss (不继续) | 同场景 1 | 去抖正常 |
| 9 | Ghost run (无 spin) | `_bh_count_spins()==0` → 清空并返回 | 不写 JSON |
| 10 | 两次连续 flush 同 spin count | 第二次被 `spins == _bh_flushed_at_spin` 拦截 | 不重复写文件 |

---

## 风险评估

| 风险 | 概率 | 缓解 |
|------|------|------|
| events 内存增长 | 确定（设计如此） | 350-spin run ≈ 少量 MB；可在 `_bh_start_run` 之外的 GC 点添加 cap（后续优化） |
| `_bh_count_spins()` O(n) 扫描 | 低影响 | 仅在 ending 时调用（~每 run 1-3 次），事件数 ≤ 数千 |
| stale `run_end` 清理循环移除所有 run_end | 低 | 反向遍历 + `.remove(i)` 在 GDScript 中安全；每个 flip 最多 1-2 个 run_end |
| `victory_achieved` 在 cold-boot 后不正确 | 低 | stale run_end 清理循环会检测旧 victory；+ 显式检查 |
| `_bh_dump_raw_events` 不再清理 temp file | 设计如此 | temp file 在 `_bh_start_run` 间接清理（新 run_id → 新文件名）；可后续添加清理 |

---

## 语义变更: ended_by vs victory_achieved

**当前行为**: `ended_by` 只能是 "victory" / "loss" / "quit"，胜利后继续的记录丢失。

**新行为**:
- 正常 Victory: `ended_by="victory"`, `victory_achieved=true`
- Victory→Guillotine: `ended_by="victory"`, `victory_achieved=true`（GuillotineEndPatch 传 "victory"）
- Victory→Coin loss: `ended_by="loss"`, `victory_achieved=true`
- Victory→Title: `ended_by="quit"`, `victory_achieved=true`

如果后续希望区分 "victory" 和 "guillotine" 作为 ended_by，只需修改 GuillotineEndPatch 传递的参数（如 `_bh_end_run("guillotine")`），`_bh_flush` 的 Phase 2 逻辑通过 `victory_achieved` 正确处理 rent_payment。
