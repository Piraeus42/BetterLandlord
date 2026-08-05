using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Fixes original symbol-resolution bugs in Slot Icon.tscn::1.
/// </summary>
public sealed class SymbolResolutionBugFixSourceMod : ISourceMod
{
    private const string SlotIconPath = "res://Slot Icon.tscn::1";

    public bool ShouldRun(string path) => path == SlotIconPath;

    public string Modify(string path, string source)
    {
        if (source.Contains("func _bl_snapshot_wildcard_value_before_destruction():", StringComparison.Ordinal))
            return source;

        var originalSource = source;
        var eol = GetPreferredEol(source);

        const string wildcardSnapshotOriginal = "\t\tvar p_obj = {\"type\": type, \"destroyed\": prev_destroyed_state, \"final_value\": get_value(\"coin\"),";
        const string wildcardSnapshotReplacement = "\t\t# A destroyed Wildcard becomes empty before Reels' final value pass.\n" +
                                                   "\t\t# Freeze its adjacent maximum while its original neighbours still exist.\n" +
                                                   "\t\tif being_destroyed and wildcarded:\n" +
                                                   "\t\t\t_bl_snapshot_wildcard_value_before_destruction()\n" +
                                                   "\t\tvar p_obj = {\"type\": type, \"destroyed\": prev_destroyed_state, \"final_value\": get_value(\"coin\"),";

        const string prevValueOriginal = "\tfor p in prev_data:\n\t\tvar p_value_bonus = 0";
        const string prevValueReplacement = "\tfor p in prev_data:\n" +
                                            "\t\t# Historical Wildcards use their frozen maximum, not the empty slot's value.\n" +
                                            "\t\tvar p_v_str = v_str\n" +
                                            "\t\tif currency == \"coin\" and p.wildcarded:\n" +
                                            "\t\t\tp_v_str = \"flat_value_bonus\"\n" +
                                            "\t\tvar p_value_bonus = 0";
        const string prevValueFormulaOriginal = "\t\tif (int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]) < 0:\n" +
                                                "\t\t\tprev_final_value += round((int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])))\n" +
                                                "\t\telse:\n" +
                                                "\t\t\tprev_final_value += round((int(p[v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]))";
        const string prevValueFormulaReplacement = "\t\tif (int(p[p_v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]) < 0:\n" +
                                                   "\t\t\tprev_final_value += round((int(p[p_v_str]) + int(p_value_bonus) + int(p[pb_str])))\n" +
                                                   "\t\telse:\n" +
                                                   "\t\t\tprev_final_value += round((int(p[p_v_str]) + int(p_value_bonus) + int(p[pb_str])) * float(p_value_multiplier) * float(p[pm_str]))";

        if (!InjectDoveNoDestroyerGrowth(ref source, eol) ||
            !ReplaceOnce(ref source, wildcardSnapshotOriginal, wildcardSnapshotReplacement, eol) ||
            !ReplaceOnceAfter(ref source, "func get_value(currency):", prevValueOriginal, prevValueReplacement, eol) ||
            !ReplaceOnceAfter(ref source, "func get_value(currency):", prevValueFormulaOriginal, prevValueFormulaReplacement, eol))
        {
            // A future game update moved an anchor: do not leave a partial script patch.
            return originalSource;
        }

        var helper = string.Join(eol, new[]
        {
            "func _bl_snapshot_wildcard_value_before_destruction():",
            "\tflat_value_bonus = 0",
            "\tfor adj_icon in get_adjacent_icons():",
            "\t\tvar adjacent_value = adj_icon.get_value(\"coin\")",
            "\t\tif adjacent_value > flat_value_bonus and not adj_icon.wildcarded:",
            "\t\t\tflat_value_bonus = adjacent_value"
        });
        return source + eol + helper + eol;
    }

    private static bool InjectDoveNoDestroyerGrowth(ref string source, string eol)
    {
        const string destroyerIf = "\t\t\t\t\t\t\tif destroyer != null:";
        const string adjacentDove = "\t\t\t\t\t\t\tadjacent_dove = true";

        var start = source.IndexOf(destroyerIf, StringComparison.Ordinal);
        if (start < 0)
            return false;

        var adjacent = source.IndexOf(adjacentDove, start, StringComparison.Ordinal);
        if (adjacent < 0)
            return false;

        var insertion = string.Join(eol, new[]
        {
            "\t\t\t\t\t\t\telse:",
            "\t\t\t\t\t\t\t\t# A source-less self-destruction stops before the native destroyed handler.",
            "\t\t\t\t\t\t\t\t# Recreate its native Dove event: mark the protected symbol, then hold the",
            "\t\t\t\t\t\t\t\t# growth effect on that symbol. Keeping it off Dove is essential: Dove's",
            "\t\t\t\t\t\t\t\t# current_effect_hashes intentionally deduplicate identical effects, while",
            "\t\t\t\t\t\t\t\t# each protected symbol must emit one independent growth event.",
            "\t\t\t\t\t\t\t\tcomparison_target.dove_destroyed = true",
            "\t\t\t\t\t\t\t\tcomparison_target.add_effect_to_symbol(comparison_target.grid_position.y, comparison_target.grid_position.x, {\"comparisons\": [{\"a\": \"dove_destroyed\", \"b\": true}], \"anim\": \"circle\", \"anim_targets\": [comparison_target, reels.displayed_icons[y][x]], \"sfx_override\": \"coo\", \"target\": reels.displayed_icons[y][x], \"value_to_change\": \"permanent_bonus\", \"diff\": reels.displayed_icons[y][x].values[0]})",
        }) + eol;

        // Insert at the beginning of the existing adjacent_dove line.
        // SlotWeave source mods can create mixed-EOL scripts; do not assume the
        // line ending before this anchor matches the file-wide dominant EOL.
        source = source.Insert(adjacent, insertion);
        return true;
    }

    private static string GetPreferredEol(string source)
    {
        var crlf = 0;
        var lfOnly = 0;
        for (var i = 0; i < source.Length; i++)
        {
            if (source[i] != '\n')
                continue;

            if (i > 0 && source[i - 1] == '\r')
                crlf++;
            else
                lfOnly++;
        }

        // Prefer the dominant style. This is important because another
        // ISourceMod may have appended/injected a small CRLF fragment into an
        // otherwise LF source before this mod runs.
        return crlf > lfOnly ? "\r\n" : "\n";
    }
    private static bool ReplaceOnce(ref string source, string original, string replacement, string eol)
    {
        original = original.Replace("\n", eol, StringComparison.Ordinal);
        replacement = replacement.Replace("\n", eol, StringComparison.Ordinal);
        var index = source.IndexOf(original, StringComparison.Ordinal);
        if (index < 0)
            return false;

        source = source[..index] + replacement + source[(index + original.Length)..];
        return true;
    }

    private static bool ReplaceOnceAfter(ref string source, string startMarker, string original, string replacement, string eol)
    {
        var start = source.IndexOf(startMarker, StringComparison.Ordinal);
        if (start < 0)
            return false;

        original = original.Replace("\n", eol, StringComparison.Ordinal);
        replacement = replacement.Replace("\n", eol, StringComparison.Ordinal);
        var index = source.IndexOf(original, start, StringComparison.Ordinal);
        if (index < 0)
            return false;

        source = source[..index] + replacement + source[(index + original.Length)..];
        return true;
    }
}
