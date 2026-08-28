using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Injects a call into Slot Icon.tscn::1 so that successful item_to_destroy
/// resolutions are recorded immediately at the authoritative branch.
/// The later native Item.destroy() log is deduplicated by WriteLogPatch.
/// </summary>
public sealed class ItemEffectConsumptionSourceMod : ISourceMod
{
    private const string TargetPath = "res://Slot Icon.tscn::1";
    private const string Marker = "# BH: record successful item_to_destroy consumption";
    private const string Anchor = "\t\t\t\ti.destroyed = true";

    public bool ShouldRun(string path) => path == TargetPath;

    public string Modify(string path, string source)
    {
        if (source.Contains(Marker, System.StringComparison.Ordinal)) return source;
        var index = source.IndexOf(Anchor, System.StringComparison.Ordinal);
        if (index < 0) return source;
        var eol = source.Contains("\r\n", System.StringComparison.Ordinal) ? "\r\n" : "\n";
        var injected = string.Join(eol, new[]
        {
            Anchor,
            "\t\t\t\t" + Marker,
            "\t\t\t\tif \"/root/Main\".has_method(\"_bh_record_effect_item_consumed\"): ",
            "\t\t\t\t\"/root/Main\"._bh_record_effect_item_consumed(i.type)"
        });
        return source[..index] + injected + source[(index + Anchor.Length)..];
    }
}