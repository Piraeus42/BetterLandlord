using System.Text.RegularExpressions;
using GDWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

public class ReelExtraRngSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Reel.tscn::1";
    public string Modify(string path, string source)
    {
        if (source.Contains("func _rer_shuffle")) return source;
        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed (seed RNG)", RegexOptions.Multiline);
        source = source.Replace("rand_range(", "_rer_rand_range(");
        source = Regex.Replace(source, @"(\w[\w\[\]""'\.]*)\.shuffle\(\s*\)", "_rer_shuffle($1)");
        return source + "\n" + @"

func _rer_randf():
    var r = $""/root/Main""._bh_rng_reel; return r.randf() if r != null else 0.0
func _rer_randi_max(n):
    var r = $""/root/Main""._bh_rng_reel; return r.randi_max(n) if r != null else 0
func _rer_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_reel; return r.rand_range(a, b) if r != null else a
func _rer_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var r = $""/root/Main""._bh_rng_reel; if r != null: r.custom_shuffle(arr)
" + "\n";
    }
}
