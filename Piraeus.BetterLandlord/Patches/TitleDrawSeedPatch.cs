using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Bootstrap only — creates the Seed button and Timer on first draw().
/// After bootstrap, all UI refresh (visibility, position, text) is driven
/// by the Timer's timeout callback (_bh_on_seed_timer).
/// </summary>
[Patch("res://Main.tscn::6", "draw")]
class TitleDrawSeedPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main/Title".has_method("_bh_draw_seed_ui"):
            $"/root/Main/Title"._bh_draw_seed_ui()
        """);
}
