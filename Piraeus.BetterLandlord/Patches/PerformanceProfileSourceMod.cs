using System.Text;
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Appends lightweight, raw JSONL performance profiling helpers to Main.
/// Samples stay in memory briefly and are appended in batches so profiling does
/// not add a synchronous file write to every game operation.
/// </summary>
public class PerformanceProfileSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("var _bh_profile_samples = []")) return source;

        var sb = new StringBuilder(source);
        sb.Append('\n');
        sb.Append(GdscriptUtil.Tabify(ProfileHelpers));
        sb.Append('\n');
        return sb.ToString();
    }

    private const string ProfileHelpers = @"

# ---- BetterLandlord raw performance profile (auto-generated) ----
# JSONL is intentionally raw: one unaggregated operation sample per line.
# Writes are batched so the profiler does not turn each measured operation into
# a disk stall of its own.
var _bh_profile_enabled = true
var _bh_profile_samples = []
var _bh_profile_sequence = 0
var _bh_profile_session_id = ''
var _bh_profile_started_us = -1
var _bh_profile_file_path = ''
var _bh_profile_phase = 'idle'
var _bh_profile_event_type = ''
var _bh_profile_choice = ''
var _bh_profile_flush_threshold = 64
var _bh_profile_flush_scheduled = false
var _bh_profile_context_id = 0
var _bh_profile_current_context_id = 0
var _bh_profile_context_start_us = -1
# The last deferred disk flush is reported at the next context boundary.  It is
# intentionally not attributed to the click that scheduled it.
var _bh_profile_last_flush_metrics = {}

func _bh_profile_init():
    if _bh_profile_file_path != '':
        return
    var _dir = Directory.new()
    var _base = 'user://betterlandlord_profile'
    if _dir.dir_exists(_base) == false:
        _dir.make_dir_recursive(_base)
    _bh_profile_started_us = OS.get_ticks_usec()
    _bh_profile_session_id = str(OS.get_unix_time()) + '_' + str(_bh_profile_started_us)
    _bh_profile_file_path = _base + '/profile_' + _bh_profile_session_id + '.jsonl'
    _bh_profile_samples.clear()
    _bh_profile_sequence = 0
    _bh_profile_context_id = 0
    _bh_profile_current_context_id = 0
    _bh_profile_context_start_us = -1
    _bh_profile_last_flush_metrics = {}
    _bh_profile_write_line({
        'record_type': 'session_start',
        'schema_version': 2,
        'session_id': _bh_profile_session_id,
        'timestamp_us': _bh_profile_started_us,
        'unix_time': OS.get_unix_time()
    })

func _bh_profile_begin(phase, event_type = '', choice = ''):
    if not _bh_profile_enabled:
        return
    _bh_profile_init()
    _bh_profile_emit_last_flush_metrics()
    _bh_profile_phase = str(phase)
    _bh_profile_event_type = str(event_type)
    _bh_profile_choice = str(choice)
    _bh_profile_context_id += 1
    _bh_profile_current_context_id = _bh_profile_context_id
    _bh_profile_context_start_us = OS.get_ticks_usec()
    _bh_profile_append_record({
        'record_type': 'context_start',
        'schema_version': 2,
        'session_id': _bh_profile_session_id,
        'context_id': _bh_profile_current_context_id,
        'timestamp_us': _bh_profile_context_start_us,
        'elapsed_us': max(0, _bh_profile_context_start_us - _bh_profile_started_us),
        'phase': _bh_profile_phase,
        'event_type': _bh_profile_event_type,
        'choice': _bh_profile_choice,
        'state': _bh_profile_state()
    })

func _bh_profile_end():
    if not _bh_profile_enabled:
        return
    var _ended_us = OS.get_ticks_usec()
    if _bh_profile_current_context_id > 0:
        _bh_profile_append_record({
            'record_type': 'context_end',
            'schema_version': 2,
            'session_id': _bh_profile_session_id,
            'context_id': _bh_profile_current_context_id,
            'timestamp_us': _ended_us,
            'elapsed_us': max(0, _ended_us - _bh_profile_started_us),
            'duration_us': max(0, _ended_us - _bh_profile_context_start_us),
            'phase': _bh_profile_phase,
            'event_type': _bh_profile_event_type,
            'choice': _bh_profile_choice,
            'state': _bh_profile_state()
        })
    _bh_profile_current_context_id = 0
    _bh_profile_context_start_us = -1
    _bh_profile_phase = 'idle'
    _bh_profile_event_type = ''
    _bh_profile_choice = ''

func _bh_profile_record(operation, started_us, extra = {}):
    if not _bh_profile_enabled or started_us < 0:
        return
    _bh_profile_init()
    var _ended_us = OS.get_ticks_usec()
    _bh_profile_sequence += 1
    var _sample = {
        'record_type': 'operation',
        'schema_version': 2,
        'session_id': _bh_profile_session_id,
        'seq': _bh_profile_sequence,
        'context_id': _bh_profile_current_context_id,
        'timestamp_us': _ended_us,
        'elapsed_us': max(0, _ended_us - _bh_profile_started_us),
        'duration_us': max(0, _ended_us - started_us),
        'observer_us': 0,
        'operation': str(operation),
        'phase': _bh_profile_phase,
        'event_type': _bh_profile_event_type,
        'choice': _bh_profile_choice,
        'extra': extra
    }
    _bh_profile_append_record(_sample)
    _sample['observer_us'] = max(0, OS.get_ticks_usec() - _ended_us)

func _bh_profile_append_record(record):
    _bh_profile_samples.append(record)
    if _bh_profile_samples.size() >= _bh_profile_flush_threshold:
        _bh_profile_schedule_flush()

func _bh_profile_emit_last_flush_metrics():
    if _bh_profile_last_flush_metrics.size() == 0:
        return
    var _metrics = _bh_profile_last_flush_metrics
    _bh_profile_last_flush_metrics = {}
    var _base = {
        'record_type': 'operation',
        'schema_version': 2,
        'session_id': _bh_profile_session_id,
        'context_id': 0,
        'timestamp_us': _metrics.get('timestamp_us', OS.get_ticks_usec()),
        'elapsed_us': _metrics.get('elapsed_us', 0),
        'phase': 'profiler',
        'event_type': '',
        'choice': '',
        'extra': {
            'sample_count': _metrics.get('sample_count', 0),
            'bytes': _metrics.get('bytes', 0)
        }
    }
    var _serialize = _base.duplicate(true)
    _serialize['operation'] = 'profile.flush_serialize'
    _serialize['duration_us'] = _metrics.get('serialize_us', 0)
    _serialize['observer_us'] = 0
    _bh_profile_append_record(_serialize)
    var _write = _base.duplicate(true)
    _write['operation'] = 'profile.flush_write'
    _write['duration_us'] = _metrics.get('write_us', 0)
    _write['observer_us'] = 0
    _bh_profile_append_record(_write)
    var _total = _base.duplicate(true)
    _total['operation'] = 'profile.flush_total'
    _total['duration_us'] = _metrics.get('total_us', 0)
    _total['observer_us'] = 0
    _bh_profile_append_record(_total)

func _bh_profile_state():
    var _state = {
        'run': -1,
        'spin': -1,
        'floor': -1,
        'coins': -1,
        'items': 0,
        'destroyed_symbols': 0,
        'destroyed_items': 0,
        'reels': 0,
        'icon_slots': 0,
        'non_empty_symbols': 0,
        'saved_values_author_keys': 0,
        'saved_values_value_count': 0
    }
    # Fine-grained hooks can run while the title scene is still constructing.
    # Do not traverse partially initialized nodes for records outside an active
    # game operation. This also keeps title/startup work out of the profile.
    if _bh_profile_phase == 'idle':
        return _state

    # These nodes and fields are part of the game scene contracts. The state
    # walk runs only at a profile-context boundary, never once per low-level
    # symbol/item callback while a scene is being initialized or resolved.
    var _popup = get_node_or_null('Pop-up Sprite/Pop-up')
    if _popup != null:
        _state['run'] = _popup.total_runs
        _state['spin'] = _popup.spins
        _state['floor'] = _popup.current_floor
        _state['destroyed_symbols'] = _popup.destroyed_symbol_types.size()
    var _coins_node = get_node_or_null('Coins')
    if _coins_node != null:
        _state['coins'] = _coins_node.coins
    var _items_node = get_node_or_null('Items')
    if _items_node != null:
        _state['items'] = _items_node.items.size()
        _state['destroyed_items'] = _items_node.destroyed_item_types.size()
    var _reels_node = get_node_or_null('Reels')
    if _reels_node != null:
        _state['reels'] = _reels_node.reels.size()
        for _reel in _reels_node.reels:
            _state['icon_slots'] += _reel.icons.size()
            for _icon in _reel.icons:
                if _icon.type != 'empty' and _icon.type != 'dud':
                    _state['non_empty_symbols'] += 1
                if typeof(_icon.saved_values) == TYPE_DICTIONARY:
                    _state['saved_values_author_keys'] += _icon.saved_values.size()
                    for _key in _icon.saved_values.keys():
                        var _values = _icon.saved_values[_key]
                        if typeof(_values) == TYPE_ARRAY:
                            _state['saved_values_value_count'] += _values.size()
    return _state

func _bh_profile_flush():
    if _bh_profile_samples.size() == 0:
        return
    _bh_profile_init()
    var _flush_started_us = OS.get_ticks_usec()
    var _sample_count = _bh_profile_samples.size()
    var _file = File.new()
    var _mode = File.READ_WRITE if _file.file_exists(_bh_profile_file_path) else File.WRITE
    var _open_error = _file.open(_bh_profile_file_path, _mode)
    if _open_error != OK:
        return
    _file.seek_end()
    var _serialize_start_us = OS.get_ticks_usec()
    var _lines = ''
    for _sample in _bh_profile_samples:
        _lines += to_json(_sample) + '\n'
    var _serialize_us = max(0, OS.get_ticks_usec() - _serialize_start_us)
    var _write_start_us = OS.get_ticks_usec()
    _file.store_string(_lines)
    _file.close()
    var _write_us = max(0, OS.get_ticks_usec() - _write_start_us)
    var _total_us = max(0, OS.get_ticks_usec() - _flush_started_us)
    _bh_profile_samples.clear()
    _bh_profile_last_flush_metrics = {
        'timestamp_us': _flush_started_us,
        'elapsed_us': max(0, _flush_started_us - _bh_profile_started_us),
        'sample_count': _sample_count,
        'bytes': _lines.length(),
        'serialize_us': _serialize_us,
        'write_us': _write_us,
        'total_us': _total_us
    }

func _bh_profile_schedule_flush():
    if _bh_profile_samples.size() == 0 or _bh_profile_flush_scheduled:
        return
    _bh_profile_flush_scheduled = true
    call_deferred('_bh_profile_deferred_flush')

func _bh_profile_deferred_flush():
    _bh_profile_flush_scheduled = false
    _bh_profile_flush()

func _bh_profile_force_flush():
    # Reserved for a future shutdown hook. Do not synchronously write during a
    # player action: it would contaminate the latency being measured.
    _bh_profile_schedule_flush()

func _bh_profile_write_line(value):
    var _file = File.new()
    var _mode = File.READ_WRITE if _file.file_exists(_bh_profile_file_path) else File.WRITE
    var _open_error = _file.open(_bh_profile_file_path, _mode)
    if _open_error != OK:
        return
    _file.seek_end()
    _file.store_string(to_json(value) + '\n')
    _file.close()
";
}
