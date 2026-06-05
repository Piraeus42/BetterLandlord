using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// TTButton.do_call() line 501 does OS.set_clipboard("") for TTS purposes,
/// destroying any seed the user copied from the history window.
///
/// Replace the clear call with a safe wrapper that saves/restores clipboard.
/// ISourceMod approach because do_call() has early returns that skip Postfix.
/// </summary>
public class ClipboardPreserveMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://TT Button.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("func _bh_safe_clear_clipboard")) return source;

        // Replace OS.set_clipboard("") with our safe wrapper
        source = source.Replace(
            "\tOS.set_clipboard(\"\")",
            "\t_bh_safe_clear_clipboard()");

        return source + "\n" + SafeClearGdscript + "\n";
    }

    private const string SafeClearGdscript = @"

# ---- BetterHistoryMod clipboard preservation ----

var _bh_clip_saved = ''

func _bh_safe_clear_clipboard():
    _bh_clip_saved = OS.get_clipboard()
    OS.set_clipboard('')
    # Schedule restore for next idle frame — TTS may set clipboard later in this frame
    call_deferred('_bh_restore_clipboard')

func _bh_restore_clipboard():
    var _cur = OS.get_clipboard()
    if typeof(_cur) != TYPE_STRING or _cur == '':
        if typeof(_bh_clip_saved) == TYPE_STRING and _bh_clip_saved.length() > 0:
            OS.set_clipboard(_bh_clip_saved)
";
}
