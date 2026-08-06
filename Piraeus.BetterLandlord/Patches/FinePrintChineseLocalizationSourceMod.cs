using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Corrects the base-game Simplified Chinese text for Fine Print 37.
/// The original zh translation mistakenly duplicates Fine Print 18's Guillotine text.
/// </summary>
public sealed class FinePrintChineseLocalizationSourceMod : ISourceMod
{
    private const string TargetPath = "res://Landlord.tscn::9";
    private const string Marker = "func _bl_fix_fine_print_37_zh():";
    private const string ReadyAnchor = "\tinit_fine_print()";

    public bool ShouldRun(string path) => path == TargetPath;

    public string Modify(string path, string source)
    {
        if (source.Contains(Marker, StringComparison.Ordinal))
            return source;

        var anchorIndex = source.IndexOf(ReadyAnchor, StringComparison.Ordinal);
        if (anchorIndex < 0)
            throw new InvalidOperationException("Fine Print zh localization patch anchor was not found.");

        var replacement = ReadyAnchor + "\n\t_bl_fix_fine_print_37_zh()";
        source = source[..anchorIndex] + replacement + source[(anchorIndex + ReadyAnchor.Length)..];

        return source + "\n" + @"
func _bl_fix_fine_print_37_zh():
	if not $""/root/Main"".fine_print_database.has(""37""):
		return
	var fine_print = $""/root/Main"".fine_print_database[""37""]
	if not fine_print.has(""localized_text""):
		fine_print[""localized_text""] = {}
	fine_print[""localized_text""][""zh""] = ""<dynamic_capsule>没有效果。""
	$""/root/Main"".fine_print_database[""37""] = fine_print
";
    }
}
