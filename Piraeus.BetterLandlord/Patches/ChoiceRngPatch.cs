using System.Text.RegularExpressions;
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

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
    var _popup = $""/root/Main/Pop-up Sprite/Pop-up""
    if _popup != null and _popup.emails.size() > 0:
        var _type = _popup.emails[0].type
        if _type == ""add_item"" or _type == ""add_item_prompt"":
            var _r = $""/root/Main""._bh_rng_itm_rarity
            if _r != null: return _r.randf()
            return 0.0
    var _r = $""/root/Main""._bh_rng_sym_rarity
    if _r != null: return _r.randf()
    return 0.0

func _bh_c_rarity_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var _r = $""/root/Main""._bh_rng_forced_rarity
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_forced_rarity is NULL in shuffle!"")
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

# skip-owned item pick: deterministic per-round shuffle, prefix-stable.
# Iterates the shuffle sequence for `rarity`, returns the first candidate
# found in `pool` that is not already owned.  Cursor advances monotonically
# within a round; reset on new round.
func _bh_c_pick_item(rarity, pool):
    var _main = $""/root/Main""
    _main._bh_ensure_item_seqs()

    # Belt-and-suspenders: filter pool against owned / recently-destroyed.
    # The main add_cards branch already filters, but the else branch
    # (Pop-up:1424) rebuilds an unfiltered pool — we catch that here.
    var _items = $""/root/Main/Items""
    var _filtered = []
    for cand in pool:
        var _skip = false
        for it in _items.items:
            if it.type == cand:
                _skip = true
                break
        if not _skip:
            for it in _items.recently_destroyed_items:
                if it.type == cand:
                    _skip = true
                    break
        if not _skip:
            _filtered.push_back(cand)

    # skip-owned main loop: match against filtered pool (C1 — prevents
    # the ELSE branch's unfiltered pool from returning an owned item).
    # Fallback passes the ORIGINAL pool, matching upstream semantics:
    # the ELSE branch draws from the full rebuilt pool (owned items
    # included, disabled items included), exactly like vanilla line 1427.
    if _main._bh_item_seq.has(rarity):
        var seq = _main._bh_item_seq[rarity]
        var n = seq.size()
        if n > 0:
            var i = _main._bh_item_cursor.get(rarity, 0)
            while i < n:
                var cand = seq[i]
                i += 1
                if _filtered.has(cand):
                    _main._bh_item_cursor[rarity] = i
                    return cand
            _main._bh_item_cursor[rarity] = n

    return _bh_item_fallback(rarity, pool)

# Fallback when the shuffle sequence is exhausted for a rarity.
# Receives the ORIGINAL pool (caller's parameter, not filtered).
# Essence: vanilla always returns pool_ball_essence.
# Non-essence: deterministic pick from pool, whose domain matches
#   vanilla's ELSE-branch rebuilt pool (full rarity set minus same-choice).
func _bh_item_fallback(rarity, pool):
    if rarity == ""essence"":
        return ""pool_ball_essence""
    if pool.size() > 0:
        var _main = $""/root/Main""
        var idx = $""/root/Main""._bh_derive_seed(_main._bh_rng_landlord_seed,
            ""itemfb_"" + rarity + ""_"" + str(_main._bh_item_seq_round) + ""_""
            + str(_main._bh_item_cursor.get(rarity, 0)))
        return pool[((idx % pool.size()) + pool.size()) % pool.size()]
    return ""pool_ball_essence""

func _bh_c_pick_from_pool(rarity, pool):
    var _popup = $""/root/Main/Pop-up Sprite/Pop-up""
    if _popup != null and _popup.emails.size() > 0:
        var _type = _popup.emails[0].type
        if _type == ""add_item"" or _type == ""add_item_prompt"":
            return _bh_c_pick_item(rarity, pool)
    return _bh_c_pick_symbol(rarity, pool)

func _bh_c_spin_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    var _r = $""/root/Main""._bh_rng_oil_can
    if _r == null:
        printerr(""[BetterHistory] FATAL: _bh_rng_oil_can is NULL in shuffle!"")
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
        source = source.Replace("card.data = database[card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]]", "card.data = database[_bh_c_pick_from_pool(rarity, card_pool[rarity])]");
        source = source.Replace("rand_symbol = card_pool[rarity][floor(rand_range(0, card_pool[rarity].size()))]", "rand_symbol = _bh_c_pick_from_pool(rarity, card_pool[rarity])");
        source = source.Replace("\t\t\t\t\t\t\tpool.shuffle()", "\t\t\t\t\t\t\t_bh_c_spin_shuffle(pool)");
        source = source.Replace("landlord_fates_data[floor(rand_range(0, landlord_fates_data.size() - 1))]", "_bh_c_cosmetic_pick(landlord_fates_data)");
        source = source.Replace("card.data = database[card_pool[rand_range(0, card_pool.size())]]", "card.data = database[_bh_c_pick_item(rarity, card_pool)]");
        source = source.Replace("current_tip_num = int(tips[floor(rand_range(0, tips.size()))])", "current_tip_num = int(_bh_c_cosmetic_pick(tips))");
        source = source.Replace("\t\t\t\t\t\trandomize()\n\t\t\t\t\t\tif rand_range(0, 1) < 0.5:", "\t\t\t\t\t\t# randomize() removed\n\t\t\t\t\t\tif _bh_c_cosmetic_randf() < 0.5:");
        source = source.Replace("\t\t\t\t\t\t\t\t\t\t\t\t\t\trandomize()\n\t\t\t\t\t\t\t\t\t\t\t\t\t\tpool.shuffle()", "\t\t\t\t\t\t\t\t\t\t\t\t\t\t# randomize() removed\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t_bh_c_spin_shuffle(pool)");
        source = source.Replace("if rand_range(0, 1) < 0.5:", "if _bh_c_cosmetic_randf() < 0.5:");
        source = Regex.Replace(source, @"^(\t+)randomize\(\s*\)[ \t]*$", "$1# randomize() removed", RegexOptions.Multiline);

        return source;
    }
}
