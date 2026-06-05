using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

[Patch("res://Main.tscn::6", "draw")]
class TitleDrawSeedPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main/Title".has_method("_bh_draw_seed_ui"):
            $"/root/Main/Title"._bh_draw_seed_ui()
        if $"/root/Main/Title".has_method("_bh_position_seed_ui"):
            $"/root/Main/Title"._bh_position_seed_ui()
        if $"/root/Main/Title".has_method("_bh_update_seed_visibility"):
            $"/root/Main/Title"._bh_update_seed_visibility()
        """);
}
