using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Snapshot flush: when returning to title mid-run, write the current events
/// to JSON (so WPF history refreshes), then dump to sidecar for cold-boot
/// Continue recovery.
///
/// _bh_flush() is now non-destructive — events remain in memory, so the
/// old save/restore dance is unnecessary.  Any later ending (guillotine,
/// coin-loss, force-close) re-flushes the full buffer in place.
/// </summary>
[Patch("res://Main.tscn::1", "title")]
class TitlePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_flush") and has_method("_bh_dump_raw_events"):
            if _bh_events.size() > 0:
                _bh_flush()
                _bh_dump_raw_events()
        """);
}
