using System.Text.RegularExpressions;
using GDWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Injects seed guards into native stat/achievement functions on Stats.tscn::1.
/// Custom-seeded runs are excluded from:
///   - add_stat()              — per-stat counters (guillotine, executions, etc.)
///   - add_to_games_played()   — games played / win-rate tracking
///   - unlock_achievement()    — Steam achievement unlocks
///
/// Guards are early returns inserted right after each function signature,
/// before any existing logic.  Uses has_method() for safety (no-op if the
/// mod is unloaded).
/// </summary>
public class SeededStatsSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Stats.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("_bh_is_seeded")) return source;

        var guard = @"
	if $""/root/Main"".has_method(""_bh_is_seeded"") and $""/root/Main""._bh_is_seeded():
		return";

        // All three functions get the same early-return guard after the
        // function signature, before the first body statement.

        source = Regex.Replace(source,
            @"^(func add_stat\(.*\):)\r?$",
            @"$1" + guard,
            RegexOptions.Multiline);

        source = Regex.Replace(source,
            @"^(func add_to_games_played\(.*\):)\r?$",
            @"$1" + guard,
            RegexOptions.Multiline);

        source = Regex.Replace(source,
            @"^(func unlock_achievement\(.*\):)\r?$",
            @"$1" + guard,
            RegexOptions.Multiline);

        return source;
    }
}
