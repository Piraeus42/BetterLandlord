using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Hooks continue_game() Postfix (after load_data) to restore PCGRng state
/// from the sidecar file written by SaveGamePatch.
///
/// The sidecar stores the exact (state, inc) of all 19 PCG streams,
/// plus seed metadata and a fingerprint for consistency validation.
/// Restore is only accepted if the fingerprint matches the current save.
/// </summary>
[Patch("res://Main.tscn::1", "continue_game")]
class ContinueGamePatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        # Only restore if a save was actually loaded
        if not sandbox_mode and $"/root/Main/Pop-up Sprite/Pop-up".spins > 0:
            if has_method("_bh_restore_rng_state"):
                $"/root/Main"._bh_restore_rng_state()
        """);
}
