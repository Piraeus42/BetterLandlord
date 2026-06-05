using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Snapshot flush: when returning to title mid-run, call _bh_end_run("quit")
/// to capture the final board state BEFORE title() clears it (Prefix),
/// write the JSON (so WPF shows "Quit" not "Defeat"), and dump to sidecar
/// for cold-boot Continue recovery.
///
/// _bh_end_run is re-entrant and spin-count debounced — safe to call
/// even if the run was already flushed (victory/loss).  The debounce
/// also prevents TitleSetFloorPatch from doing a redundant quit flush.
/// </summary>
[Patch("res://Main.tscn::1", "title")]
class TitlePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_end_run") and has_method("_bh_dump_raw_events"):
            if _bh_events.size() > 0:
                _bh_end_run("quit")
                _bh_dump_raw_events()
        """);
}
