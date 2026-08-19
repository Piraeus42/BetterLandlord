using System;
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Reuses one counted_symbols key snapshot for all scan, comparison, and commit
/// loops in one count_symbols() call. The snapshot is intentionally taken only
/// after Item callbacks finish, so dynamic Items retain their native behavior.
/// </summary>
public sealed class CountedSymbolsKeySnapshotSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::4";

    public string Modify(string path, string source)
    {
        if (path != "res://Main.tscn::4" || source.Contains("var counted_keys = counted_symbols.keys()", StringComparison.Ordinal))
            return source;

        var crlf = source.Contains("\r\n", StringComparison.Ordinal);
        var patched = source.Replace("\r\n", "\n", StringComparison.Ordinal);

        // Replace the existing loop expressions before adding the one retained
        // allocation, so the snapshot declaration itself is not rewritten.
        patched = ReplaceAllInFunction(
            patched,
            "count_symbols",
            "counted_symbols.keys()",
            "counted_keys",
            "count_symbols counted-symbol key reuse");
        patched = ReplaceOnce(
            patched,
            "\t\t$\"/root/Main/Reels\".counting_symbols = false\n\t\tvar temp_counts = {}",
            "\t\t$\"/root/Main/Reels\".counting_symbols = false\n\t\tvar counted_keys = counted_symbols.keys()\n\t\tvar temp_counts = {}",
            "count_symbols counted-symbol key snapshot");

        return crlf ? patched.Replace("\n", "\r\n", StringComparison.Ordinal) : patched;
    }

    private static string ReplaceAllInFunction(string source, string functionName, string oldValue, string newValue, string label)
    {
        var start = source.IndexOf($"func {functionName}(", StringComparison.Ordinal);
        if (start < 0)
            throw new InvalidOperationException($"Could not find {functionName} while applying {label}.");

        var end = source.IndexOf("\nfunc ", start + 1, StringComparison.Ordinal);
        if (end < 0)
            throw new InvalidOperationException($"Could not find the end of {functionName} while applying {label}.");

        var prefix = source[..start];
        var body = source[start..end];
        var suffix = source[end..];
        var count = CountOccurrences(body, oldValue);
        if (count == 0)
            throw new InvalidOperationException($"Could not find {label} in {functionName}.");

        return prefix + body.Replace(oldValue, newValue, StringComparison.Ordinal) + suffix;
    }

    private static string ReplaceOnce(string source, string oldValue, string newValue, string label)
    {
        var index = source.IndexOf(oldValue, StringComparison.Ordinal);
        if (index < 0)
            throw new InvalidOperationException($"Could not find {label}.");
        if (source.IndexOf(oldValue, index + oldValue.Length, StringComparison.Ordinal) >= 0)
            throw new InvalidOperationException($"Found multiple {label} anchors.");

        return source[..index] + newValue + source[(index + oldValue.Length)..];
    }

    private static int CountOccurrences(string value, string needle)
    {
        var count = 0;
        var start = 0;
        while (true)
        {
            var index = value.IndexOf(needle, start, StringComparison.Ordinal);
            if (index < 0)
                return count;
            count++;
            start = index + needle.Length;
        }
    }
}
