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
            # Essence-forced emails: rarity is deterministic, no roll consumed
            var _email = _popup.emails[0]
            if _email.has('extra_values') and _email.extra_values.has('forced_rarity'):
                var _fr = _email.extra_values.forced_rarity
                if typeof(_fr) == TYPE_ARRAY and _fr.size() > 0 and _fr[0] == 'essence':
                    return 0.0
            return $""/root/Main""._bh_item_rarity_randf()
    # add_tile path: uses symbol rarity RNG
    var _r = $""/root/Main""._bh_rng_sym_rarity
    if _r != null:
        var _val = _r.randf()
        return _val
    return 0.0

func _bh_c_rarity_shuffle(arr):
    if typeof(arr) != TYPE_ARRAY: return
    # Essence forced_rarity_arr = ['essence','essence','essence'] — no-op shuffle
    if arr.size() > 0 and arr[0] == 'essence':
        return
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
    var idx = _r.randi_max(pool.size())
    var result = pool[idx]
    return result

# skip-owned item pick: deterministic per-round shuffle, prefix-stable.
# Iterates the shuffle sequence for `rarity`, returns the first candidate
# found in `pool` that is not already owned.  Cursor advances monotonically
# within a round; reset on new round.
func _bh_c_pick_item(rarity, pool):
    var _main = $""/root/Main""
    # Event boundary is at add_cards loop start (_bh_begin_item_pick_event);
    # this function is a pure consumer — filter + advance cursor, no rebuild.

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

    var fb = _bh_item_fallback(rarity, pool)
    return fb

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
            ""itemfb_"" + rarity + ""_"" + str(_main._bh_item_pick_event) + ""_""
            + str(_main._bh_item_cursor.get(rarity, 0)))
        return pool[((idx % pool.size()) + pool.size()) % pool.size()]
    return ""pool_ball_essence""

# Essence skip-owned pick — independent essence stream, fully decoupled from items.
# Uses _bh_essence_seq / _bh_essence_cursor / _bh_essence_pick_event (NOT _bh_item_*).
func _bh_c_pick_essence(pool):
    var _main = $""/root/Main""

    # Filter pool against owned / recently-destroyed (same logic as _bh_c_pick_item)
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

    # Skip-owned from essence sequence
    var seq = _main._bh_essence_seq
    var n = seq.size()
    if n > 0:
        var i = _main._bh_essence_cursor
        while i < n:
            var cand = seq[i]
            i += 1
            if _filtered.has(cand):
                _main._bh_essence_cursor = i
                return cand
        _main._bh_essence_cursor = n

    # Fallback: deterministic pick from pool
    if pool.size() > 0:
        var idx = $""/root/Main""._bh_derive_seed(_main._bh_rng_landlord_seed,
            ""essfb_"" + str(_main._bh_essence_pick_event) + ""_"" + str(_main._bh_essence_cursor))
        var fb = pool[((idx % pool.size()) + pool.size()) % pool.size()]
        return fb
    return ""pool_ball_essence""

func _bh_c_pick_from_pool(rarity, pool):
    var _popup = $""/root/Main/Pop-up Sprite/Pop-up""
    if _popup != null and _popup.emails.size() > 0:
        var _type = _popup.emails[0].type
        if _type == ""add_item"" or _type == ""add_item_prompt"":
            if rarity == ""essence"":
                return _bh_c_pick_essence(pool)
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

        // Inject event-boundary signal before add_cards card loop.
        // This rebuilds shuffle sequences + resets cursor once per three-pick event,
        // so unpicked items are re-scattered into the pool (vanilla-semantic).
        source = source.Replace(
            "\t\tfor c in range(stcf - cards.size()):",
            "\t\t$\"/root/Main\"._bh_begin_item_pick_event()\n\t\tfor c in range(stcf - cards.size()):");

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
