using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Guillotine essence death calls title() inside _process without going
/// through write_log("VICTORY/GAME OVER") or resolve_event().
/// The animation runs 600 frames; after completion, _bh_events may have
/// been cleared by a prior title() call.  Flush as soon as the guillotine
/// animation starts, before any state reset.
///
/// _bh_end_run is re-entrant and spin-count debounced — safe to call
/// even if the run has already been flushed once.
/// </summary>
[Patch("res://Main.tscn::1", "_process")]
class GuillotineEndPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        # Guillotine death: flush events at animation start (anim just set to 600).
        # Direct variable access — `get()` does not work for injected script vars in Godot 3.x.
        if guillotine_essence_anim == 600 and has_method("_bh_end_run"):
            if _bh_events != null and _bh_events.size() > 1:
                _bh_end_run("victory")
        """);
}
