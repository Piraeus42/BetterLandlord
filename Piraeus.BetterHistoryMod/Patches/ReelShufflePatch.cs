using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// [Replace] patch for shuffle_tiles() — uses cached RNG reference from Main.
/// A companion ISourceMod injects _bh_rng_init() which caches the reference once.
/// </summary>
[Patch("res://Main.tscn::4", "shuffle_tiles")]
class ReelShufflePatch
{
    [Replace]
    static string ReplaceCode(string original) => original
        .Replace("randomize()", "# randomize() → RNG")
        .Replace("pool.shuffle()", "_rrr_shuffle(pool)")
        .Replace("empties.shuffle()", "_rrr_shuffle(empties)");
}
