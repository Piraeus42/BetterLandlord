using Piraeus.BetterLandlord.Patches;
using Xunit;

namespace Piraeus.BetterLandlord.Tests;

public class ChoiceCardReuseSourceModTests
{
    [Fact]
    public void MainPreservesActiveChoiceCardsWhenReturningToTitleForContinue()
    {
        const string source = """
            func title():
            	load_data(true, false, true)

            func reset_values():
            	popup.undraw_deck()
            """;

        var modified = new ChoiceCardReuseSourceMod().Modify("res://Main.tscn::1", source);

        Assert.Contains(
            "_bl_preload_choice_cards(loading_without_quitting)",
            modified,
            StringComparison.Ordinal);
        Assert.Matches(
            @"popup\._bl_release_choice_cards\(\)[\r\n]+\tpopup\.undraw_deck\(\)",
            modified);
    }

    [Fact]
    public void PreloaderAcceptsOneShotActiveCardPreservation()
    {
        var source = File.ReadAllText(
            Path.GetFullPath(
                Path.Combine(AppContext.BaseDirectory, "../../../..", "game_source_code", "Pop-up.tscn__1.gd")));

        var modified = new ChoiceCardReuseSourceMod().Modify("res://Pop-up.tscn::1", source);

        Assert.Matches(
            @"func _bl_preload_choice_cards\(preserve_active_cards\s*=\s*false\):",
            modified);
        Assert.Matches(@"\tif preserve_active_cards:[\r\n]+\t\treturn", modified);
    }
}
