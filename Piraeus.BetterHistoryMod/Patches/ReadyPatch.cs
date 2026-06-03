using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

[Patch("res://Main.tscn::1", "_ready")]
class ReadyPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main".has_method("_bh_init"):
            $"/root/Main"._bh_init()
        """);
}
