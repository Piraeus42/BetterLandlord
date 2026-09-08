using System.Text.RegularExpressions;
using Piraeus.BetterLandlord.Patches;
using Xunit;

namespace Piraeus.BetterLandlord.Tests;

public class SymbolResolutionBugFixSourceModTests
{
    private const string SlotIconPath = "res://Slot Icon.tscn::1";

    [Fact]
    public void SlotIconUsesFloatResolversWithLargeValuePreservation()
    {
        var source = ReadGameSource("Slot Icon.tscn__1.gd");

        var modified = new SymbolResolutionBugFixSourceMod().Modify(SlotIconPath, source);

        Assert.NotEqual(source, modified);

        var nonPrev = ExtractFunction(modified, "func get_non_prev_value(currency):");
        var getValue = ExtractFunction(modified, "func get_value(currency):");
        var helper = ExtractFunction(modified, "func _bl_normalise_value(value):");

        Assert.DoesNotMatch(@"(?<![A-Za-z0-9_])int\(", nonPrev);
        Assert.DoesNotMatch(@"(?<![A-Za-z0-9_])int\(", getValue);
        Assert.DoesNotContain("_bl_saturating_int", nonPrev, StringComparison.Ordinal);
        Assert.DoesNotContain("_bl_saturating_int", getValue, StringComparison.Ordinal);
        Assert.Contains("float(self[v_str])", nonPrev, StringComparison.Ordinal);
        Assert.Contains("float(self[pb_str])", nonPrev, StringComparison.Ordinal);
        Assert.Contains("float(self[pm_str])", nonPrev, StringComparison.Ordinal);
        Assert.Contains("float(self[fvb_str])", nonPrev, StringComparison.Ordinal);
        Assert.Contains("_bl_normalise_value(round(", nonPrev, StringComparison.Ordinal);

        Assert.Contains("float(p[p_v_str])", getValue, StringComparison.Ordinal);
        Assert.Contains("float(p[pb_str])", getValue, StringComparison.Ordinal);
        Assert.Contains("float(p[pm_str])", getValue, StringComparison.Ordinal);
        Assert.Contains(
            "var p_core_value = (p_base_value + p_value_bonus) * p_value_multiplier * p_permanent_multiplier",
            getValue,
            StringComparison.Ordinal);
        Assert.Contains(
            "prev_final_value += _bl_normalise_value(round((p_base_value + p_value_bonus + p_permanent_bonus) * p_value_multiplier * p_permanent_multiplier))",
            getValue,
            StringComparison.Ordinal);
        Assert.Contains(
            "var core_value = (base_value + value_bonus) * value_multiplier * permanent_multiplier",
            getValue,
            StringComparison.Ordinal);
        Assert.Contains(
            "return _bl_normalise_value(round(base_value + value_bonus + permanent_bonus + prev_final_value))",
            getValue,
            StringComparison.Ordinal);
        Assert.Contains(
            "check_symbol_value(self, _bl_normalise_value(round(positive_core_value)))",
            getValue,
            StringComparison.Ordinal);
        Assert.Contains("_bl_normalise_value(round(", getValue, StringComparison.Ordinal);
        Assert.Contains(
            "if currency == \"coin\" and p.wildcarded:",
            getValue,
            StringComparison.Ordinal);

        Assert.Equal(1, CountDeclarations(modified, "func _bl_normalise_value(value):"));
        Assert.Contains("if is_nan(number):", helper, StringComparison.Ordinal);
        Assert.Contains("if is_inf(number):", helper, StringComparison.Ordinal);
        Assert.Contains("if abs(number) <= 1e15:", helper, StringComparison.Ordinal);
        Assert.Contains("return int(number)", helper, StringComparison.Ordinal);
        Assert.Contains("return number", helper, StringComparison.Ordinal);
    }

    [Fact]
    public void SlotIconFloatResolverPatchIsIdempotent()
    {
        var source = ReadGameSource("Slot Icon.tscn__1.gd");
        var mod = new SymbolResolutionBugFixSourceMod();

        var modifiedOnce = mod.Modify(SlotIconPath, source);
        var modifiedTwice = mod.Modify(SlotIconPath, modifiedOnce);

        Assert.Equal(modifiedOnce, modifiedTwice);
        Assert.Equal(
            1,
            CountDeclarations(modifiedTwice, "func _bl_normalise_value(value):"));
    }

    [Fact]
    public void FloatResolverMatchesIntegerResolverForBoundedIntegerValues()
    {
        const int caseCount = 1_000;
        var random = new Random(20260908);

        for (var i = 0; i < caseCount; i++)
        {
            var multipliers = new long[random.Next(0, 4)];
            for (var j = 0; j < multipliers.Length; j++)
                multipliers[j] = random.Next(1, 6);

            var bonuses = new long[random.Next(0, 4)];
            for (var j = 0; j < bonuses.Length; j++)
                bonuses[j] = random.Next(-4, 5);

            var scale = random.Next(0, 15);
            var value = random.Next(-10, 11) * (long)Math.Pow(10, scale);
            var permanentBonus = random.Next(-10, 11) * (long)Math.Pow(10, scale);
            var flatBonus = random.Next(-10, 11) * (long)Math.Pow(10, scale);

            var symbol = new TestSymbol(value, permanentBonus, flatBonus, bonuses, multipliers);
            var oldResult = IntegerResolver(symbol);
            var newResult = FloatResolver(symbol);

            if (Math.Abs(oldResult) <= 1_000_000_000_000_000)
                Assert.Equal(oldResult, newResult);
        }

        var boundary = new TestSymbol(
            250_000_000_000_000,
            50_000_000_000_000,
            100_000_000_000_000,
            [0],
            [3]);

        Assert.Equal(1_000_000_000_000_000L, FloatResolver(boundary));
        Assert.Equal(1_000_000_000_000_000L, IntegerResolver(boundary));

        var exponential = new TestSymbol(
            1,
            0,
            0,
            [],
            Enumerable.Repeat(64L, 17).ToArray());

        var expectedExponential = 1.0;
        foreach (var multiplier in exponential.Multipliers)
            expectedExponential *= multiplier;

        Assert.Equal(expectedExponential, FloatResolver(exponential));
        Assert.True(Math.Abs(expectedExponential) > 1_000_000_000_000_000);
    }

    private static long IntegerResolver(TestSymbol symbol)
    {
        long valueBonus = 0;
        long valueMultiplier = 1;

        foreach (var bonus in symbol.Bonuses)
            checked { valueBonus += bonus; }
        foreach (var multiplier in symbol.Multipliers)
            checked { valueMultiplier *= multiplier; }

        var bonusSum = checked(symbol.Value + valueBonus + symbol.PermanentBonus);
        var core = (double)bonusSum;
        foreach (var multiplier in symbol.Multipliers)
            core *= multiplier;

        if (core < 0)
            return IntegerGodotRound(bonusSum);

        var result = core + symbol.FlatBonus;
        return IntegerGodotRound(result);
    }

    private static double FloatResolver(TestSymbol symbol)
    {
        double valueBonus = 0;
        double valueMultiplier = 1;

        foreach (var bonus in symbol.Bonuses)
            valueBonus += (double)bonus;
        foreach (var multiplier in symbol.Multipliers)
            valueMultiplier *= (double)multiplier;

        var baseValue = (double)symbol.Value;
        var permanentBonus = (double)symbol.PermanentBonus;
        var flatBonus = (double)symbol.FlatBonus;
        var coreValue = (baseValue + valueBonus + permanentBonus) * valueMultiplier;

        if (coreValue < 0)
            return NormaliseResolverResult(baseValue + valueBonus + permanentBonus);

        return NormaliseResolverResult(
            (baseValue + valueBonus + permanentBonus) * valueMultiplier + flatBonus);
    }

    private static double NormaliseResolverResult(double value)
    {
        if (double.IsNaN(value))
            return 0;
        if (double.IsInfinity(value))
            return value > 0 ? 1e308 : -1e308;

        var rounded = Math.Round(value, MidpointRounding.AwayFromZero);
        return Math.Abs(rounded) <= 1_000_000_000_000_000
            ? (double)(long)rounded
            : rounded;
    }

    private static long IntegerGodotRound(double value) =>
        checked((long)Math.Round(value, MidpointRounding.AwayFromZero));

    private static string ReadGameSource(string fileName) =>
        File.ReadAllText(Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "../../../..", "game_source_code", fileName)));

    private static string ExtractFunction(string source, string declaration)
    {
        var start = source.IndexOf(declaration, StringComparison.Ordinal);
        Assert.True(start >= 0, $"Missing function: {declaration}");

        var end = source.IndexOf("\nfunc ", start + declaration.Length, StringComparison.Ordinal);
        return end < 0 ? source[start..] : source[start..(end + 1)];
    }

    private static int CountDeclarations(string source, string declaration)
    {
        var count = 0;
        var position = 0;
        while ((position = source.IndexOf(declaration, position, StringComparison.Ordinal)) >= 0)
        {
            count++;
            position += declaration.Length;
        }

        return count;
    }

    private readonly record struct TestSymbol(
        long Value,
        long PermanentBonus,
        long FlatBonus,
        long[] Bonuses,
        long[] Multipliers);
}
