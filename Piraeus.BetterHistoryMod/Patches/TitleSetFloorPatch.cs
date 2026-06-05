using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// new_game() Prefix: flush any saved run, then start fresh.
///
/// If events exist from a previous session that was never ended
/// (player quit to title mid-run and chose New Game instead of Continue),
/// flush them now.  Then reset bookkeeping, apply seed, and record run_start.
/// </summary>
[Patch("res://Main.tscn::1", "new_game")]
class TitleSetFloorPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_end_run") and has_method("_bh_start_run") and has_method("_bh_apply_seed"):
            # new_game() is called twice: once on button click (floor not selected →
            # shows floor menu), once after floor selection (actually starts game).
            # Only flush+init on the second call when a run is really about to begin.
            if $'Pop-up Sprite/Pop-up'.floor_selected or demo:
                # Flush any dangling events from a previous run.
                # _bh_end_run is debounced — safe to call even if already flushed.
                if _bh_events.size() > 0:
                    _bh_end_run("quit")
                # Fresh bookkeeping for the new run
                _bh_start_run()
                # Apply seed from UI / config
                _bh_apply_seed()
                _bh_add_event("run_start", {
                    "run_number": $'Pop-up Sprite/Pop-up'.total_runs,
                    "version": version_str
                })
        """);
}
