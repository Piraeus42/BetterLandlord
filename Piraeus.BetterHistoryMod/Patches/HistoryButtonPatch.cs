using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Adds "History" button to the Title main menu (draw()).
/// Instead of rendering UI in-game, the button calls _bh_toggle_ui()
/// which writes a flag file that the C# GamePipeServer detects.
/// </summary>
[Patch("res://Main.tscn::6", "draw")]
class HistoryButtonPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        var _hb = preload("res://TT Button.tscn").instance()
        _hb.button_text = "History"
        _hb.color = Color($"/root/Main/Options Sprite/Options".colors3["button_color_continue"])
        _hb.color_type = "button_color_continue"
        _hb.target = self
        _hb.call = "_bh_toggle_ui"
        _hb.toggle = false
        _hb.title_button = true
        if $"/root/Main/Options Sprite/Options".resolution_y < 720:
            _hb.scale_mod = -1
        add_child(_hb)
        _hb.text_node.update()
        _hb.button_text = _hb.text_node.text
        _hb.update_size()
        _hb.button_text = _hb.text_node.raw_string
        _hb.base_x = _hb.rect_position.x
        buttons.push_back(_hb)
        update_button_positions()
        """);
}
