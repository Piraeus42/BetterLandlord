using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Captures per-spin board symbol values for DPT statistics.
/// Hooks check_values() after the game's final-value pass.  The effective
/// settlement value must be read through get_value("coin"), not final_value:
/// wildcarded symbols receive their payout through flat_value_bonus while
/// true_final_value is set, and that path does not refresh final_value.
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
                        # final_value is stale for Wildcard and any symbol with
                        # wildcarded=true. get_value() selects flat_value_bonus
                        # during the final-value phase, matching settlement.
                        var _entry = {
                            'id': str(_icon.type),
                            'value': _icon.get_value("coin")
                        }
                        if _icon.wildcarded:
                            _entry['wildcarded'] = true
                        # Badge data: use the game's own rendered display strings
                        # (update_value_text() already computed these per symbol type)
                        if typeof(_icon.displayed_text_value) == TYPE_STRING and _icon.displayed_text_value != '':
                            _entry['badge_text'] = str(_icon.displayed_text_value)
                        if typeof(_icon.displayed_multiplier_value) == TYPE_STRING and _icon.displayed_multiplier_value != '' and _icon.get_child(2).raw_string != '':
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
