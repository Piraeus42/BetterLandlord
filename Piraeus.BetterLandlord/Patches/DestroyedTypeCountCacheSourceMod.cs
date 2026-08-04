using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Replaces repeated linear Array.count() calls for persistent destroyed/removed
/// types with owner-local dictionaries. Arrays remain the authoritative saved
/// representation; cache dictionaries rebuild only when their source size
/// changes or the save/reset hooks explicitly invalidate them.
/// </summary>
public class DestroyedTypeCountCacheSourceMod : ISourceMod
{
    private const string PopupPath = "res://Pop-up.tscn::1";
    private const string ItemsPath = "res://Items.tscn::1";

    public bool ShouldRun(string path) => path is PopupPath or ItemsPath
        or "res://Item.tscn::1" or "res://Slot Icon.tscn::1" or "res://Main.tscn::4";

    public string Modify(string path, string source)
    {
        return path switch
        {
            PopupPath => AddPopupCache(source),
            ItemsPath => AddItemsCache(source),
            _ => ReplaceCountCalls(source)
        };
    }

    private static string AddPopupCache(string source)
    {
        if (source.Contains("func _bh_count_destroyed_symbol_type(", StringComparison.Ordinal))
            return source;

        var eol = GetEol(source);
        const string variableAnchor = "var removed_symbol_types = []";
        const string variables = """
            var _bh_destroyed_symbol_type_counts = {}
            var _bh_destroyed_symbol_type_count_cache_size = -1
            var _bh_removed_symbol_type_counts = {}
            var _bh_removed_symbol_type_count_cache_size = -1
            """;
        var variableIndex = source.IndexOf(variableAnchor, StringComparison.Ordinal);
        if (variableIndex < 0)
            return source;

        var insertionIndex = variableIndex + variableAnchor.Length;
        source = source[..insertionIndex] + eol + variables.Replace("\n", eol, StringComparison.Ordinal).TrimEnd('\r', '\n') + source[insertionIndex..];

        var functions = string.Join(eol, new[]
        {
            "",
            "func _bh_invalidate_destroyed_type_count_caches():",
            "\t_bh_destroyed_symbol_type_counts.clear()",
            "\t_bh_destroyed_symbol_type_count_cache_size = -1",
            "\t_bh_removed_symbol_type_counts.clear()",
            "\t_bh_removed_symbol_type_count_cache_size = -1",
            "",
            "func _bh_count_destroyed_symbol_type(p_type):",
            "\tif _bh_destroyed_symbol_type_count_cache_size != destroyed_symbol_types.size():",
            "\t\t_bh_destroyed_symbol_type_counts.clear()",
            "\t\tfor cached_type in destroyed_symbol_types:",
            "\t\t\t_bh_destroyed_symbol_type_counts[cached_type] = int(_bh_destroyed_symbol_type_counts.get(cached_type, 0)) + 1",
            "\t\t_bh_destroyed_symbol_type_count_cache_size = destroyed_symbol_types.size()",
            "\treturn int(_bh_destroyed_symbol_type_counts.get(p_type, 0))",
            "",
            "func _bh_count_removed_symbol_type(p_type):",
            "\tif _bh_removed_symbol_type_count_cache_size != removed_symbol_types.size():",
            "\t\t_bh_removed_symbol_type_counts.clear()",
            "\t\tfor cached_type in removed_symbol_types:",
            "\t\t\t_bh_removed_symbol_type_counts[cached_type] = int(_bh_removed_symbol_type_counts.get(cached_type, 0)) + 1",
            "\t\t_bh_removed_symbol_type_count_cache_size = removed_symbol_types.size()",
            "\treturn int(_bh_removed_symbol_type_counts.get(p_type, 0))"
        });
        return source + functions + eol;
    }

    private static string AddItemsCache(string source)
    {
        if (source.Contains("func _bh_count_destroyed_item_type(", StringComparison.Ordinal))
            return source;

        var eol = GetEol(source);
        const string variableAnchor = "var destroyed_item_types = []";
        const string variables = """
            var _bh_destroyed_item_type_counts = {}
            var _bh_destroyed_item_type_count_cache_size = -1
            """;
        var variableIndex = source.IndexOf(variableAnchor, StringComparison.Ordinal);
        if (variableIndex < 0)
            return source;

        var insertionIndex = variableIndex + variableAnchor.Length;
        source = source[..insertionIndex] + eol + variables.Replace("\n", eol, StringComparison.Ordinal).TrimEnd('\r', '\n') + source[insertionIndex..];

        var functions = string.Join(eol, new[]
        {
            "",
            "func _bh_invalidate_destroyed_item_type_count_cache():",
            "\t_bh_destroyed_item_type_counts.clear()",
            "\t_bh_destroyed_item_type_count_cache_size = -1",
            "",
            "func _bh_count_destroyed_item_type(p_type):",
            "\tif _bh_destroyed_item_type_count_cache_size != destroyed_item_types.size():",
            "\t\t_bh_destroyed_item_type_counts.clear()",
            "\t\tfor cached_type in destroyed_item_types:",
            "\t\t\t_bh_destroyed_item_type_counts[cached_type] = int(_bh_destroyed_item_type_counts.get(cached_type, 0)) + 1",
            "\t\t_bh_destroyed_item_type_count_cache_size = destroyed_item_types.size()",
            "\treturn int(_bh_destroyed_item_type_counts.get(p_type, 0))"
        });
        return source + functions + eol;
    }

    private static string ReplaceCountCalls(string source)
    {
        return source
            .Replace("$\"/root/Main/Pop-up Sprite/Pop-up\".destroyed_symbol_types.count(", "$\"/root/Main/Pop-up Sprite/Pop-up\"._bh_count_destroyed_symbol_type(", StringComparison.Ordinal)
            .Replace("popup.destroyed_symbol_types.count(", "popup._bh_count_destroyed_symbol_type(", StringComparison.Ordinal)
            .Replace("$\"/root/Main/Pop-up Sprite/Pop-up\".removed_symbol_types.count(", "$\"/root/Main/Pop-up Sprite/Pop-up\"._bh_count_removed_symbol_type(", StringComparison.Ordinal)
            .Replace("get_parent().destroyed_item_types.count(", "get_parent()._bh_count_destroyed_item_type(", StringComparison.Ordinal)
            .Replace("$\"/root/Main/Items\".destroyed_item_types.count(", "$\"/root/Main/Items\"._bh_count_destroyed_item_type(", StringComparison.Ordinal);
    }

    private static string GetEol(string source) => source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
}
