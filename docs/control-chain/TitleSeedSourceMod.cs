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

# ---- BetterHistoryMod Seed UI (stateful button → WPF dialog) ----

var _bh_custom_seed_btn = null
var _bh_seed_btn_created = false
var _bh_seed_request = 0
var _bh_seed_timer = null

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
                        return {'active': true, 'input': input}
    return {'active': false, 'input': ''}

func _bh_update_seed_button_text():
    if not _bh_seed_btn_created:
        return
    var cfg = _bh_read_seed_config()
    if cfg.active:
        _bh_custom_seed_btn.text = 'Seed: ON'
        _bh_custom_seed_btn.add_color_override('font_color', Color(0.4, 1.0, 0.5, 1))
    else:
        _bh_custom_seed_btn.text = 'Seed: OFF'
        _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))

# Timer callback — polls seed_config.json independently of draw()
func _bh_on_seed_timer():
    if not _bh_seed_btn_created:
        return
    var cfg = _bh_read_seed_config()
    var want = 'Seed: ON' if cfg.active else 'Seed: OFF'
    if _bh_custom_seed_btn != null and _bh_custom_seed_btn.text != want:
        _bh_custom_seed_btn.text = want
        if cfg.active:
            _bh_custom_seed_btn.add_color_override('font_color', Color(0.4, 1.0, 0.5, 1))
        else:
            _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))
        _bh_custom_seed_btn.update()

func _bh_draw_seed_ui():
    if not _bh_seed_btn_created:
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

        # Timer to poll seed_config.json periodically — draw() is not called
        # continuously on the floor menu, so we need an independent refresh source.
        _bh_seed_timer = Timer.new()
        _bh_seed_timer.name = 'BHSeedTimer'
        _bh_seed_timer.wait_time = 0.5
        _bh_seed_timer.one_shot = false
        _bh_seed_timer.connect('timeout', self, '_bh_on_seed_timer')
        add_child(_bh_seed_timer)
        _bh_seed_timer.start()

        _bh_seed_btn_created = true

    # Update button text from seed_config.json on every frame
    _bh_update_seed_button_text()

func _bh_open_custom_seed():
    # Signal GameStateBus reader with a timestamp (always unique per click)
    _bh_seed_request = OS.get_ticks_msec()

func _bh_position_seed_ui():
    if not _bh_seed_btn_created:
        return
    var res_x = $'/root/Main/Options Sprite/Options'.resolution_x
    var res_y = $'/root/Main/Options Sprite/Options'.resolution_y
    var base_x = res_x / 2 + 80
    var base_y = res_y - 70
    _bh_custom_seed_btn.rect_position = Vector2(base_x, base_y)
    _bh_custom_seed_btn.rect_size = Vector2(160, 30)
    _bh_custom_seed_btn.rect_scale = Vector2(1.1, 1.1)

var _bh_prev_on_floor = false

func _bh_update_seed_visibility():
    if not _bh_seed_btn_created:
        return
    var on_floor = $""/root/Main"".current_menu_path == ""floor_menu""
    _bh_custom_seed_btn.visible = on_floor

    # Reset seed state every time we enter the floor menu
    if on_floor and not _bh_prev_on_floor:
        var file = File.new()
        var path = ""user://betterHistory/seed_config.json""
        _bh_update_seed_button_text()

    _bh_prev_on_floor = on_floor

# Called by _bh_apply_seed() in RngInfrastructureSourceMod — reads seed_config.json
# written by GamePipeServer when WPF dialog confirms.
func _bh_get_seed_config():
    var cfg = _bh_read_seed_config()
    if cfg.active:
        var input = cfg.input.replace('O', '0').replace('I', '1')
        return {'type': 'custom', 'input': input}
    return {'type': 'random', 'input': ''}
";
}
