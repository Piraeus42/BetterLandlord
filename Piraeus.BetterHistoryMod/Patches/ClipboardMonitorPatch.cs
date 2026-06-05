using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Hooks Main._process to sample clipboard every 0.5s.
/// Used to pinpoint exactly when Godot clears the clipboard.
/// </summary>
[Patch("res://Main.tscn::1", "_process")]
class ClipboardMonitorPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if has_method("_bh_clip_sample"):
            _bh_clip_timer += delta
            if _bh_clip_timer >= 1.0:
                _bh_clip_sample()
        """);
}
