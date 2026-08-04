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
        var __bh_prof_spin_start_us = -1
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
                    if $"/root/Main".has_method("_bh_profile_begin"):
                        __bh_prof_spin_start_us = OS.get_ticks_usec()
                        $"/root/Main"._bh_profile_begin("spin", "spin", str(_popup.spins + 1))
                    # Initialize per-spin RNG before the spin executes
                    if $"/root/Main".has_method("_bh_begin_spin_rng"):
                        $"/root/Main"._bh_begin_spin_rng()
                    $"/root/Main"._bh_add_event("spin_start", {
                        "spin_num": _popup.spins + 1,
                        "coins": $"/root/Main/Coins".coins,
                        "floor": _popup.current_floor,
                        "rent_paid": _popup.times_rent_paid
                    })
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_spin_start_us >= 0 and $"/root/Main".has_method("_bh_profile_record"):
            $"/root/Main"._bh_profile_record("reels.spin", __bh_prof_spin_start_us)
            $"/root/Main"._bh_profile_schedule_flush()
            $"/root/Main"._bh_profile_end()
        """);
}
