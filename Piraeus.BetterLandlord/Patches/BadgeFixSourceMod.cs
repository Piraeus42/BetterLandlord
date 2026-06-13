using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Fixes stale displayed_multiplier_value in update_value_text().
/// Clears the instance variable when permanent_multiplier == 1,
/// matching the existing behavior of displayed_text_value and
/// displayed_bonus_value which ARE properly cleared.
/// </summary>
public class BadgeFixSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Slot Icon.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("displayed_multiplier_value = \"\"  # BH-FIX")) return source;

        // Inject the clearance line after the else branch of permanent_multiplier == 1.
        // The original clears get_child(2).raw_string but leaves displayed_multiplier_value stale.
        // This post-injection adds the missing clearance — the line only executes when
        // permanent_multiplier == 1, which is the "no multiplier" state.
        source = source.Replace(
            "\telse:\n\t\tget_child(2).raw_string = \"\"",
            "\telse:\n\t\tget_child(2).raw_string = \"\"\n\t\tdisplayed_multiplier_value = \"\"  # BH-FIX: clear stale multiplier");

        return source;
    }
}
