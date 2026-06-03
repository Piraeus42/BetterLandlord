using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Captures per-spin board symbol values for DPT statistics.
/// Hooks check_values() — at this point true_final_value=true and
/// displayed_icons[][] has its final_value computed.
/// </summary>
[Patch("res://Main.tscn::4", "check_values")]
class BoardValuePatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main".has_method("_bh_add_event") and true_final_value:
            var _grid_vals = []
            for _y in range(reel_height):
                for _x in range(reel_width):
                    var _icon = displayed_icons[_y][_x]
                    if _icon.type != 'empty' and _icon.type != 'dud':
                        var _entry = {
                            'id': str(_icon.type),
                            'value': _icon.final_value
                        }
                        # Badge data: use the game's own rendered display strings
                        # (update_value_text() already computed these per symbol type)
                        if typeof(_icon.displayed_text_value) == TYPE_STRING and _icon.displayed_text_value != '':
                            _entry['badge_text'] = str(_icon.displayed_text_value)
                        if typeof(_icon.displayed_multiplier_value) == TYPE_STRING and _icon.displayed_multiplier_value != '':
                            _entry['badge_mult'] = str(_icon.displayed_multiplier_value)
                        if typeof(_icon.displayed_bonus_value) == TYPE_STRING and _icon.displayed_bonus_value != '':
                            _entry['badge_bonus'] = str(_icon.displayed_bonus_value)
                        _grid_vals.append(_entry)
            if _grid_vals.size() > 0:
                $"/root/Main"._bh_add_event("board_value", {
                    "spin_num": popup.spins,
                    "values": _grid_vals
                })
        """);
}
