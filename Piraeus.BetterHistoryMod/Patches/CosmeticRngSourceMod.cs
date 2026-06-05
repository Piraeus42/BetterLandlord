using System.Text.RegularExpressions;
using SlotWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

public class CosmeticRngSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path switch
    {
        "res://Music Player.tscn::1" => true,
        "res://Options.tscn::1" => true,
        "res://Main.tscn::1" => true,
        _ => false
    };

    public string Modify(string path, string source)
    {
        if (source.Contains("func _csr_randf") || source.Contains("_bh_rng_cosmetic.pick(textures)"))
            return source;

        if (path == "res://Main.tscn::1")
        {
            source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed (seed RNG)", RegexOptions.Multiline);
            source = source.Replace("return textures[floor(rand_range(0, textures.size()))]", "return _bh_rng_cosmetic.pick(textures)");
            source = source.Replace("if rand_range(0, 1) < 0.5:", "if _bh_rng_cosmetic.randf() < 0.5:");
            return source;
        }

        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed (seed RNG)", RegexOptions.Multiline);
        source = source.Replace("rand_range(", "_csr_rand_range(");
        return source + "\n" + @"

func _csr_randf():
    var r = $""/root/Main""._bh_rng_cosmetic; return r.randf() if r != null else 0.0
func _csr_rand_range(a, b):
    var r = $""/root/Main""._bh_rng_cosmetic; return r.rand_range(a, b) if r != null else a
func _csr_pick(arr):
    var r = $""/root/Main""._bh_rng_cosmetic; return r.pick(arr) if r != null else (arr[0] if arr.size() > 0 else null)
" + "\n";
    }
}
