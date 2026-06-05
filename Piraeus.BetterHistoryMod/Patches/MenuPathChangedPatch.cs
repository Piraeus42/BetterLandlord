using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Hooks change_current_menu_path (Main.tscn::1) so seed button visibility
/// updates instantly on menu transitions, rather than waiting for the 0.3s Timer.
/// </summary>
[Patch("res://Main.tscn::1", "change_current_menu_path")]
class MenuPathChangedPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main/Title".has_method("_bh_refresh_seed_visibility"):
            $"/root/Main/Title"._bh_refresh_seed_visibility()
        """);
}
