using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Snapshot flush: when returning to title mid-run, write the current events
/// to JSON (so WPF history refreshes as "Quit"), but preserve events in memory
/// and on disk so Continue (warm or cold) picks up seamlessly.
///
/// _bh_flush() deletes the temp events file as part of its cleanup.  We
/// re-dump it immediately after restoring memory so cold-boot Continue
/// still has recovery data.
/// </summary>
[Patch("res://Main.tscn::1", "title")]
class TitlePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_flush") and has_method("_bh_dump_raw_events"):
            if _bh_events.size() > 0 and not _bh_run_ended:
                var _saved = _bh_events.duplicate(true)
                _bh_flush()
                _bh_events = _saved
                _bh_dump_raw_events()
                _bh_run_ended = false
        """);
}
