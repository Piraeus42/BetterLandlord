using System.Collections.Generic;
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
        const string wildcardHelperMarker = "func _bl_snapshot_wildcard_value_before_destruction():";

        var originalSource = source;
        var eol = GetPreferredEol(source);

        // Cached SlotWeave sources can contain an earlier BetterLandlord Dove
        // implementation. Remove only our known lifecycle/diagnostic fragments,
        // then rebuild the Dove path from a single, explicit source lifetime.
        if (!RemoveLegacyDoveComparisonInjection(ref source) ||
            !RemoveDoveProtectionTrace(ref source) ||
            !RemoveOldDoveLifecycleHelpers(ref source) ||
            !DisableNativeDoveComparisonGrowth(ref source, eol) ||
            !DisableNativeDoveTargetComparisonGrowth(ref source, eol) ||
            !InjectDoveProtectionSourceRecord(ref source, eol) ||
            !InjectDoveProtectionCommitGrowth(ref source, eol))
            return originalSource;

        var hasWildcardHelper = source.Contains(wildcardHelperMarker, StringComparison.Ordinal);

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

        if ((!hasWildcardHelper && !ReplaceOnce(ref source, wildcardSnapshotOriginal, wildcardSnapshotReplacement, eol)) ||
            (!hasWildcardHelper && !ReplaceOnceAfter(ref source, "func get_value(currency):", prevValueOriginal, prevValueReplacement, eol)) ||
            (!hasWildcardHelper && !ReplaceOnceAfter(ref source, "func get_value(currency):", prevValueFormulaOriginal, prevValueFormulaReplacement, eol)))
        {
            // A future game update moved an anchor: do not leave a partial script patch.
            return originalSource;
        }

        var helpers = new List<string>();
        if (!hasWildcardHelper)
        {
            helpers.Add(string.Join(eol, new[]
            {
                "func _bl_snapshot_wildcard_value_before_destruction():",
                "\tflat_value_bonus = 0",
                "\tfor adj_icon in get_adjacent_icons():",
                "\t\tvar adjacent_value = adj_icon.get_value(\"coin\")",
                "\t\tif adjacent_value > flat_value_bonus and not adj_icon.wildcarded:",
                "\t\t\tflat_value_bonus = adjacent_value"
            }));
        }
        helpers.Add(BuildDoveProtectionHelpers(eol));

        return source + eol + string.Join(eol + eol, helpers) + eol;
    }

    private static bool InjectDoveProtectionSourceRecord(ref string source, string eol)
    {
        const string original = "\tif typeof(target) == TYPE_OBJECT and target.has_method(\"get_value\"):\n" +
                                "\t\ttarget.current_effect = c.duplicate(true)";
        const string replacement = "\tif typeof(target) == TYPE_OBJECT and target.has_method(\"get_value\"):\n" +
                                   "\t\ttarget.current_effect = c.duplicate(true)\n" +
                                   "\t\t_bl_record_dove_protection_source(c, target)";
        const string recordCall = "_bl_record_dove_protection_source(c, target)";

        var doDiffStart = source.IndexOf("func do_diff(c, target, c_tbe):", StringComparison.Ordinal);
        if (doDiffStart < 0)
            return false;
        var doDiffEnd = source.IndexOf("\nfunc ", doDiffStart + 1, StringComparison.Ordinal);
        if (doDiffEnd < 0)
            doDiffEnd = source.Length;

        var recordCalls = CountOccurrences(source, recordCall, doDiffStart, doDiffEnd);
        if (recordCalls > 1)
            return false;
        if (recordCalls == 1)
            return true;

        if (!ReplaceOnceAfter(ref source, "func do_diff(c, target, c_tbe):", original, replacement, eol))
            return false;

        doDiffEnd = source.IndexOf("\nfunc ", doDiffStart + 1, StringComparison.Ordinal);
        if (doDiffEnd < 0)
            doDiffEnd = source.Length;
        return CountOccurrences(source, recordCall, doDiffStart, doDiffEnd) == 1;
    }

    private static bool InjectDoveProtectionCommitGrowth(ref string source, string eol)
    {
        const string firstGuardOriginal = "\t\t\t\tif target.indestructible:\n" +
                                          "\t\t\t\t\ttarget.dove_destroyed = true\n" +
                                          "\t\t\t\t\tcheck_item_triggers(c, target)";
        const string firstGuardReplacement = "\t\t\t\tif target.indestructible:\n" +
                                             "\t\t\t\t\ttarget.dove_destroyed = true\n" +
                                             "\t\t\t\t\t_bl_queue_dove_protection_growth(c, target)\n" +
                                             "\t\t\t\t\tcheck_item_triggers(c, target)";
        const string secondGuardOriginal = "\t\t\t\t\tif target.indestructible:\n" +
                                           "\t\t\t\t\t\ttarget.dove_destroyed = true\n" +
                                           "\t\t\t\t\t\tcheck_item_triggers(c, target)";
        const string secondGuardReplacement = "\t\t\t\t\tif target.indestructible:\n" +
                                              "\t\t\t\t\t\ttarget.dove_destroyed = true\n" +
                                              "\t\t\t\t\t\t_bl_queue_dove_protection_growth(c, target)\n" +
                                              "\t\t\t\t\t\tcheck_item_triggers(c, target)";
        const string commitCall = "_bl_queue_dove_protection_growth(c, target)";

        // do_diff has two native indestructible guards: one before, and one after,
        // target-TBD scheduling. Each is a mutually exclusive real destruction
        // commit point. Keep both covered, including when a cached source was only
        // partially patched by an earlier mod version.
        var doDiffStart = source.IndexOf("func do_diff(c, target, c_tbe):", StringComparison.Ordinal);
        if (doDiffStart < 0)
            return false;
        var doDiffEnd = source.IndexOf("\nfunc ", doDiffStart + 1, StringComparison.Ordinal);
        if (doDiffEnd < 0)
            doDiffEnd = source.Length;

        var commitCalls = CountOccurrences(source, commitCall, doDiffStart, doDiffEnd);
        if (commitCalls > 2)
            return false;

        if (!ReplaceOnceAfter(ref source, "func do_diff(c, target, c_tbe):", firstGuardOriginal, firstGuardReplacement, eol) &&
            CountOccurrences(source, commitCall, doDiffStart, doDiffEnd) == 0)
            return false;

        if (!ReplaceOnceAfter(ref source, "func do_diff(c, target, c_tbe):", secondGuardOriginal, secondGuardReplacement, eol) &&
            CountOccurrences(source, commitCall, doDiffStart, doDiffEnd) < 2)
            return false;

        doDiffEnd = source.IndexOf("\nfunc ", doDiffStart + 1, StringComparison.Ordinal);
        if (doDiffEnd < 0)
            doDiffEnd = source.Length;
        return CountOccurrences(source, commitCall, doDiffStart, doDiffEnd) == 2;
    }

    private static bool DisableNativeDoveComparisonGrowth(ref string source, string eol)
    {
        const string marker = "# BetterLandlord: Dove growth is committed in do_diff, never during comparison.";
        if (source.Contains(marker, StringComparison.Ordinal))
            return true;

        const string original = "\t\t\t\t\t\t\tif destroyer != null:\n" +
                                "\t\t\t\t\t\t\t\tdestroyer.add_effect({\"comparisons\": [{\"a\": \"destroyed_giver_on_destroy\", \"b\": true}], \"anim\": \"circle\", \"anim_targets\": [destroyer, reels.displayed_icons[y][x]], \"sfx_override\": \"coo\", \"target\": reels.displayed_icons[y][x], \"value_to_change\": \"permanent_bonus\", \"diff\": reels.displayed_icons[y][x].values[0], \"one_time\": true, \"t_pdi\": destroyer.t_index})";
        const string replacement = "\t\t\t\t\t\t\tif destroyer != null:\n" +
                                   "\t\t\t\t\t\t\t\t# BetterLandlord: Dove growth is committed in do_diff, never during comparison.\n" +
                                   "\t\t\t\t\t\t\t\tpass";

        return ReplaceOnceAfter(ref source, "func do_comp(comparison, c, target, c_effects, c_tbe):", original, replacement, eol);
    }

    private static bool DisableNativeDoveTargetComparisonGrowth(ref string source, string eol)
    {
        const string marker = "# BetterLandlord: target-side Dove growth is committed in do_diff, never during comparison.";
        if (source.Contains(marker, StringComparison.Ordinal))
            return true;

        const string original = "\t\tvar tmp_adj_icons = get_adjacent_icons()\n" +
                                "\t\tfor x in range(reels.reel_width):\n" +
                                "\t\t\tfor y in range(reels.reel_height):\n" +
                                "\t\t\t\tif reels.displayed_icons[y][x].type == \"dove\" and tmp_adj_icons.has(reels.displayed_icons[y][x]):\n" +
                                "\t\t\t\t\tadd_effect_to_symbol(grid_position.y, grid_position.x, {\"comparisons\": [{\"a\": \"dove_destroyed\", \"b\": true}], \"anim\": \"circle\", \"anim_targets\": [self, reels.displayed_icons[y][x]], \"sfx_override\": \"coo\", \"target\": reels.displayed_icons[y][x], \"value_to_change\": \"permanent_bonus\", \"diff\": reels.displayed_icons[y][x].values[0]})";
        const string replacement = "\t\t# BetterLandlord: target-side Dove growth is committed in do_diff, never during comparison.";

        return ReplaceOnceAfter(ref source, "func do_comp(comparison, c, target, c_effects, c_tbe):", original, replacement, eol);
    }

    private static bool RemoveLegacyDoveComparisonInjection(ref string source)
    {
        const string legacyComment = "# A source-less self-destruction stops before the native destroyed handler.";
        var commentIndex = source.IndexOf(legacyComment, StringComparison.Ordinal);
        if (commentIndex < 0)
            return true;

        var legacyElse = "\t\t\t\t\t\t\telse:";
        var start = source.LastIndexOf(legacyElse, commentIndex, StringComparison.Ordinal);
        var endAnchor = "\t\t\t\t\t\t\tadjacent_dove = true";
        var end = source.IndexOf(endAnchor, commentIndex, StringComparison.Ordinal);
        if (start < 0 || end < 0 || start >= end)
            return false;

        source = source.Remove(start, end - start);
        return true;
    }

    private static bool RemoveDoveProtectionTrace(ref string source)
    {
        // SlotWeave wraps injected lines with provenance comments in cached scripts,
        // so removing the old diagnostic by its original multi-line text is not
        // reliable. Remove the diagnostics as their small injected line blocks.
        return RemoveDoveTraceBlock(ref source, "# BetterLandlord diagnostic: Dove protection-growth trace.", 3) &&
               RemoveDoveTraceBlock(ref source, "\t\tif c.has(\"_bl_dove_protection_event\"):", 2);
    }

    private static bool RemoveDoveTraceBlock(ref string source, string firstLine, int lineCount)
    {
        while (true)
        {
            var first = source.IndexOf(firstLine, StringComparison.Ordinal);
            if (first < 0)
                return true;

            var start = source.LastIndexOf('\n', first);
            start = start < 0 ? 0 : start + 1;
            var previousLineStart = start > 0 ? source.LastIndexOf('\n', start - 2) + 1 : -1;
            if (previousLineStart >= 0 && source.AsSpan(previousLineStart, start - previousLineStart).Contains("[SymbolResolutionBugFixSourceMod]", StringComparison.Ordinal))
                start = previousLineStart;

            var end = source.IndexOf('\n', first);
            if (end < 0)
                end = source.Length;
            else
                end++;
            for (var i = 1; i < lineCount && end < source.Length; i++)
            {
                end = source.IndexOf('\n', end);
                if (end < 0)
                {
                    end = source.Length;
                    break;
                }
                end++;
            }

            source = source.Remove(start, end - start);
        }
    }
    private static bool RemoveOldDoveLifecycleHelpers(ref string source)
    {
        return RemoveFunctionWithLeadingMarker(ref source,
                   "# BetterLandlord: a Dove growth event is created only after do_diff commits a real protected destruction attempt.",
                   "func _bl_queue_dove_protection_growth(c, protected_target):") &&
               RemoveFunctionWithLeadingMarker(ref source,
                   "# BetterLandlord: Dove protection sources are recorded when indestructible is applied.",
                   "func _bl_record_dove_protection_source(c, protected_target):") &&
               RemoveFunctionWithLeadingMarker(ref source,
                   "# BetterLandlord: Dove protection sources are recorded when indestructible is applied.",
                   "func _bl_queue_dove_protection_growth(c, protected_target):");
    }

    private static bool RemoveFunctionWithLeadingMarker(ref string source, string marker, string declaration)
    {
        while (true)
        {
            var functionStart = source.IndexOf(declaration, StringComparison.Ordinal);
            if (functionStart < 0)
                return true;

            var markerStart = source.LastIndexOf(marker, functionStart, StringComparison.Ordinal);
            var removalStart = markerStart >= 0 ? markerStart : functionStart;
            var functionEnd = source.IndexOf("\nfunc ", functionStart + declaration.Length, StringComparison.Ordinal);
            if (functionEnd < 0)
            {
                source = source[..removalStart];
                return true;
            }

            source = source.Remove(removalStart, functionEnd - removalStart);
        }
    }

    private static string BuildDoveProtectionHelpers(string eol)
    {
        return string.Join(eol, new[]
        {
            "# BetterLandlord: Dove protection sources are recorded when indestructible is applied.",
            "func _bl_record_dove_protection_source(c, protected_target):",
            "\tif typeof(protected_target) != TYPE_OBJECT or not protected_target.has_method(\"get_adjacent_icons\"):",
            "\t\treturn",
            "\tif not c.has(\"value_to_change\") or c.value_to_change != \"indestructible\":",
            "\t\treturn",
            "\tif not c.has(\"giver\") or typeof(c.giver) != TYPE_OBJECT:",
            "\t\treturn",
            "\tvar dove = c.giver",
            "\tif not is_instance_valid(dove) or dove.type != \"dove\" or not dove.has_method(\"get_adjacent_icons\"):",
            "\t\treturn",
            "\tif not dove.get_adjacent_icons().has(protected_target):",
            "\t\treturn",
            "\tvar sources = []",
            "\tif protected_target.has_meta(\"_bl_dove_protection_sources\"):",
            "\t\tsources = protected_target.get_meta(\"_bl_dove_protection_sources\")",
            "\tif typeof(sources) != TYPE_ARRAY:",
            "\t\tsources = []",
            "\tif not sources.has(dove):",
            "\t\tsources.push_back(dove)",
            "\tprotected_target.set_meta(\"_bl_dove_protection_sources\", sources)",
            "",
            "func _bl_queue_dove_protection_growth(c, protected_target):",
            "\tif typeof(protected_target) != TYPE_OBJECT or not protected_target.has_meta(\"_bl_dove_protection_sources\"):",
            "\t\treturn",
            "\t# Resolver passes can revisit one protected target during the same spin.",
            "\t# Once committed, this target cannot grow Dove protection again until the next spin.",
            "\tif protected_target.has_meta(\"_bl_dove_protection_committed\") and protected_target.get_meta(\"_bl_dove_protection_committed\"):",
            "\t\treturn",
            "\tvar sources = protected_target.get_meta(\"_bl_dove_protection_sources\")",
            "\tif typeof(sources) != TYPE_ARRAY:",
            "\t\treturn",
            "\tvar emitted_doves = []",
            "\tfor dove in sources:",
            "\t\tif typeof(dove) != TYPE_OBJECT or not is_instance_valid(dove):",
            "\t\t\tcontinue",
            "\t\tif dove.type != \"dove\" or not dove.has_method(\"get_adjacent_icons\"):",
            "\t\t\tcontinue",
            "\t\tif emitted_doves.has(dove) or not dove.get_adjacent_icons().has(protected_target):",
            "\t\t\tcontinue",
            "\t\temitted_doves.push_back(dove)",
            "\t\tprotected_target.set_meta(\"_bl_dove_protection_committed\", true)",
            "\t\tvar event_seq = 1",
            "\t\tif dove.has_meta(\"_bl_dove_protection_event_seq\"):",
            "\t\t\tevent_seq = int(dove.get_meta(\"_bl_dove_protection_event_seq\")) + 1",
            "\t\tdove.set_meta(\"_bl_dove_protection_event_seq\", event_seq)",
            "\t\tvar event_id = str(dove.get_instance_id()) + \":\" + str(event_seq)",
            "\t\tdove.add_effect({\"comparisons\": [{\"a\": \"type\", \"b\": \"dove\"}], \"anim\": \"circle\", \"anim_targets\": [protected_target, dove], \"sfx_override\": \"coo\", \"target\": dove, \"value_to_change\": \"permanent_bonus\", \"diff\": dove.values[0], \"one_time\": true, \"no_extra_targets\": true, \"_bl_dove_protection_event\": event_id})",
            "\t\treels.add_symbol_position_to_update(dove.grid_position)",
            "\t\treels.dove_prevention = true"
        });
    }

    private static int CountOccurrences(string source, string value, int start, int end)
    {
        var count = 0;
        var position = start;
        while (true)
        {
            position = source.IndexOf(value, position, StringComparison.Ordinal);
            if (position < 0 || position >= end)
                return count;
            count++;
            position += value.Length;
        }
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
