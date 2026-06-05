using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Blocks queued achievement registration for custom-seeded runs.
/// add_queued_achievement is the entry point for all in-spin achievement
/// triggers (clump sizes, symbol counts, etc.).  If the achievement is
/// never queued, unlock_achievement will never process it.
/// </summary>
[Patch("res://Main.tscn::4", "add_queued_achievement")]
class SeededAchievementPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main".has_method("_bh_is_seeded") and $"/root/Main"._bh_is_seeded():
            return
        """);
}
