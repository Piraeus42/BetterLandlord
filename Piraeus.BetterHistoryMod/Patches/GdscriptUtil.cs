namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Converts space-indented GDScript to tab-indented (Godot 3 convention).
/// The game uses tabs; our C# raw string literals use 4-space indentation.
/// </summary>
public static class GdscriptUtil
{
    /// <summary>Convert 4-space indent to tabs. For script-level (column 0) code.</summary>
    public static string Tabify(string gdscript)
    {
        var lines = gdscript.Replace("\r\n", "\n").Split('\n');
        for (int i = 0; i < lines.Length; i++)
            lines[i] = ConvertLine(lines[i]);
        return string.Join("\n", lines);
    }

    /// <summary>Convert 4-space indent to tabs, then add one extra tab level (for Prefix/Postfix).</summary>
    public static string TabifyIndent(string gdscript)
    {
        var lines = gdscript.Replace("\r\n", "\n").Split('\n');
        for (int i = 0; i < lines.Length; i++)
        {
            var converted = ConvertLine(lines[i]);
            lines[i] = string.IsNullOrEmpty(converted) ? "" : "\t" + converted;
        }
        return string.Join("\n", lines);
    }

    private static string ConvertLine(string line)
    {
        int spaces = 0;
        while (spaces < line.Length && line[spaces] == ' ')
            spaces++;
        if (spaces == 0) return line;
        int tabs = spaces / 4;
        return new string('\t', tabs) + line[spaces..];
    }
}
