using System.Text.RegularExpressions;
using Piraeus.BetterLandlord.Patches;
using Xunit;

namespace Piraeus.BetterLandlord.Tests;

public class JarZeroPayoutGuardSourceModTests
{
    private const string ItemPath = "res://Item.tscn::1";

    [Fact]
    public void GuardsBothJarBranchesInRealGameSource()
    {
        var source = ReadGameSource("Item.tscn__1.gd");
        var anchorPiggy = "\t\t\"piggy_bank\":\r\n\t\t\t$\"/root/Main/Sums/Coin Sum\".add_value(round(saved_value * values[1]))";
        var anchorSwear = "\t\t\"swear_jar\":\r\n\t\t\t$\"/root/Main/Sums/Coin Sum\".add_value(saved_value * values[1])";
        Assert.Equal(1, Regex.Matches(source, Regex.Escape(anchorPiggy)).Count);
        Assert.Equal(1, Regex.Matches(source, Regex.Escape(anchorSwear)).Count);

        var modified = new JarZeroPayoutGuardSourceMod().Modify(ItemPath, source);

        Assert.NotEqual(source, modified);
        var normalized = modified.Replace("\r\n", "\n");
        Assert.Contains(
            "\t\t\"piggy_bank\":\n" +
            "\t\t\tif round(saved_value * values[1]) != 0:\n" +
            "\t\t\t\t$\"/root/Main/Sums/Coin Sum\".add_value(round(saved_value * values[1]))\n" +
            "\t\t\t\t$\"/root/Main/Sums/Coin Sum\".adding = true\n" +
            "\t\t\t\t$\"/root/Main/Sums/HP Sum\".add_value(round(saved_value * values[1]))\n" +
            "\t\t\t\t$\"/root/Main/Sums/HP Sum\".adding = true\n",
            normalized, StringComparison.Ordinal);
        Assert.Contains(
            "\t\t\"swear_jar\":\n" +
            "\t\t\tif saved_value * values[1] != 0:\n" +
            "\t\t\t\t$\"/root/Main/Sums/Coin Sum\".add_value(saved_value * values[1])\n" +
            "\t\t\t\t$\"/root/Main/Sums/Coin Sum\".adding = true\n" +
            "\t\t\t\t$\"/root/Main/Sums/HP Sum\".add_value(saved_value * values[1])\n" +
            "\t\t\t\t$\"/root/Main/Sums/HP Sum\".adding = true\n",
            normalized, StringComparison.Ordinal);

        // Non-zero payouts keep the original statements (just re-indented),
        // and no other destroy() branch gains or loses statements.
        Assert.Equal(
            CountOccurrences(source, "add_value(round(saved_value * values[1]))"),
            CountOccurrences(normalized, "add_value(round(saved_value * values[1]))"));
        Assert.Equal(
            CountOccurrences(source, "add_value(saved_value * values[1])"),
            CountOccurrences(normalized, "add_value(saved_value * values[1])"));
        Assert.Contains(
            "\t\t\"treasure_map\":\n\t\t\tif saved_value >= values[0]:\n",
            normalized, StringComparison.Ordinal);
    }

    [Fact]
    public void IsIdempotent()
    {
        var mod = new JarZeroPayoutGuardSourceMod();
        var source = ReadGameSource("Item.tscn__1.gd");

        var modifiedOnce = mod.Modify(ItemPath, source);
        var modifiedTwice = mod.Modify(ItemPath, modifiedOnce);

        Assert.Equal(modifiedOnce, modifiedTwice);
    }

    [Fact]
    public void HandlesLfLineEndings()
    {
        var source = ReadGameSource("Item.tscn__1.gd").Replace("\r\n", "\n");

        var modified = new JarZeroPayoutGuardSourceMod().Modify(ItemPath, source);

        Assert.NotEqual(source, modified);
        Assert.Contains("\t\t\tif round(saved_value * values[1]) != 0:\n", modified, StringComparison.Ordinal);
        Assert.Contains("\t\t\tif saved_value * values[1] != 0:\n", modified, StringComparison.Ordinal);
    }

    private static int CountOccurrences(string haystack, string needle) =>
        Regex.Matches(haystack, Regex.Escape(needle)).Count;

    private static string ReadGameSource(string fileName) =>
        File.ReadAllText(Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "../../../..", "game_source_code", fileName)));
}
