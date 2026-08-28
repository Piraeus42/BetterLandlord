using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

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
                var _bh_restored = $"/root/Main"._bh_restore_rng_state()
                if not _bh_restored and has_method("_bh_init_rng"):
                    # Keep the loaded game playable even when exact restoration
                    # is impossible.  _bh_restore_rng_state() has already set
                    # the fail-closed stats guard, so this fallback cannot leak
                    # the run into native win/loss/streak statistics.
                    $"/root/Main"._bh_init_rng("random", "")
        """);
}
