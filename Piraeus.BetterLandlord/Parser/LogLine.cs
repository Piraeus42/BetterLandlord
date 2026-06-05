using System.Text.RegularExpressions;

namespace Piraeus.BetterLandlord.Parser;

public readonly struct LogLine
{
    public readonly string Timestamp;
    public readonly string Content;

    private static readonly Regex TimestampPattern = new(
        @"^\[(\d+/\d+/\d{4}\s+\d{2}:\d{2}:\d{2})\]\s+(.*)$",
        RegexOptions.Compiled);

    public LogLine(string raw)
    {
        var m = TimestampPattern.Match(raw);
        if (m.Success)
        {
            Timestamp = m.Groups[1].Value;
            Content = m.Groups[2].Value;
        }
        else
        {
            Timestamp = "";
            Content = raw;
        }
    }

    public static LogLine FromRaw(string raw) => new(raw);

    public bool IsValid => !string.IsNullOrEmpty(Timestamp);

    public static bool TryParse(string raw, out LogLine result)
    {
        result = new LogLine(raw);
        return result.IsValid;
    }
}
