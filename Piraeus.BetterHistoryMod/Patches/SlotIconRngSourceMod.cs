using System.Text.RegularExpressions;
using GDWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// EffectRNG + ScratchRNG for Slot Icon.tscn::1.
/// Cosmetic (shake/SFX) → ScratchRNG. Gameplay (probability/values/picks) → EffectRNG.
/// </summary>
public class SlotIconRngSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Slot Icon.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("func _sir_shuffle")) return source;

        // Order matters: general rand_range( → _sir_rand_range( FIRST,
        // then override the specific cosmetic lines with _scr_* variants.
        // If the overrides run first, the general replacement corrupts
        // _scr_rand_range into _scr__sir_rand_range (double replacement).

        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed", RegexOptions.Multiline);
        source = source.Replace("rand_range(", "_sir_rand_range(");
        source = Regex.Replace(source, @"(\w[\w\[\]""'\.]*)\.shuffle\(\s*\)", "_sir_shuffle($1)");

        // Now override the cosmetic lines — _sir_* is already in place,
        // so these replacements target the final function names safely.
        source = source.Replace("str(floor(_sir_rand_range(0, sfx_total_num)))", "str(_scr_randi_max(sfx_total_num))");
        source = source.Replace("floor(_sir_rand_range(-1, 2))", "floor(_scr_rand_range(-1, 2))");

        // Inject event emission at symbol destruction / removal points
        // so _bh_flush can accumulate destroyed/removed symbols from events
        // (mirrors destroyed_item capture in WriteLogPatch).
        source = Regex.Replace(source,
            @"^(\t*)\$""/root/Main/Pop-up Sprite/Pop-up""\.destroyed_symbol_types\.push_back\(target\.type\)\r?$",
            @"$1$""/root/Main/Pop-up Sprite/Pop-up"".destroyed_symbol_types.push_back(target.type)
$1if $""/root/Main"".has_method(""_bh_add_event""):
$1	$""/root/Main""._bh_add_event(""symbol_destroyed"", {""symbol"": target.type})",
            RegexOptions.Multiline);
        source = Regex.Replace(source,
            @"^(\t*)\$""/root/Main/Pop-up Sprite/Pop-up""\.removed_symbol_types\.push_back\(target\.type\)\r?$",
            @"$1$""/root/Main/Pop-up Sprite/Pop-up"".removed_symbol_types.push_back(target.type)
$1if $""/root/Main"".has_method(""_bh_add_event""):
$1	$""/root/Main""._bh_add_event(""symbol_removed"", {""symbol"": target.type})",
            RegexOptions.Multiline);

        return source + "\n" + @"

func _sir_randf():
    var r = $""/root/Main""._bh_rng_effect; return r.randf() if r != null else 0.0
func _sir_randi_max(n):
    var r = $""/root/Main""._bh_rng_effect; return r.randi_max(n) if r != null else 0
func _sir_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_effect; return r.rand_range(a, b) if r != null else a
func _sir_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var r = $""/root/Main""._bh_rng_effect_shuffle; if r != null: r.custom_shuffle(arr)

func _scr_randf():
    var r = $""/root/Main""._bh_rng_scratch; return r.randf() if r != null else 0.0
func _scr_randi_max(n):
    var r = $""/root/Main""._bh_rng_scratch; return r.randi_max(n) if r != null else 0
func _scr_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_scratch; return r.rand_range(a, b) if r != null else a
" + "\n";
    }
}
