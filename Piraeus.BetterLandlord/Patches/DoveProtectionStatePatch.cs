using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Dove protection belongs to one resolution only. Clear stale marks when
/// Main.tscn::4.spin() is about to start a genuine new spin.
/// </summary>
[Patch("res://Main.tscn::4", "spin")]
class DoveProtectionStatePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        # spin() is polled from Main.tscn::5.update(), so mirror every guard
        # before resetting a state that must remain valid during resolution.
        var __bl_dove_reset_can_spin = true
        if effects_playing or popup.emails.size() > 0 or $"/root/Main/Coins".coins <= 0 or $"/root/Main/Landlord".anim_time > 0 or $"/root/Main/Sums/HP Sum".adding:
            __bl_dove_reset_can_spin = false
        if __bl_dove_reset_can_spin:
            for __bl_dove_reset_text in texts:
                if __bl_dove_reset_text.effect_timer > 0:
                    __bl_dove_reset_can_spin = false
                    break
        if __bl_dove_reset_can_spin:
            for __bl_dove_reset_reel in reels:
                if __bl_dove_reset_reel.spinning:
                    __bl_dove_reset_can_spin = false
                    break
        if __bl_dove_reset_can_spin:
            for __bl_dove_reset_reel in reels:
                for __bl_dove_reset_icon in __bl_dove_reset_reel.icons:
                    __bl_dove_reset_icon.dove_destroyed = false
                    if __bl_dove_reset_icon.has_meta("_bl_dove_protection_sources"):
                        __bl_dove_reset_icon.remove_meta("_bl_dove_protection_sources")
        """);
}
