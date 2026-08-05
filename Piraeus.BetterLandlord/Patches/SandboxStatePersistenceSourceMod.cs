using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Makes the built-in Sandbox behave like a normal continuing run after its
/// initial board has been loaded. The original game reconstructs the board
/// after resolving every choice event, which discards all runtime symbol data
/// (including permanent bonuses). Returning to the title menu still performs
/// the game's normal reset and reloads the Sandbox save on the next run.
/// </summary>
public sealed class SandboxStatePersistenceSourceMod : ISourceMod
{
    private const string PopupPath = "res://Pop-up.tscn::1";
    private const string Marker = "# BetterLandlord: preserve Sandbox runtime state";

    public bool ShouldRun(string path) => path == PopupPath;

    public string Modify(string path, string source)
    {
        if (source.Contains(Marker, StringComparison.Ordinal))
            return source;

        var originalSource = source;
        var eol = source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";

        const string forcedReloadCondition =
            "\t\t\t\tif $\"/root/Main\".sandbox_mode and current_modded_floor == null:";
        var forcedReloadReplacement = string.Join(eol, new[]
        {
            "\t\t\t\t# BetterLandlord: preserve Sandbox runtime state after choices.",
            "\t\t\t\t# The default branch reloads the save and recreates every symbol.",
            "\t\t\t\tif false:"
        });

        const string postChoiceReloadCondition =
            "\tif $\"/root/Main\".sandbox_mode and (prev_email_type == \"add_tile\" or prev_email_type == \"add_item\" or prev_email_type == \"add_tile_prompt\") and emails.size() == 0 and current_modded_floor == null:";
        var postChoiceReloadReplacement = string.Join(eol, new[]
        {
            "\t# BetterLandlord: preserve Sandbox runtime state",
            "\t# Do not recreate Reel icons after a choice has resolved.",
            "\tif false:"
        });

        if (!ReplaceOnce(ref source, forcedReloadCondition, forcedReloadReplacement) ||
            !ReplaceOnce(ref source, postChoiceReloadCondition, postChoiceReloadReplacement))
        {
            // A future game update moved an anchor: keep the original script intact.
            return originalSource;
        }

        return source;
    }

    private static bool ReplaceOnce(ref string source, string original, string replacement)
    {
        var index = source.IndexOf(original, StringComparison.Ordinal);
        if (index < 0)
            return false;

        source = source[..index] + replacement + source[(index + original.Length)..];
        return true;
    }
}
