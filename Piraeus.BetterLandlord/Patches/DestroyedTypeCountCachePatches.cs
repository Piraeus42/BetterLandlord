using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Saved game loading assigns the native arrays directly. Explicitly discard
/// cache contents after load/reset so identical-length arrays can never reuse
/// counts from a previous run or save snapshot.
/// </summary>
[Patch("res://Main.tscn::1", "reset_values")]
class InvalidateDestroyedTypeCountCachesOnResetPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        $"Pop-up Sprite/Pop-up"._bh_invalidate_destroyed_type_count_caches()
        $"Items"._bh_invalidate_destroyed_item_type_count_cache()
        """);
}

[Patch("res://Main.tscn::1", "load_game")]
class InvalidateDestroyedTypeCountCachesOnLoadPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        $"Pop-up Sprite/Pop-up"._bh_invalidate_destroyed_type_count_caches()
        $"Items"._bh_invalidate_destroyed_item_type_count_cache()
        """);
}
