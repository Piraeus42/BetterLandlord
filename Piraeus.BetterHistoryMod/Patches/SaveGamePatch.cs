using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Hooks save_game() Postfix to dump all 19 PCGRng stream states
/// to a sidecar file alongside the game's native save.
///
/// The sidecar stores (state, inc) for every stream plus seed metadata
/// and a fingerprint for consistency validation on restore.
/// </summary>
[Patch("res://Main.tscn::1", "save_game")]
class SaveGamePatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if not sandbox_mode:
            if has_method("_bh_save_rng_state"):
                _bh_save_rng_state()
            if has_method("_bh_dump_raw_events"):
                _bh_dump_raw_events()
        """);
}
