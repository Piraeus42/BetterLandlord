using SlotWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Injects _bh_toggle_ui() and _bh_init_flags() helpers onto the Title node.
/// Writes a flag file that the C# GamePipeServer polls for.
/// </summary>
public class TitleToggleSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::6";

    public string Modify(string path, string source)
    {
return source + "\n" + GdscriptUtil.Tabify(ToggleHelpersGdscript);
    }

    private const string ToggleHelpersGdscript = @"

# ---- BetterHistoryMod IPC toggle helpers (Title node) ----

# Monotonic counter — SeedSignalReader picks this up every frame
var _bh_history_request_seq = 0

# Called by HistoryButtonPatch (TTButton on title menu)
func _bh_toggle_ui():
    _bh_history_request_seq += 1

# Clean up orphaned elements when leaving history mode.
func _bh_cleanup_title():
    pass
";
}
