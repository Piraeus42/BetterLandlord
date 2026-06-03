using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// [Replace] patch for landlord fine print selection (get_fine_print).
/// Uses _bh_fp_rng which is injected by a companion ISourceMod.
/// </summary>
[Patch("res://Landlord.tscn::9", "get_fine_print")]
class LandlordFinePrintPatch
{
    // ISourceMod (LandlordRngRefSourceMod) already handles ALL RNG replacement
    // in Landlord.tscn::9.  This [Replace] is redundant: the function body it
    // receives has already been modified, and .Replace("rand_range(", ...)
    // would hit the "rand_range(" substring inside "_lfr_rand_range(" →
    // double replacement → "_lfr__lfr_rand_range(" → undefined function → crash.
    // Idempotency guard + pass-through:
    [Replace]
    static string ReplaceCode(string original) =>
        original.Contains("_lfr_rand_range(") ? original : original;
}
