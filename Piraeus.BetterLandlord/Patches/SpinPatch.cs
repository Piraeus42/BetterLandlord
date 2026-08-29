using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Records spin_start events. Must mirror spin()'s internal guard to avoid
/// firing on every frame (Main.tscn::5.update() calls spin() each frame).
/// </summary>
[Patch("res://Main.tscn::4", "spin")]
class SpinPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        # Mirror spin()'s guard — only record if spin would actually execute
        if $"/root/Main".has_method("_bh_add_event"):
            var _popup = $"/root/Main/Pop-up Sprite/Pop-up"
            var _reels = $"/root/Main/Reels"
            if typeof(_popup) != TYPE_NIL and typeof(_reels) != TYPE_NIL:
                # Same guards as spin() line 190 + 247
                var _can_spin = true
                if _reels.effects_playing or _popup.emails.size() > 0:
                    _can_spin = false
                if $"/root/Main/Coins".coins <= 0:
                    _can_spin = false
                if $"/root/Main/Landlord".anim_time > 0:
                    _can_spin = false
                if typeof($"/root/Main/Sums/HP Sum") != TYPE_NIL and $"/root/Main/Sums/HP Sum".adding:
                    _can_spin = false
                for _r in _reels.reels:
                    if _r.spinning:
                        _can_spin = false
                if _can_spin:
                    # Initialize per-spin RNG before the spin executes
                    if $"/root/Main".has_method("_bh_begin_spin_rng"):
                        $"/root/Main"._bh_begin_spin_rng()
                    $"/root/Main"._bh_add_event("spin_start", {
                        "spin_num": _popup.spins + 1,
                        "coins": $"/root/Main/Coins".coins,
                        "floor": _popup.current_floor,
                        "rent_paid": _popup.times_rent_paid
                    })
                    var _deck_symbols = []
                    # These symbols use the lower-right native counter as a
                    # countdown to their next change, effect, or removal.
                    # Do not capture accumulating values such as Thief/Gambler.
                    var _countdown_symbol_types = [
                        'snail', 'turtle', 'sloth', 'magpie', 'robin_hood', 'owl',
                        'spirit', 'coal',
                        'matryoshka_doll_1', 'matryoshka_doll_2', 'matryoshka_doll_3', 'matryoshka_doll_4', 'golem',
                        'mine', 'bubble', 'bar_of_soap', 'present', 'crow', 'frozen_fossil',
                        'rabbit', 'wine', 'dud', 'light_bulb'
                    ]
                    for _r in _reels.reels:
                        for _icon in _r.icons:
                            if _icon.type != 'empty':
                                var _deck_symbol = {'id': str(_icon.type)}
                                var _turns_until_change = -1
                                var _symbol_type = str(_icon.type)
                                var _steam_id_index = _symbol_type.find('_STEAM_ID_')
                                var _base_symbol_type = _symbol_type if _steam_id_index < 0 else _symbol_type.substr(0, _steam_id_index)
                                if _countdown_symbol_types.has(_base_symbol_type):
                                    # displayed_text_value follows the same logic as the
                                    # game's lower-right label, including item modifiers.
                                    var _counter_text = str(_icon.displayed_text_value)
                                    if _counter_text.is_valid_integer():
                                        _turns_until_change = int(_counter_text)
                                if _turns_until_change >= 0:
                                    _deck_symbol['turns_until_change'] = _turns_until_change
                                # Permanent stack bonuses use a separate native label.
                                var _stack_value = str(_icon.displayed_bonus_value)
                                # Rabbit and Wine have a fixed mature value; their
                                # default "1" is not an accumulating stack badge.
                                if _stack_value != '' and _base_symbol_type != 'rabbit' and _base_symbol_type != 'wine':
                                    _deck_symbol['stack_value'] = _stack_value
                                _deck_symbols.append(_deck_symbol)
                    $"/root/Main"._bh_add_event("deck_snapshot", {
                        "spin_num": _popup.spins + 1,
                        "symbols": _deck_symbols
                    })
        """);
}
