using System.Text.RegularExpressions;
using GDWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Replaces all randomize()/rand_range()/shuffle() in Pop-up.tscn::1
/// with deterministic PCGRng instances from Main._bh_rng_*.
/// </summary>
public class ChoiceRngSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Pop-up.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("func _bh_c_rarity_randf():")) return source;

        var helpers = @"

# === Choice RNG helpers (BetterHistoryMod) ===
func _bh_c_rarity_randf():
    var _r = $""/root/Main""._bh_rng_rarity
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_rarity is NULL at choice time!"")
        return 0.0
    return _r.randf()

func _bh_c_rarity_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var _r = $""/root/Main""._bh_rng_rarity
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_rarity is NULL in shuffle!"")
        return
    _r.custom_shuffle(arr)

func _bh_c_pick_symbol(rarity, pool):
    var _r
    match rarity:
        ""common"":    _r = $""/root/Main""._bh_rng_sym_common
        ""uncommon"":  _r = $""/root/Main""._bh_rng_sym_uncommon
        ""rare"":      _r = $""/root/Main""._bh_rng_sym_rare
        ""very_rare"": _r = $""/root/Main""._bh_rng_sym_vrare
        _:             _r = $""/root/Main""._bh_rng_sym_common
    if _r == null:
        printerr(""[BetterHistory] FATAL: symbol RNG for rarity='"", rarity, ""' is NULL!"")
        return pool[0] if pool.size() > 0 else null
    return pool[_r.randi_max(pool.size())]

func _bh_c_pick_item(rarity, pool):
    var _r
    match rarity:
        ""common"":    _r = $""/root/Main""._bh_rng_itm_common
        ""uncommon"":  _r = $""/root/Main""._bh_rng_itm_uncommon
        ""rare"":      _r = $""/root/Main""._bh_rng_itm_rare
        ""very_rare"": _r = $""/root/Main""._bh_rng_itm_vrare
        _:             _r = $""/root/Main""._bh_rng_itm_common
    if _r == null:
        printerr(""[BetterHistory] FATAL: item RNG for rarity='"", rarity, ""' is NULL!"")
        return pool[0] if pool.size() > 0 else null
    return pool[_r.randi_max(pool.size())]

func _bh_c_spin_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var _r = $""/root/Main""._bh_rng_spin
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_spin is NULL in shuffle!"")
        return
    _r.custom_shuffle(arr)

func _bh_c_cosmetic_pick(arr):
    var _r = $""/root/Main""._bh_rng_cosmetic
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_cosmetic is NULL in pick!"")
        return arr[0] if arr.size() > 0 else null
    return _r.pick(arr)

func _bh_c_cosmetic_randf():
    var _r = $""/root/Main""._bh_rng_cosmetic
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_cosmetic is NULL in randf!"")
        return 0.5
    return _r.randf()
# === end Choice RNG helpers ===
";
        source += helpers;

        source = source.Replace("\t\t\t\t\trandomize()", "\t\t\t\t\t# randomize() removed");
        source = source.Replace("\t\t\t\t\t\t\t\t\trandomize()", "\t\t\t\t\t\t\t\t\t# randomize() removed");
        source = source.Replace("\t\t\t\trandomize()", "\t\t\t\t# randomize() removed");
        source = source.Replace("var rand_num = rand_range(0, 1)", "var rand_num = _bh_c_rarity_randf()");
        source = source.Replace("forced_rarity_arr.shuffle()", "_bh_c_rarity_shuffle(forced_rarity_arr)");
        source = source.Replace("card.data = database[card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]]", "card.data = database[_bh_c_pick_symbol(rarity, card_pool[rarity])]");
        source = source.Replace("rand_symbol = card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]", "rand_symbol = _bh_c_pick_symbol(rarity, card_pool[rarity])");
        source = source.Replace("\t\t\t\t\t\t\tpool.shuffle()", "\t\t\t\t\t\t\t_bh_c_spin_shuffle(pool)");
        source = source.Replace("landlord_fates_data[floor(rand_range(0, landlord_fates_data.size() - 1))]", "_bh_c_cosmetic_pick(landlord_fates_data)");
        source = source.Replace("card.data = database[card_pool[rand_range(0, card_pool.size())]]", "card.data = database[_bh_c_pick_item(rarity, card_pool)]");
        source = source.Replace("current_tip_num = int(tips[floor(rand_range(0, tips.size()))])", "current_tip_num = int(_bh_c_cosmetic_pick(tips))");
        source = source.Replace("\t\t\t\t\t\trandomize()\n\t\t\t\t\t\tif rand_range(0, 1) < 0.5:", "\t\t\t\t\t\t# randomize() removed\n\t\t\t\t\t\tif _bh_c_cosmetic_randf() < 0.5:");
        source = source.Replace("\t\t\t\t\t\t\t\t\t\t\t\t\t\trandomize()\n\t\t\t\t\t\t\t\t\t\t\t\t\t\tpool.shuffle()", "\t\t\t\t\t\t\t\t\t\t\t\t\t\t# randomize() removed\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t_bh_c_spin_shuffle(pool)");
        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed", RegexOptions.Multiline);

        return source;
    }
}
