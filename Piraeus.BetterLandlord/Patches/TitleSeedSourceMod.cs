using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

public class TitleSeedSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::6";

    public string Modify(string path, string source)
    {
        return source + "\n" + GdscriptUtil.Tabify(SeedUiGdscript);
    }

    private const string SeedUiGdscript = @"

# ---- BetterHistoryMod Seed UI (monotonic counter → WPF, single Timer tick) ----

var _bh_custom_seed_btn = null
var _bh_seed_btn_created = false
var _bh_seed_request_seq = 0      # monotonic counter — read by SeedSignalReader
var _bh_seed_timer = null
# Cache last known state so transient read failures don't flash OFF
var _bh_last_seed_state = {'active': false, 'input': ''}
var _bh_prev_on_floor = false     # detect floor-menu entry edge

func _bh_read_seed_config():
    var file = File.new()
    var path = ""user://betterHistory/seed_config.json""
    if file.file_exists(path):
        if file.open(path, File.READ) == OK:
            var text = file.get_as_text()
            file.close()
            var parsed = JSON.parse(text)
            if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
                var cfg = parsed.result
                if cfg.get('type', '') == 'custom':
                    var input = str(cfg.get('input', ''))
                    if input.length() > 0:
                        _bh_last_seed_state = {'active': true, 'input': input}
                        return _bh_last_seed_state
                _bh_last_seed_state = {'active': false, 'input': ''}
                return _bh_last_seed_state
    # File missing or parse failed — return last known state, no flash
    return _bh_last_seed_state

# ---- Reset seed to random — called on floor-menu entry ----

func _bh_reset_seed_to_random():
    var file = File.new()
    var path = ""user://betterHistory/seed_config.json""
    var dir = Directory.new()
    if not dir.dir_exists(""user://betterHistory""):
        dir.make_dir(""user://betterHistory"")
    # Atomic write (.tmp → rename, same pattern as C# side)
    var tmp = path + "".tmp""
    file.open(tmp, File.WRITE)
    file.store_string(JSON.print({'type': 'random', 'input': '', 'updated_at': ''}))
    file.close()
    # Godot 3.x doesn't have Directory.rename; use file copy + remove
    var df = Directory.new()
    if df.file_exists(path):
        df.remove(path)
    df.rename(tmp, path)
    _bh_last_seed_state = {'active': false, 'input': ''}

# ---- Single UI tick source: visibility, position, text all driven by Timer ----

# Called on every change_current_menu_path — instant visibility, zero delay
func _bh_refresh_seed_visibility():
    if not _bh_seed_btn_created or _bh_custom_seed_btn == null:
        return
    _bh_custom_seed_btn.visible = $""/root/Main"".current_menu_path == ""floor_menu""

func _bh_on_seed_timer():
    if not _bh_seed_btn_created or _bh_custom_seed_btn == null:
        return

    var on_floor = $""/root/Main"".current_menu_path == ""floor_menu""
    if not on_floor:
        _bh_prev_on_floor = false
        return

    # Just entered floor menu → reset seed to random/OFF
    if not _bh_prev_on_floor:
        _bh_reset_seed_to_random()
        _bh_prev_on_floor = true

    # Position — recalculate every tick (resolution may change)
    var res_x = $'/root/Main/Options Sprite/Options'.resolution_x
    var res_y = $'/root/Main/Options Sprite/Options'.resolution_y
    _bh_custom_seed_btn.rect_position = Vector2(res_x / 2 + 80, res_y - 70)
    _bh_custom_seed_btn.rect_size = Vector2(160, 30)
    _bh_custom_seed_btn.rect_scale = Vector2(1.1, 1.1)

    # Text — show seed value when active, OFF when random
    var cfg = _bh_read_seed_config()
    var want = ('Seed: ' + cfg.input) if cfg.active else 'Seed: OFF'
    _bh_custom_seed_btn.text = want

    # Set all state slots — otherwise hover/pressed fall back to default gray
    var col = Color(0.3, 0.95, 0.35, 1) if cfg.active else Color(0.8, 0.8, 0.9, 1)
    _bh_custom_seed_btn.add_color_override('font_color', col)
    _bh_custom_seed_btn.add_color_override('font_color_hover', col)
    _bh_custom_seed_btn.add_color_override('font_color_pressed', col)
    _bh_custom_seed_btn.add_color_override('font_color_focus', col)

    _bh_custom_seed_btn.update()

# ---- Bootstrap: draw() Postfix calls this — create button + Timer once ----

func _bh_draw_seed_ui():
    if _bh_seed_btn_created:
        return

    # Clean up any orphaned nodes from previous reload
    if _bh_custom_seed_btn != null:
        _bh_custom_seed_btn.queue_free()
    if _bh_seed_timer != null:
        _bh_seed_timer.queue_free()

    _bh_custom_seed_btn = Button.new()
    _bh_custom_seed_btn.name = 'BHCustomSeed'
    _bh_custom_seed_btn.text = 'Seed: OFF'
    _bh_custom_seed_btn.flat = false
    var _sb = StyleBoxFlat.new()
    _sb.bg_color = Color(0.15, 0.15, 0.25, 0.95)
    _sb.border_width_left = 1
    _sb.border_width_right = 1
    _sb.border_width_top = 1
    _sb.border_width_bottom = 1
    _sb.border_color = Color(0.3, 0.3, 0.5, 1)
    _sb.corner_radius_top_left = 4
    _sb.corner_radius_top_right = 4
    _sb.corner_radius_bottom_left = 4
    _sb.corner_radius_bottom_right = 4
    _bh_custom_seed_btn.add_stylebox_override('normal', _sb)
    _bh_custom_seed_btn.add_stylebox_override('hover', _sb)
    _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))
    _bh_custom_seed_btn.connect('pressed', self, '_bh_open_custom_seed')
    add_child(_bh_custom_seed_btn)

    # Timer drives ALL UI refresh — independent of draw()
    _bh_seed_timer = Timer.new()
    _bh_seed_timer.name = 'BHSeedTimer'
    _bh_seed_timer.wait_time = 0.3
    _bh_seed_timer.one_shot = false
    _bh_seed_timer.connect('timeout', self, '_bh_on_seed_timer')
    add_child(_bh_seed_timer)
    _bh_seed_timer.start()

    _bh_seed_btn_created = true

# ---- Button click: monotonic counter — C# reader picks it up as pending ----

func _bh_open_custom_seed():
    _bh_seed_request_seq += 1

# Called by _bh_apply_seed() in RngInfrastructureSourceMod — reads seed_config.json
# written atomically by GamePipeServer when WPF dialog confirms.
func _bh_get_seed_config():
    var cfg = _bh_read_seed_config()
    if cfg.active:
        var input = cfg.input.replace('O', '0').replace('I', '1')
        return {'type': 'custom', 'input': input}
    return {'type': 'random', 'input': ''}
";
}
