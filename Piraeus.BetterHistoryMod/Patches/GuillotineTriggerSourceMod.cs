using System.Text.RegularExpressions;
using SlotWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Injects _bh_end_run("victory") at the actual guillotine trigger points
/// (Coins.update / Items update), BEFORE the animation starts and before
/// any board state is cleared.
///
/// This replaces GuillotineEndPatch which hooked Main._process at anim==600
/// — too late: by then the board may already be cleared, corrupting the
/// summary snapshot in the final JSON.
/// </summary>
public class GuillotineTriggerSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path switch
    {
        "res://Coins.tscn::1" => true,
        "res://Items.tscn::1" => true,
        _ => false
    };

    public string Modify(string path, string source)
    {
        if (source.Contains("_bh_end_run")) return source;

        // Match the exact line that sets guillotine_essence_anim = 600,
        // capturing its leading whitespace so injected lines use the same
        // indentation.  Append a guarded _bh_end_run("victory") call
        // immediately after — at this point the board is 100% intact.
        // \r? handles CRLF line endings in the original game files.
        source = Regex.Replace(source,
            @"^(\t*)\$""/root/Main""\.guillotine_essence_anim = 600\r?$",
            @"$1$""/root/Main"".guillotine_essence_anim = 600
$1if $""/root/Main"".has_method(""_bh_end_run""):
$1	$""/root/Main""._bh_end_run(""victory"")",
            RegexOptions.Multiline);

        return source;
    }
}
