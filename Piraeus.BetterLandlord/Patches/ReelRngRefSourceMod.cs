using System.Text.RegularExpressions;
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// ReelRNG wrappers + full-file replacement for Main.tscn::4.
/// Now covers ALL randomize/rand_range/shuffle including add_tile().
/// </summary>
public class ReelRngRefSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::4";

    public string Modify(string path, string source)
    {
        if (source.Contains("func _rrr_shuffle")) return source;

        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$",
            "$1# randomize() removed (seed RNG)", RegexOptions.Multiline);
        source = source.Replace("rand_range(", "_rrr_rand_range(");
        source = Regex.Replace(source, @"(\w[\w\[\]""'\.]*)\.shuffle\(\s*\)", "_rrr_shuffle($1)");

        return source + "\n" + @"

func _rrr_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var r = $""/root/Main""._bh_rng_reel_shuffle; if r != null: r.custom_shuffle(arr)
func _rrr_randi_max(n):
    var r = $""/root/Main""._bh_rng_reel; return r.randi_max(n) if r != null else 0
func _rrr_randf():
    var r = $""/root/Main""._bh_rng_reel; return r.randf() if r != null else 0.0
func _rrr_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_reel; return r.rand_range(a, b) if r != null else a
" + "\n";
    }
}
