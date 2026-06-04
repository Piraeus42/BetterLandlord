using System.Text.RegularExpressions;
using GDWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

public class ItemRngSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Item.tscn::1";
    public string Modify(string path, string source)
    {
        if (source.Contains("func _itr_shuffle")) return source;
        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed", RegexOptions.Multiline);
        source = source.Replace("rand_range(", "_itr_rand_range(");
        source = Regex.Replace(source, @"(\w[\w\[\]""'\.]*)\.shuffle\(\s*\)", "_itr_shuffle($1)");
        return source + "\n" + @"

func _itr_randf():
    var r = $""/root/Main""._bh_rng_effect; return r.randf() if r != null else 0.0
func _itr_randi_max(n):
    var r = $""/root/Main""._bh_rng_effect; return r.randi_max(n) if r != null else 0
func _itr_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_effect; return r.rand_range(a, b) if r != null else a
func _itr_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var r = $""/root/Main""._bh_rng_effect_shuffle; if r != null: r.custom_shuffle(arr)
" + "\n";
    }
}
