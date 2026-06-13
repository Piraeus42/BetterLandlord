using System.Text.RegularExpressions;
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Captures player-selected removal-token targets from Hover Icon.press().
/// Game-wide removed_symbol_types also includes item/effect removals, so history
/// needs a narrower event emitted only from the manual removal flow.
/// </summary>
public class HoverIconRemovalSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Hover Icon.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("\"source\": \"removal_token\"")) return source;

        return Regex.Replace(
            source,
            @"^(\t*)popup\.removed_symbol_types\.push_back\(p_type\)\r?$",
            @"$1popup.removed_symbol_types.push_back(p_type)
$1if main.has_method(""_bh_add_event""):
$1	main._bh_add_event(""symbol_removed"", {""symbol"": p_type, ""source"": ""removal_token"", ""badge_text"": vt, ""badge_bonus"": pb, ""badge_mult"": pm})",
            RegexOptions.Multiline);
    }
}
