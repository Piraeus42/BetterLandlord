using System.Text.RegularExpressions;
using GDWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

public class LandlordRngRefSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Landlord.tscn::9";
    public string Modify(string path, string source)
    {
        if (source.Contains("func _lfr_shuffle")) return source;
        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed (seed RNG)", RegexOptions.Multiline);
        source = source.Replace("rand_range(", "_lfr_rand_range(");
        source = Regex.Replace(source, @"(\w[\w\[\]""'\.]*)\.shuffle\(\s*\)", "_lfr_shuffle($1)");
        return source + "\n" + @"

func _lfr_randf():
    var r = $""/root/Main""._bh_rng_fineprint; return r.randf() if r != null else 0.0
func _lfr_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_fineprint; return r.rand_range(a, b) if r != null else a
func _lfr_randi_max(n):
    var r = $""/root/Main""._bh_rng_fineprint; return r.randi_max(n) if r != null else 0
func _lfr_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var r = $""/root/Main""._bh_rng_fineprint; if r != null: r.custom_shuffle(arr)
" + "\n";
    }
}

