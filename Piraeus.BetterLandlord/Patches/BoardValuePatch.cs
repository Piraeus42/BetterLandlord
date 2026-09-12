using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Captures per-spin board symbol values for DPT statistics.
/// Hooks check_values() after the game's final-value pass.  The effective
/// settlement value must be read through get_value("coin"), not final_value:
/// wildcarded symbols receive their payout through flat_value_bonus while
/// true_final_value is set, and that path does not refresh final_value.
///
/// get_value() includes the accumulated prev_data of every form the icon
/// replaced this spin (Shrine-style destroy-and-replace, growth transforms).
/// The payout total is settlement-accurate, but keying the whole amount by the
/// current type would credit a departed symbol's final production to its
/// replacement (e.g. a fresh Spirit inheriting a destroyed Sun's value).  The
/// prev_data contribution is therefore split per layer and attributed to the
/// form that produced it.
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
                        var _total = _icon.get_value("coin")
                        var _own = _total
                        var _inherited_layers = []
                        if not _icon.drained and _icon.prev_data.size() > 0:
                            # Same value-source switch get_value() applies, so
                            # each layer below mirrors what the game's prev_data
                            # loop added to the settlement total.
                            var _v_str = 'value'
                            if _icon.wildcarded and true_final_value:
                                _v_str = 'flat_value_bonus'
                            for _p in _icon.prev_data:
                                var _p_bonus = 0
                                var _p_mult = 1.0
                                for _pv in _p['value_bonus_arr']:
                                    _p_bonus += _pv.value
                                for _pm in _p['value_multiplier_arr']:
                                    _p_mult *= _pm.value
                                var _p_base = int(_p[_v_str]) + int(_p_bonus) + int(_p['permanent_bonus'])
                                var _p_val
                                if _p_base * _p_mult * float(_p['permanent_multiplier']) < 0:
                                    _p_val = round(_p_base)
                                else:
                                    _p_val = round(_p_base * _p_mult * float(_p['permanent_multiplier']))
                                _own -= _p_val
                                var _p_type = str(_p.get('type', ''))
                                if _p_type != '' and _p_type != 'null' and _p_val != 0:
                                    _inherited_layers.append({'id': _p_type, 'value': _p_val, 'inherited': true})
                        var _entry = {
                            'id': str(_icon.type),
                            'value': _own
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
