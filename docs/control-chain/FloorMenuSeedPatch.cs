using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

[Patch("res://Main.tscn::6", "floor_menu")]
class FloorMenuSeedPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main/Title".has_method("_bh_update_seed_visibility"):
            $"/root/Main/Title"._bh_update_seed_visibility()
        """);
}
