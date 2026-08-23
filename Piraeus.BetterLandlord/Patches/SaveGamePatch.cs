using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Hooks save_game() Postfix to persist RNG state and incremental event history
/// alongside the game's native save.
/// </summary>
[Patch("res://Main.tscn::1", "save_game")]
class SaveGamePatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if not sandbox_mode:
            if has_method("_bh_save_rng_state"):
                _bh_save_rng_state()
            if has_method("_bh_persist_events_incremental"):
                _bh_persist_events_incremental()
        """);
}
