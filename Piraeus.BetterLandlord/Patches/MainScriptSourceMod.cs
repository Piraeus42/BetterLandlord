using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Single ISourceMod that injects event-capture helpers into Main.tscn::1.
/// History viewer UI now lives in TitleHistoryMenuSourceMod (Main.tscn::6).
/// </summary>
public class MainScriptSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::1";

    public string Modify(string path, string source)
    {
var sb = new System.Text.StringBuilder(source);
        sb.Append('\n');
        sb.Append(GdscriptUtil.Tabify(EventCaptureHelpers));
        sb.Append('\n');
        return sb.ToString();
    }

    private const string EventCaptureHelpers = @"

# ---- BetterHistoryMod event capture helpers (auto-generated) ----

var _bh_events = []
var _bh_run_id = ''
var _bh_flushed_at_spin = -1
var _bh_victory_achieved = false
var _bh_pending_choice = {}
var _bh_just_recorded_item = ''
var _bh_choice_idx = 0

# Clipboard monitor — samples every 0.5s to pinpoint when clipboard is cleared
var _bh_saved_clip = ''
var _bh_clip_timer = 0.0
func _bh_clip_sample():
    if not OS.is_debug_build():
        _bh_clip_timer = 0.0
        return
    _bh_clip_timer = 0.0
    var clip = OS.get_clipboard()
    var _prefix = 'clip_sample'
    var _len = 0
    if typeof(clip) == TYPE_STRING:
        _len = clip.length()
    _bh_debug_log(_prefix + ' len=' + str(_len) + ' t=' + str(OS.get_ticks_msec()))

func _bh_init():
    _bh_events.clear()
    _bh_run_id = str(OS.get_unix_time())
    _bh_flushed_at_spin = -1
    _bh_victory_achieved = false
    _bh_pending_choice.clear()
    _bh_choice_idx = 0

func _bh_start_run():
    # Clean up temp events file from the previous run before resetting run_id.
    # New Game is the one true run boundary — only here can we safely delete
    # recovery data for the old run without risk of needing it for Continue.
    if _bh_run_id != '':
        var _d2 = Directory.new()
        var _old_tmp = 'user://betterHistory/events_' + _bh_run_id + '.json'
        if _d2.file_exists(_old_tmp):
            _d2.remove(_old_tmp)
    _bh_events.clear()
    _bh_flushed_at_spin = -1
    _bh_victory_achieved = false
    # Always include run_number to prevent collisions across sessions.
    # Never reuse run_timestamp from a previous run.
    _bh_run_id = str(OS.get_unix_time())
    _bh_pending_choice.clear()
    _bh_choice_idx = 0
    # RNG is NOT initialized here — that belongs to new_game / continue_game hooks.

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

func _bh_debug_log(msg: String):
    if not OS.is_debug_build():
        return
    var _df = File.new()
    if _df.file_exists('user://betterHistory/debug.log'):
        _df.open('user://betterHistory/debug.log', File.READ_WRITE)
        _df.seek_end()
    else:
        _df.open('user://betterHistory/debug.log', File.WRITE)
    _df.store_string(str(OS.get_unix_time()) + ' ' + msg + '\n')
    _df.close()

func _bh_flush():
    _bh_debug_log('flush_start events=' + str(_bh_events.size()))
    if _bh_events.size() == 0:
        return

    # ============================================================
    # Phase 1: Build spin frames from events
    # ============================================================
    var all_spins = []
    var cur_spin = null
    var pending_additions = []
    var pending_skip_symbols = []
    var pending_skip_items = []
    var symbol_accum = {}
    var item_accum = {}
    var destroyed_item_accum = {}
    var destroyed_symbol_accum = {}
    var removed_symbol_accum = {}
    var des_sym = []
    var des_it = []
    var rem_sym = []
    # DPT accumulators: per-symbol value tracking
    var symbol_value_sum = {}      # {id: total_coins}
    var symbol_spin_count = {}     # {id: times_on_grid}
    var symbol_first_spin = {}     # {id: first_spin_num}
    var symbol_last_spin = {}      # {id: last_spin_num}
    var current_spin_num = 0       # tracked from spin_start
    var run_number = 0
    var end_run_number = 0
    var seed_type = ''
    var seed_input = ''
    var landlord_seed = 0
    var final_coins = 0
    var floor_num = 0
    var ended_by = 'loss'
    var f_symbols = []
    var f_items = []
    var _start_time = ''
    var _end_time = ''
    var victory_achieved = false

    for ev in _bh_events:
        var et = str(ev.get('type', ''))
        var pl = ev.get('payload', {})
        if typeof(pl) != TYPE_DICTIONARY:
            pl = {}

        if et == 'run_start':
            run_number = int(pl.get('run_number', 0))
            _start_time = str(ev.get('timestamp', ''))

        elif et == 'spin_start':
            # Finalize the PREVIOUS spin first, flushing pending choices into IT
            # (not the new spin). This implements spin→choice model:
            # choice made after spin N belongs to spin N, takes effect in spin N+1.
            if cur_spin != null:
                if pending_additions.size() > 0:
                    var choice_idx = -1
                    for pi in range(pending_additions.size()):
                        var pa = pending_additions[pi]
                        if str(pa.get('source', '')) == 'choice' and str(pa.get('type', '')) == 'symbol':
                            cur_spin.main_symbol = str(pa.get('id', ''))
                            choice_idx = pi
                            break
                    for pi in range(pending_additions.size()):
                        if pi == choice_idx:
                            continue
                        cur_spin.extra_actions.append(pending_additions[pi])
                    pending_additions.clear()
                if pending_skip_symbols.size() > 0:
                    for sk in pending_skip_symbols:
                        cur_spin.skipped_options.append(str(sk))
                    pending_skip_symbols.clear()
                if pending_skip_items.size() > 0:
                    for si in pending_skip_items:
                        cur_spin.skipped_options.append(str(si))
                    pending_skip_items.clear()
                all_spins.append(cur_spin)
            cur_spin = {
                'spin_num': int(pl.get('spin_num', 0)),
                'coins_before': float(pl.get('coins', 0)),
                'coins_after': 0,
                'coin_change': 0,
                'main_symbol': null,
                'skipped_options': [],
                'extra_actions': []
            }

        elif et == 'spin_end':
            if cur_spin != null:
                cur_spin.coins_after = float(pl.get('coin_total', 0))
                cur_spin.coin_change = cur_spin.coins_after - cur_spin.coins_before
                final_coins = cur_spin.coins_after

        elif et == 'board_value':
            var _sn = int(pl.get('spin_num', 0))
            current_spin_num = _sn
            var _vals = pl.get('values', [])
            if typeof(_vals) == TYPE_ARRAY:
                for _v in _vals:
                    if typeof(_v) == TYPE_DICTIONARY:
                        var _vid = str(_v.get('id', ''))
                        var _vv = int(_v.get('value', 0))
                        if _vid != '' and _vid != 'null':
                            symbol_value_sum[_vid] = symbol_value_sum.get(_vid, 0) + _vv
                            symbol_spin_count[_vid] = symbol_spin_count.get(_vid, 0) + 1
                            if not symbol_first_spin.has(_vid) or _sn < symbol_first_spin[_vid]:
                                symbol_first_spin[_vid] = _sn
                            symbol_last_spin[_vid] = _sn
                            # Badge data: use the game's already-rendered display strings.
                            # update_value_text() ran before us -- strings are already formatted.
                            # Use all badge channels so permanent-bonus variants stay distinct.
                            var _bt = str(_v.get('badge_text', ''))
                            var _bm = str(_v.get('badge_mult', ''))
                            var _bb = str(_v.get('badge_bonus', ''))
        elif et == 'symbol_added':
            var s = str(pl.get('symbol', ''))
            var src = str(pl.get('source', 'choice'))
            if s != '' and s != 'null':
                pending_additions.append({'action': 'added', 'type': 'symbol', 'id': s, 'source': src})
                var c = symbol_accum.get(s, 0)
                symbol_accum[s] = c + 1
            # Also collect skipped options from the same event
            var _sk = pl.get('skipped', [])
            if typeof(_sk) == TYPE_ARRAY and _sk.size() > 0:
                for _sk_name in _sk:
                    if str(_sk_name) != '' and str(_sk_name) != 'null':
                        pending_skip_symbols.append(str(_sk_name))

        elif et == 'symbol_chosen':
            var skipped = pl.get('skipped', [])
            if typeof(skipped) == TYPE_ARRAY:
                for sk in skipped:
                    if str(sk) != '' and str(sk) != 'null':
                        pending_skip_symbols.append(str(sk))

        elif et == 'item_added':
            var it = str(pl.get('item', ''))
            var src = str(pl.get('source', 'choice'))
            var _ci = int(pl.get('choice_idx', 0))
            if it != '' and it != 'null':
                pending_additions.append({'action': 'added', 'type': 'item', 'id': it, 'source': src, 'choice_idx': _ci})
                var c = item_accum.get(it, 0)
                item_accum[it] = c + 1
            var _isk = pl.get('skipped', [])
            if typeof(_isk) == TYPE_ARRAY:
                for _isk_name in _isk:
                    if str(_isk_name) != '' and str(_isk_name) != 'null':
                        pending_additions.append({'action': 'skipped', 'type': 'item', 'id': str(_isk_name), 'choice_idx': _ci})

        elif et == 'item_chosen':
            var skipped = pl.get('skipped', [])
            if typeof(skipped) == TYPE_ARRAY:
                for sk in skipped:
                    if str(sk) != '' and str(sk) != 'null':
                        pending_skip_items.append(str(sk))

        elif et == 'item_destroyed':
            var it = str(pl.get('item', ''))
            if it != '':
                var c = destroyed_item_accum.get(it, 0)
                destroyed_item_accum[it] = c + 1
                var ic = item_accum.get(it, 0)
                if ic > 0:
                    item_accum[it] = ic - 1
                # Attach destroyed items to the current spin if active
                if cur_spin != null:
                    cur_spin.extra_actions.append({'action': 'destroyed', 'type': 'item', 'id': it})

        elif et == 'symbol_destroyed':
            var sd = str(pl.get('symbol', ''))
            if sd != '':
                var sc = destroyed_symbol_accum.get(sd, 0)
                destroyed_symbol_accum[sd] = sc + 1

        elif et == 'symbol_removed':
            var sr = str(pl.get('symbol', ''))
            var src = str(pl.get('source', ''))
            if sr != '' and src == 'removal_token':
                var rc = removed_symbol_accum.get(sr, 0)
                removed_symbol_accum[sr] = rc + 1

        elif et == 'run_end':
            _end_time = str(ev.get('timestamp', ''))
            ended_by = str(pl.get('result', 'loss'))
            victory_achieved = bool(pl.get('victory_achieved', false))
            final_coins = float(pl.get('coins', final_coins))
            floor_num = int(pl.get('floor', 0))
            f_symbols = pl.get('final_symbols', [])
            f_items = pl.get('final_items', [])
            end_run_number = int(pl.get('run_number', 0))
            seed_type = str(pl.get('seed_type', ''))
            seed_input = str(pl.get('seed_input', ''))
            landlord_seed = int(pl.get('landlord_seed', 0))
            var _raw_ds = pl.get('destroyed_symbols', [])
            if typeof(_raw_ds) == TYPE_ARRAY and _raw_ds.size() > 0:
                for _e in _raw_ds:
                    if typeof(_e) == TYPE_DICTIONARY:
                        var _d = {'id': str(_e.get('id', '')), 'count': int(_e.get('count', 1))}
                        des_sym.append(_d)
            var _raw_di = pl.get('destroyed_items', [])
            if typeof(_raw_di) == TYPE_ARRAY and _raw_di.size() > 0:
                for _e in _raw_di:
                    if typeof(_e) == TYPE_DICTIONARY:
                        var _d = {'id': str(_e.get('id', '')), 'count': int(_e.get('count', 1))}
                        des_it.append(_d)

    # Flush final spin
    if cur_spin != null:
        all_spins.append(cur_spin)
    # Flush remaining pending additions onto the last spin
    if pending_additions.size() > 0 and all_spins.size() > 0:
        var last = all_spins[all_spins.size() - 1]
        if last.main_symbol == null and str(pending_additions[0].get('action', '')) == 'added' and str(pending_additions[0].get('type', '')) == 'symbol':
            last.main_symbol = str(pending_additions[0].get('id', ''))
        var start_i = 0
        if last.main_symbol != null and pending_additions.size() > 0 and str(pending_additions[0].get('id', '')) == last.main_symbol:
            start_i = 1
        var i = start_i
        while i < pending_additions.size():
            last.extra_actions.append(pending_additions[i])
            i += 1
    # Flush remaining pending skips onto the last spin
    if pending_skip_symbols.size() > 0 and all_spins.size() > 0:
        var _ls = all_spins[all_spins.size() - 1]
        for _sn in pending_skip_symbols:
            _ls.skipped_options.append(str(_sn))
    if pending_skip_items.size() > 0 and all_spins.size() > 0:
        var _li = all_spins[all_spins.size() - 1]
        for _in in pending_skip_items:
            _li.skipped_options.append(str(_in))


    # spin_num=0 is now preserved (spin→choice model)
    _bh_debug_log('phase1_done spins=' + str(all_spins.size()))

    # ============================================================
    # Phase 1.5: Build actual rent lookup from rent_updated events
    # ============================================================
    var _bh_actual_rents = {}
    for ev in _bh_events:
        if str(ev.get('type', '')) == 'rent_updated':
            var pl = ev.get('payload', {})
            if typeof(pl) == TYPE_DICTIONARY:
                var idx = int(pl.get('times_rent_paid', -1))
                if idx >= 0:
                    _bh_actual_rents[idx] = int(pl.get('rent_0', 0))

    # ============================================================
    # Phase 2: Build rent_cycles from all_spins
    # ============================================================
    var base_round_cuts = [5, 10, 16, 22, 29, 36, 44, 52, 61, 70, 80, 90]
    var base_rents = [25, 50, 100, 150, 225, 300, 350, 425, 575, 625, 675, 777]
    var rent_cycles = []
    var round_idx = 0
    var cycle_spins = []

    for sp in all_spins:
        var sn = int(sp.spin_num)
        var cut = _bh_round_cut_v2(round_idx, base_round_cuts)
        # Cut check BEFORE appending: the spin that triggers rent payment
        # (popup.spins reaching the cut) has already had rent deducted from
        # its coins_before, so it belongs in the NEXT cycle.
        if sn > cut and cycle_spins.size() > 0:
            while sn > _bh_round_cut_v2(round_idx, base_round_cuts):
                round_idx += 1
            var cyc = {
                'cycle_index': round_idx,
                'rent_required': _bh_lookup_actual_rent(_bh_actual_rents, round_idx - 1, base_rents),
                'spins_in_cycle': cycle_spins.size(),
                'spins': cycle_spins
            }
            var last_sp = cycle_spins[cycle_spins.size() - 1]
            cyc['rent_payment'] = {
                'paid_successfully': true,
                'coins_left_after_pay': max(0, float(last_sp.coins_after) - float(cyc.rent_required))
            }
            rent_cycles.append(cyc)
            cycle_spins = []
        cycle_spins.append(sp)

    # Final (possibly incomplete) cycle
    if cycle_spins.size() > 0:
        var cyc = {
            'cycle_index': round_idx + 1,
            'rent_required': _bh_lookup_actual_rent(_bh_actual_rents, round_idx, base_rents),
            'spins_in_cycle': cycle_spins.size(),
            'spins': cycle_spins
        }
        var last_sp = cycle_spins[cycle_spins.size() - 1]
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
        rent_cycles.append(cyc)
    _bh_debug_log('phase2_done cycles=' + str(rent_cycles.size()))

    # ============================================================
    # Phase 2.5: Extract items (added + skipped) from spin extra_actions
    # into cycle end_actions.  Grouped by choice_idx for per-icon tooltips.
    # Destroyed items stay on the spin.
    # ============================================================
    for cyc in rent_cycles:
        var end_acts = []
        for sp in cyc.spins:
            var remaining = []
            for act in sp.extra_actions:
                var _act = str(act.get('action', ''))
                if (_act == 'added' or _act == 'skipped') and str(act.get('type', '')) == 'item':
                    end_acts.append(act)
                else:
                    remaining.append(act)
            sp.extra_actions = remaining
        cyc['end_actions'] = end_acts
    _bh_debug_log('phase25_done')

    # ============================================================
    # Phase 3: Build meta
    # ============================================================
    var total_spins = all_spins.size()
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
    _bh_debug_log('phase3_done')

    # ============================================================
    # Phase 4: Build summary from end-of-run board snapshot
    # f_symbols / f_items are the ACTUAL final board state captured
    # by _bh_end_run() directly from Reels + Items nodes.
    # ============================================================
    var sym_counts = {}      # {composite_key: count}
    var sym_badges = {}      # {composite_key: {item_count, saved_value, id}}
    for fs in f_symbols:
        if typeof(fs) == TYPE_DICTIONARY:
            var sid = str(fs.get('id', ''))
            if sid != '' and sid != 'null':
                # Badge data read directly from fs entry (populated by _bh_end_run from icon properties)
                var _bt = str(fs.get('badge_text', ''))
                var _bm = str(fs.get('badge_mult', ''))
                var _bb = str(fs.get('badge_bonus', ''))
                # Composite key: id + full badge tuple (different badges -> different entries)
                var skey = sid
                if _bt != '' or _bm != '' or _bb != '':
                    skey = sid + '|t=' + _bt + '|b=' + _bb + '|m=' + _bm
                sym_counts[skey] = sym_counts.get(skey, 0) + 1
                if not sym_badges.has(skey):
                    sym_badges[skey] = {'saved_value': 0, 'item_count': 0, 'id': sid, 'badge_text': _bt, 'badge_mult': _bm, 'badge_bonus': _bb}
                var sv = int(fs.get('saved_value', 0))
                if sv > sym_badges[skey].saved_value:
                    sym_badges[skey].saved_value = sv
                var ic2 = int(fs.get('item_count', 0))
                if ic2 > sym_badges[skey].item_count:
                    sym_badges[skey].item_count = ic2
    var sym_summary = []
    for skey in sym_counts.keys():
        if sym_counts[skey] > 0:
            var b = sym_badges.get(skey, {})
            var sid = str(b.get('id', skey))
            var entry = {'id': sid, 'count': sym_counts[skey]}
            if b.get('saved_value', 0) > 0:
                entry['saved_value'] = b.saved_value
            if b.get('item_count', 0) > 0:
                entry['item_count'] = b.item_count
            # Badge data: from sym_badges (populated from fs entries / icon properties)
            var _badge_text = str(b.get('badge_text', ''))
            var _badge_mult = str(b.get('badge_mult', ''))
            var _badge_bonus = str(b.get('badge_bonus', ''))
            if _badge_text != '': entry['badge_text'] = _badge_text
            if _badge_mult != '': entry['badge_mult'] = _badge_mult
            if _badge_bonus != '': entry['badge_bonus'] = _badge_bonus
            # DPT metrics (keyed by base symbol ID — merged across badge variants)
            var _tv = symbol_value_sum.get(sid, 0)
            var _sc = symbol_spin_count.get(sid, 0)
            var _fs = symbol_first_spin.get(sid, 0)
            var _ls = symbol_last_spin.get(sid, 0)
            var _tp = 0
            if _fs > 0 and _ls > 0:
                _tp = _ls - _fs + 1
            entry['total_value'] = _tv
            entry['turns_present'] = _tp
            entry['turns_contributing'] = _sc
            if _tp > 0:
                entry['dpt_actual'] = stepify(float(_tv) / float(_tp), 0.1)
            else:
                entry['dpt_actual'] = 0.0
            if _sc > 0:
                entry['dpt_effective'] = stepify(float(_tv) / float(_sc), 0.1)
            else:
                entry['dpt_effective'] = 0.0
            sym_summary.append(entry)

    var it_summary = []
    var seen_items = {}
    for fi in f_items:
        if typeof(fi) == TYPE_DICTIONARY:
            var iid = str(fi.get('id', ''))
            if iid != '' and iid != 'null' and not seen_items.has(iid):
                seen_items[iid] = true
                var ientry = {'id': iid}
                var ic = int(fi.get('item_count', 0))
                var sv = int(fi.get('saved_value', 0))
                if ic > 0:
                    ientry['item_count'] = ic
                if sv > 0:
                    ientry['saved_value'] = sv
                it_summary.append(ientry)

    # Merge destroyed_item_accum into des_it (avoid duplicates)
    for dk in destroyed_item_accum.keys():
        var _found = false
        for _di in des_it:
            if str(_di.get('id', '')) == str(dk):
                _di['count'] = int(_di.get('count', 0)) + int(destroyed_item_accum[dk])
                _found = true
                break
        if not _found:
            des_it.append({'id': str(dk), 'count': int(destroyed_item_accum[dk])})

    # Merge destroyed_symbol_accum into des_sym (mirrors destroyed_item_accum)
    for _sk in destroyed_symbol_accum.keys():
        var _found_s = false
        for _ds in des_sym:
            if str(_ds.get('id', '')) == str(_sk):
                _ds['count'] = int(_ds.get('count', 0)) + int(destroyed_symbol_accum[_sk])
                _found_s = true
                break
        if not _found_s:
            des_sym.append({'id': str(_sk), 'count': int(destroyed_symbol_accum[_sk])})

    # Merge removed_symbol_accum into rem_sym
    for _rk in removed_symbol_accum.keys():
        var _found_r = false
        for _rs in rem_sym:
            if str(_rs.get('id', '')) == str(_rk):
                _rs['count'] = int(_rs.get('count', 0)) + int(removed_symbol_accum[_rk])
                _found_r = true
                break
        if not _found_r:
            rem_sym.append({'id': str(_rk), 'count': int(removed_symbol_accum[_rk])})

    var summary = {
        'status_bar': null,
        'symbols': sym_summary,
        'items': it_summary,
        'destroyed_symbols': des_sym,
        'destroyed_items': des_it,
        'removed_symbols': rem_sym,
        'landlord_fine_print': []
    }
    _bh_debug_log('phase4_done symbols=' + str(sym_summary.size()))

    # ============================================================
    # Phase 5: Write JSON
    # ============================================================
    var record = {
        'history_version': '2.0',
        'run_id': _bh_run_id,
        'is_legacy_log': false,
        'meta': meta,
        'summary': summary,
        'rent_cycles': rent_cycles
    }

    var d = Directory.new()
    if not d.dir_exists('user://betterHistory'):
        d.make_dir('user://betterHistory')
    if not d.dir_exists('user://betterHistory/runs'):
        d.make_dir('user://betterHistory/runs')
    var f = File.new()
    f.open('user://betterHistory/runs/' + _bh_run_id + '.json', File.WRITE)
    f.store_string(JSON.print(record, '  '))
    f.close()
    _bh_debug_log('phase5_done json_written')
    # Events persist in memory — flush is non-destructive.
    # Clean-up is the responsibility of _bh_start_run() (the one true
    # run boundary, reached via New Game).

# ---- Incremental event persistence (cold-boot Continue recovery) ----

# Dump raw _bh_events to a temp file WITHOUT clearing the array.
# Called by SaveGamePatch so events survive a force-close.
func _bh_dump_raw_events():
    if _bh_events.size() == 0:
        return
    var d = Directory.new()
    if not d.dir_exists('user://betterHistory'):
        d.make_dir('user://betterHistory')
    var f = File.new()
    f.open('user://betterHistory/events_' + _bh_run_id + '.json', File.WRITE)
    f.store_string(JSON.print(_bh_events))
    f.close()

# Load events from temp file and truncate at the save point.
# save_spins comes from the sidecar's fingerprint — it's the Pop-up.spins
# value at the moment save_game() was called.
# Events with spin_num > save_spins belong to the post-save period and will
# be re-generated by the Continue session; they must be discarded to avoid
# duplicate spin entries in the final history.
func _bh_load_events_for_continue(save_spins):
    # Warm Continue — events are still in memory, no need to reload from disk
    if _bh_events.size() > 0:
        return
    var f = File.new()
    var path = 'user://betterHistory/events_' + _bh_run_id + '.json'
    if not f.file_exists(path):
        return
    if f.open(path, File.READ) != OK:
        return
    var text = f.get_as_text()
    f.close()
    var parsed = JSON.parse(text)
    if parsed.error != OK or typeof(parsed.result) != TYPE_ARRAY:
        return
    _bh_events.clear()
    var keep = true
    for ev in parsed.result:
        if typeof(ev) != TYPE_DICTIONARY:
            if keep: _bh_events.append(ev)
            continue
        # Check if this event is past the save point
        if keep:
            var pl = ev.get('payload', {})
            if typeof(pl) == TYPE_DICTIONARY:
                var sn = pl.get('spin_num', null)
                if sn != null and (typeof(sn) == TYPE_INT or typeof(sn) == TYPE_REAL):
                    if int(sn) > save_spins:
                        keep = false
                        continue
            _bh_events.append(ev)

func _bh_round_cut_v2(r_idx, base_cuts):
    if r_idx < 0:
        return 0
    if r_idx < base_cuts.size():
        return base_cuts[r_idx]
    return base_cuts[base_cuts.size() - 1] + (r_idx - base_cuts.size() + 1) * 10

# Look up the ACTUAL rent from game-captured events (includes floor mods).
# Falls back to the static base_rents table if no event data is available.
func _bh_lookup_actual_rent(actual_rents, idx, base_rents):
    if actual_rents.has(idx):
        return actual_rents[idx]
    if idx < 0:
        return 0
    if idx < base_rents.size():
        return base_rents[idx]
    return 500 + (idx - 11) * 500

# Whether the current run uses a custom seed (excluded from native stats).
func _bh_is_seeded():
    return _bh_rng_seed_type == 'custom'

# Count completed spins from _bh_events (spin_start events).
# Used as the debounce key — two flushes at the same spin count
# are duplicate notifications for the same game state.
func _bh_count_spins():
    var n = 0
    for _ev in _bh_events:
        if str(_ev.get('type', '')) == 'spin_start':
            n += 1
    return n

func _bh_record_cards(presented, email_type):
    _bh_pending_choice = {'presented': presented, 'event_type': email_type}
    var evt = 'symbol_choice_presented'
    if not email_type.begins_with('add_tile'):
        evt = 'item_choice_presented'
    _bh_add_event(evt, {'presented': presented})

func _bh_record_choice(choice_name):
    if _bh_pending_choice.size() == 0:
        return
    var presented = _bh_pending_choice.get('presented', [])
    var skipped = []
    for p in presented:
        var pt = str(p.get('type', ''))
        if pt != choice_name:
            skipped.append(pt)
    # Use symbol_added / item_added (same format as LogParser) so there is
    # exactly one authoritative event per choice.  symbol_chosen / item_chosen
    # with non-null chosen are no longer emitted; _bh_build_timeline handles
    # the old format as a backward-compatible fallback.
    var _evt = 'symbol_added'
    if not _bh_pending_choice.get('event_type', '').begins_with('add_tile'):
        _evt = 'item_added'
    var _ci = _bh_choice_idx
    _bh_choice_idx += 1
    var _pl = {'source': 'choice', 'skipped': skipped, 'choice_idx': _ci}
    if _evt == 'symbol_added':
        _pl['symbol'] = choice_name
    else:
        _pl['item'] = choice_name
    _bh_add_event(_evt, _pl)
    _bh_pending_choice = {}
    _bh_just_recorded_item = choice_name

func _bh_record_skip():
    if _bh_pending_choice.size() == 0:
        return
    var presented = _bh_pending_choice.get('presented', [])
    var ac = []
    for p in presented:
        ac.append(str(p.get('type', '')))
    var evt = 'symbol_chosen'
    if not _bh_pending_choice.get('event_type', '').begins_with('add_tile'):
        evt = 'item_chosen'
    _bh_add_event(evt, {'chosen': null, 'skipped': ac})
    _bh_pending_choice = {}

func _bh_end_run(result):
    # --- Ghost-run filter ---
    # A real game needs spin_start/spin_end events.  run_start + startup
    # popups can accumulate 2-3 events without any spins — discard those.
    var spins = _bh_count_spins()
    if spins == 0:
        _bh_events.clear()
        _bh_flushed_at_spin = -1
        return

    # --- Debounce: skip duplicate notifications for the same game state ---
    # Both write_log(""VICTORY"") and resolve_event(""win"") fire for the same
    # victory.  The second one arrives with no new spin data -- skip it.
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
        # Iterate ALL icons on every reel (not just the visible grid)
        # so symbols outside the displayed_icons window are captured.
        # Badge data read directly from icon properties.
        var _reels = $'Reels'
        for _r in _reels.reels:
            for i in _r.icons:
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
                    var _bt = str(i.displayed_text_value)
                    var _bm = str(i.displayed_multiplier_value)
                    var _bb = str(i.displayed_bonus_value)
                    if _bt != '': entry['badge_text'] = _bt
                    if _bm != '': entry['badge_mult'] = _bm
                    if _bb != '': entry['badge_bonus'] = _bb
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
        'result': result,
        'victory_achieved': _bh_victory_achieved,
        'floor': fl, 'coins': cc,
        'final_symbols': fs, 'final_items': fi,
        'destroyed_symbols': _ds, 'destroyed_items': _di,
        'run_number': _actual_rn,
        'seed_type': _bh_rng_seed_type,
        'seed_input': _bh_rng_seed_input,
        'landlord_seed': _bh_rng_landlord_seed
    })
    _bh_flush()
    _bh_flushed_at_spin = spins

func _bh_fmt_time(tm):
    var _m = str(tm.month)
    if tm.month < 10:
        _m = '0' + _m
    var _d = str(tm.day)
    if tm.day < 10:
        _d = '0' + _d
    var _h = str(tm.hour)
    if tm.hour < 10:
        _h = '0' + _h
    var _mn = str(tm.minute)
    if tm.minute < 10:
        _mn = '0' + _mn
    var _s = str(tm.second)
    if tm.second < 10:
        _s = '0' + _s
    return str(tm.year) + '-' + _m + '-' + _d + 'T' + _h + ':' + _mn + ':' + _s
";
}
