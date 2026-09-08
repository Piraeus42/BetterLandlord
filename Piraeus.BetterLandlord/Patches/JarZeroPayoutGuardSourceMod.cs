using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Piggy bank / swear jar cash-out via Item.destroy() calls
/// Coin Sum.add_value(0) / HP Sum.add_value(0) and then sets adding = true
/// when the stored payout is zero. During a boss fight with instant coin
/// counting (counting_speed == 0) the HP Sum flush is gated on
/// hp_value != 0, so the adding flag never clears; every input gate that
/// reads HP Sum.adding (spin, pop-up buttons, item clicks) stays blocked
/// until the run is abandoned. Skip the sum updates entirely when the
/// payout is zero — destroying the item and the rent_due re-queue are
/// unaffected, and non-zero payouts (including negative) keep the
/// original code path.
/// </summary>
public class JarZeroPayoutGuardSourceMod : ISourceMod
{
    private const string ItemPath = "res://Item.tscn::1";

    public bool ShouldRun(string path) => path == ItemPath;

    public string Modify(string path, string source)
    {
        var eol = GetEol(source);
        source = GuardBranch(source, eol, "\"piggy_bank\":", "round(saved_value * values[1])");
        return GuardBranch(source, eol, "\"swear_jar\":", "saved_value * values[1]");
    }

    private static string GuardBranch(string source, string eol, string branchKey, string payoutExpr)
    {
        if (source.Contains("\t\t\tif " + payoutExpr + " != 0:" + eol + "\t\t\t\t$\"/root/Main/Sums/Coin Sum\"", StringComparison.Ordinal))
            return source;

        var anchor = string.Join(eol, new[]
        {
            "\t\t" + branchKey,
            "\t\t\t$\"/root/Main/Sums/Coin Sum\".add_value(" + payoutExpr + ")",
            "\t\t\t$\"/root/Main/Sums/Coin Sum\".adding = true",
            "\t\t\t$\"/root/Main/Sums/HP Sum\".add_value(" + payoutExpr + ")",
            "\t\t\t$\"/root/Main/Sums/HP Sum\".adding = true"
        });
        var replacement = string.Join(eol, new[]
        {
            "\t\t" + branchKey,
            "\t\t\tif " + payoutExpr + " != 0:",
            "\t\t\t\t$\"/root/Main/Sums/Coin Sum\".add_value(" + payoutExpr + ")",
            "\t\t\t\t$\"/root/Main/Sums/Coin Sum\".adding = true",
            "\t\t\t\t$\"/root/Main/Sums/HP Sum\".add_value(" + payoutExpr + ")",
            "\t\t\t\t$\"/root/Main/Sums/HP Sum\".adding = true"
        });
        return source.Contains(anchor, StringComparison.Ordinal)
            ? source.Replace(anchor, replacement, StringComparison.Ordinal)
            : source;
    }

    private static string GetEol(string source) => source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
}
