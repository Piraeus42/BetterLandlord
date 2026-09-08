using System.Text.RegularExpressions;
using Piraeus.BetterLandlord.Patches;
using Xunit;

namespace Piraeus.BetterLandlord.Tests;

public class OptionsMasterSpeedSourceModTests
{
    private const string OptionsPath = "res://Options.tscn::1";

    [Fact]
    public void InjectsMasterSpeedRowIntoRealGameSource()
    {
        var source = ReadGameSource("Options.tscn__1.gd");
        Assert.Equal(0, CountOccurrences(source, "\"speed_all\""));

        var modified = new OptionsMasterSpeedSourceMod().Modify(OptionsPath, source);
        var normalized = modified.Replace("\r\n", "\n");

        Assert.NotEqual(source, modified);

        // gameplay page: master row listed first
        Assert.Contains(
            "option_types = [\"speed_all\", \"spin_speed\", \"animation_speed\", \"counting_speed\", \"menu_speed\", \"input_type\",",
            normalized, StringComparison.Ordinal);

        // add_button(): master label derived from the four speeds, mixed shows "-"
        Assert.Contains(
            "\t\t\"speed_all\":\n" +
            "\t\t\tif spin_speed == animation_speed and animation_speed == counting_speed and counting_speed == menu_speed:\n" +
            "\t\t\t\tif spin_speed != 0:\n" +
            "\t\t\t\t\tbutton.button_text = str(spin_speed) + \"x\"\n" +
            "\t\t\t\telse:\n" +
            "\t\t\t\t\tbutton.button_text = tr(\"instant\")\n" +
            "\t\t\telse:\n" +
            "\t\t\t\tbutton.button_text = \"-\"\n" +
            "\t\t\tbutton.call = \"add_dropdown\"\n" +
            "\t\t\tbutton.args = [s]\n",
            normalized, StringComparison.Ordinal);

        // add_dropdown(): master dropdown with the same 7 choices
        Assert.Contains(
            "\t\t\"speed_all\":\n" +
            "\t\t\tfor i in range(7):\n" +
            "\t\t\t\tadd_dropdown_button(\"speed_all\", 160 + i * button_offset, i)\n",
            normalized, StringComparison.Ordinal);

        // add_dropdown_button(): shared choice builder extended
        Assert.Contains(
            "\t\t\"spin_speed\", \"animation_speed\", \"counting_speed\", \"menu_speed\", \"speed_all\":\n" +
            "\t\t\tbutton.call = \"update_setting\"\n",
            normalized, StringComparison.Ordinal);

        // update_setting(): master choice fans out to the four real settings
        Assert.Contains(
            "\t\t\"speed_all\":\n" +
            "\t\t\tspin_speed = choice\n" +
            "\t\t\tanimation_speed = choice\n" +
            "\t\t\tcounting_speed = choice\n" +
            "\t\t\tmenu_speed = choice\n",
            normalized, StringComparison.Ordinal);

        // localized row label intercepting the tr() fallback
        Assert.Contains(
            "\t\t\t\"speed_all\":\n" +
            "\t\t\t\tif TranslationServer.get_locale().begins_with(\"zh\"):\n" +
            "\t\t\t\t\tadd_option_text(\"动画速度总控\")\n",
            normalized, StringComparison.Ordinal);
    }

    [Fact]
    public void VanillaStructureIsPreserved()
    {
        var source = ReadGameSource("Options.tscn__1.gd");
        var modified = new OptionsMasterSpeedSourceMod().Modify(OptionsPath, source);
        var normalized = modified.Replace("\r\n", "\n");

        // the four original speed cases survive verbatim (single occurrence each)
        Assert.Equal(1, CountOccurrences(normalized,
            "\t\t\"spin_speed\":\n\t\t\tif spin_speed != 0:\n\t\t\t\tbutton.button_text = str(spin_speed) + \"x\""));
        Assert.Equal(1, CountOccurrences(normalized,
            "\t\t\"spin_speed\":\n\t\t\tfor i in range(7):\n\t\t\t\tadd_dropdown_button(\"spin_speed\", 160 + i * button_offset, i)"));
        Assert.Equal(1, CountOccurrences(normalized,
            "\t\t\"spin_speed\", \"animation_speed\", \"counting_speed\", \"menu_speed\":\n\t\t\tself[setting] = choice"));

        // save() still persists only the four real settings — the master row is
        // derived state and must not leak into the options save dict
        var saveFunc = ExtractFunction(normalized, "func save():");
        Assert.Contains("\t\t\"spin_speed\": spin_speed,", saveFunc, StringComparison.Ordinal);
        Assert.DoesNotContain("speed_all", saveFunc, StringComparison.Ordinal);
    }

    [Fact]
    public void IsIdempotent()
    {
        var mod = new OptionsMasterSpeedSourceMod();
        var source = ReadGameSource("Options.tscn__1.gd");

        var modifiedOnce = mod.Modify(OptionsPath, source);
        var modifiedTwice = mod.Modify(OptionsPath, modifiedOnce);

        Assert.Equal(modifiedOnce, modifiedTwice);
    }

    [Fact]
    public void UnrelatedPathsAreUntouched()
    {
        var mod = new OptionsMasterSpeedSourceMod();
        Assert.False(mod.ShouldRun("res://Main.tscn::1"));
        Assert.False(mod.ShouldRun("res://Options.tscn::2"));
        Assert.True(mod.ShouldRun(OptionsPath));
    }

    private static int CountOccurrences(string haystack, string needle) =>
        Regex.Matches(haystack, Regex.Escape(needle)).Count;

    private static string ExtractFunction(string source, string declaration)
    {
        var start = source.IndexOf(declaration, StringComparison.Ordinal);
        Assert.True(start >= 0, $"Missing function: {declaration}");
        var end = source.IndexOf("\nfunc ", start + declaration.Length, StringComparison.Ordinal);
        return end < 0 ? source[start..] : source[start..(end + 1)];
    }

    private static string ReadGameSource(string fileName) =>
        File.ReadAllText(Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "../../../..", "game_source_code", fileName)));
}
