using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

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
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_save_game_start_us = -1
        if has_method("_bh_profile_record"):
            __bh_prof_save_game_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_save_game_start_us >= 0 and has_method("_bh_profile_record"):
            _bh_profile_record("main.save_game_native", __bh_prof_save_game_start_us)
        if not sandbox_mode:
            if has_method("_bh_save_rng_state"):
                var __bh_prof_save_rng_start_us = OS.get_ticks_usec()
                _bh_save_rng_state()
                if has_method("_bh_profile_record"):
                    _bh_profile_record("mod.save_rng_state", __bh_prof_save_rng_start_us)
            if has_method("_bh_persist_events_incremental"):
                var __bh_prof_persist_events_start_us = OS.get_ticks_usec()
                _bh_persist_events_incremental()
                if has_method("_bh_profile_record"):
                    _bh_profile_record("mod.events_persist_total", __bh_prof_persist_events_start_us)
        if has_method("_bh_profile_force_flush"):
            _bh_profile_schedule_flush()
        """);
}
