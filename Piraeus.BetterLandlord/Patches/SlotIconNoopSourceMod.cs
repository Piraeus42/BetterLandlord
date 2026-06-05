using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Minimal crash reproducer: appends ONE noop function to Slot Icon.tscn::1.
/// Append-at-end, no regex, no /root/Main references, no GdscriptUtil.Tabify.
/// Identical approach to the standalone repro that doesn't crash.
/// </summary>
public class SlotIconNoopSourceMod : ISourceMod
{
    public bool ShouldRun(string path) =>
        path == "res://Slot Icon.tscn::1";

    public string Modify(string path, string source) =>
        source + "\nfunc _bh_noop():\n\tpass\n";
}
