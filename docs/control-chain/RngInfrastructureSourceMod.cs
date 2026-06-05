using SlotWeave.Modding;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Injects PCGRng class, FNV-1a/djb2 hash, custom_shuffle,
/// and init_all_rngs() into Main.tscn::1.
/// </summary>
public class RngInfrastructureSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("class PCGRng:")) return source;
        return source + "\n" + GdscriptUtil.Tabify(RngInfrastructureGdscript);
    }

    private const string RngInfrastructureGdscript = @"

# ============================================================
# PCGRng — Deterministic RNG (PCG-family, 64-bit state)
# Replaces Godot's global randomize()/rand_range() entirely.
# ============================================================

const PCG_DEFAULT_INC: int = 1442695040888963407
const PCG_MULT: int = 6364136223846793005
const MASK_63: int = 0x7FFFFFFFFFFFFFFF  # max positive signed 64-bit
const MASK_31: int = 0x7FFFFFFF

class PCGRng:
    var state: int  # kept in [0, 2^63) — always non-negative
    var inc: int    # stream id

    func _init(seed_val: int):
        state = seed_val
        inc = (PCG_DEFAULT_INC << 1) | 1
        _step()
        state = (state + PCG_MULT) & MASK_63
        _step()
        _step()

    func _step():
        var old: int = state
        state = ((old * PCG_MULT) + inc) & MASK_63
        return old

    # Returns float in [0, 1)
    func randf() -> float:
        var old: int = _step()
        var x: int = (old >> 18) ^ old
        x = x >> 27
        var rot: int = old >> 59        # PCG32 standard: top 6 bits for rotation
        var result: int = ((x >> rot) | (x << ((-rot) & 31))) & MASK_31
        return float(result) / 2147483648.0

    # Returns int in [0, max_val)
    func randi_max(max_val: int) -> int:
        return int(floor(self.randf() * float(max_val)))

    # Returns float in [min_val, max_val)
    func rand_range(min_val: float, max_val: float) -> float:
        return min_val + self.randf() * (max_val - min_val)

    # Pick a random element from an array
    func pick(arr: Array):
        if arr.size() == 0:
            return null
        return arr[self.randi_max(arr.size())]

    # Fisher-Yates shuffle using THIS RNG (NOT Godot's global random)
    func custom_shuffle(arr: Array):
        var n: int = arr.size()
        for i in range(n - 1, 0, -1):
            var j: int = int(floor(self.randf() * float(i + 1)))
            var tmp = arr[i]
            arr[i] = arr[j]
            arr[j] = tmp

    # Chance test: randf() * 100 < percent
    func chance(percent: float) -> bool:
        return self.randf() * 100.0 < percent

# ============================================================
# Hash functions
# ============================================================

# FNV-1a: any string → 31-bit positive int (deterministic, cross-platform)
func _bh_fnv1a(text: String) -> int:
    var h: int = 2166136261
    for c in text:
        h = (h ^ ord(c)) & MASK_63
        h = (h * 16777619) & MASK_63
    return h & MASK_31

# djb2: int + string → 31-bit positive int (seed derivation)
func _bh_derive_seed(base: int, name: String) -> int:
    var h: int = base & MASK_63
    for c in name:
        h = (((h << 5) + h) ^ ord(c)) & MASK_63
    return h & MASK_31

# Generate random 10-char [0-9A-Z] seed string
const _BH_SEED_CHARS = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'

func _bh_generate_random_seed() -> String:
    # Use OS entropy (not Godot global randi — seed() captures it to landlord_seed,
    # making randi() deterministic within a session)
    var _entropy = OS.get_unix_time() + OS.get_ticks_msec()
    var _h = _bh_fnv1a(str(_entropy))
    var result: String = ''
    for _i in range(10):
        _h = ((_h * 1103515245) + 12345) & 0x7FFFFFFF
        result += _BH_SEED_CHARS[_h % 34]
    return result

# ============================================================
# RNG instance registry
# ============================================================

var _bh_rng_seed_type: String = ''      # 'random' | 'custom'
var _bh_rng_seed_input: String = ''     # 10-char or user input
var _bh_rng_landlord_seed: int = 0      # hash result

# 17 persistent (cross-spin) RNG instances
var _bh_rng_spin: PCGRng = null
var _bh_rng_rarity: PCGRng = null
var _bh_rng_sym_common: PCGRng = null
var _bh_rng_sym_uncommon: PCGRng = null
var _bh_rng_sym_rare: PCGRng = null
var _bh_rng_sym_vrare: PCGRng = null
var _bh_rng_itm_common: PCGRng = null
var _bh_rng_itm_uncommon: PCGRng = null
var _bh_rng_itm_rare: PCGRng = null
var _bh_rng_itm_vrare: PCGRng = null
var _bh_rng_ess_common: PCGRng = null
var _bh_rng_ess_uncommon: PCGRng = null
var _bh_rng_ess_rare: PCGRng = null
var _bh_rng_ess_vrare: PCGRng = null
var _bh_rng_fineprint: PCGRng = null
var _bh_rng_cosmetic: PCGRng = null

# Per-spin temporary instances (recreated each spin)
var _bh_rng_reel: PCGRng = null
var _bh_rng_effect: PCGRng = null
var _bh_rng_scratch: PCGRng = null  # cosmetic/frame-driven discard stream

# ============================================================
# Initialize all RNG from seed
# ============================================================

func _bh_init_rng(seed_type: String, seed_input: String):
    _bh_rng_seed_type = seed_type
    _bh_rng_seed_input = seed_input
    seed_input = seed_input.replace('O', '0').replace('I', '1')

    if seed_type == 'random' or seed_input == '':
        _bh_rng_seed_input = _bh_generate_random_seed()
        _bh_rng_seed_type = 'random'
    else:
        _bh_rng_seed_input = seed_input
        _bh_rng_seed_type = 'custom'

    var landlord_seed: int = _bh_fnv1a(_bh_rng_seed_input)
    _bh_rng_landlord_seed = landlord_seed
    var s: int = landlord_seed

    # === Phase 1: Create ALL 19 instances to local variables ===
    var _new_spin           = PCGRng.new(_bh_derive_seed(s, 'spin'))
    var _new_rarity         = PCGRng.new(_bh_derive_seed(s, 'rarity'))
    var _new_sym_common     = PCGRng.new(_bh_derive_seed(s, 'sym_common'))
    var _new_sym_uncommon   = PCGRng.new(_bh_derive_seed(s, 'sym_uncommon'))
    var _new_sym_rare       = PCGRng.new(_bh_derive_seed(s, 'sym_rare'))
    var _new_sym_vrare      = PCGRng.new(_bh_derive_seed(s, 'sym_vrare'))
    var _new_itm_common     = PCGRng.new(_bh_derive_seed(s, 'itm_common'))
    var _new_itm_uncommon   = PCGRng.new(_bh_derive_seed(s, 'itm_uncommon'))
    var _new_itm_rare       = PCGRng.new(_bh_derive_seed(s, 'itm_rare'))
    var _new_itm_vrare      = PCGRng.new(_bh_derive_seed(s, 'itm_vrare'))
    var _new_ess_common     = PCGRng.new(_bh_derive_seed(s, 'ess_common'))
    var _new_ess_uncommon   = PCGRng.new(_bh_derive_seed(s, 'ess_uncommon'))
    var _new_ess_rare       = PCGRng.new(_bh_derive_seed(s, 'ess_rare'))
    var _new_ess_vrare      = PCGRng.new(_bh_derive_seed(s, 'ess_vrare'))
    var _new_fineprint      = PCGRng.new(_bh_derive_seed(s, 'fineprint'))
    var _new_cosmetic       = PCGRng.new(_bh_derive_seed(s, 'cosmetic'))
    var _new_reel           = PCGRng.new(_bh_derive_seed(s, 'reel_init'))
    var _new_effect         = PCGRng.new(_bh_derive_seed(s, 'effect_init'))
    var _new_scratch        = PCGRng.new(_bh_derive_seed(s, 'scratch_init'))

    # === Phase 2: Atomically assign — ALL or NOTHING ===
    _bh_rng_spin           = _new_spin
    _bh_rng_rarity         = _new_rarity
    _bh_rng_sym_common     = _new_sym_common
    _bh_rng_sym_uncommon   = _new_sym_uncommon
    _bh_rng_sym_rare       = _new_sym_rare
    _bh_rng_sym_vrare      = _new_sym_vrare
    _bh_rng_itm_common     = _new_itm_common
    _bh_rng_itm_uncommon   = _new_itm_uncommon
    _bh_rng_itm_rare       = _new_itm_rare
    _bh_rng_itm_vrare      = _new_itm_vrare
    _bh_rng_ess_common     = _new_ess_common
    _bh_rng_ess_uncommon   = _new_ess_uncommon
    _bh_rng_ess_rare       = _new_ess_rare
    _bh_rng_ess_vrare      = _new_ess_vrare
    _bh_rng_fineprint      = _new_fineprint
    _bh_rng_cosmetic       = _new_cosmetic
    _bh_rng_reel           = _new_reel
    _bh_rng_effect         = _new_effect
    _bh_rng_scratch        = _new_scratch

    # === Fix C: Capture Godot global RNG ===
    seed(landlord_seed)

# ============================================================
# Per-spin RNG derivation
# ============================================================

func _bh_begin_spin_rng():
    var spin_val: int = _bh_rng_spin.randi_max(2147483647)
    _bh_rng_reel   = PCGRng.new(_bh_derive_seed(spin_val, 'reel'))
    _bh_rng_effect = PCGRng.new(_bh_derive_seed(spin_val, 'effect'))
    _bh_rng_scratch = PCGRng.new(_bh_derive_seed(spin_val, 'scratch'))

# ============================================================
# Per-rarity RNG dispatch for symbol choice
# ============================================================

func _bh_symbol_rng_for_rarity(rarity: String) -> PCGRng:
    match rarity:
        'common':     return _bh_rng_sym_common
        'uncommon':   return _bh_rng_sym_uncommon
        'rare':       return _bh_rng_sym_rare
        'very_rare':  return _bh_rng_sym_vrare
        _:            return _bh_rng_sym_common

# Called by new_game() Prefix — applies seed config from Title UI
func _bh_apply_seed():
    var title = $""/root/Main/Title""
    if title == null:
        printerr(""[BetterHistory] FATAL: /root/Main/Title is null in _bh_apply_seed!"")
        return
    if not title.has_method(""_bh_get_seed_config""):
        printerr(""[BetterHistory] FATAL: Title does not have _bh_get_seed_config!"")
        return
    var cfg = title._bh_get_seed_config()
    _bh_init_rng(str(cfg['type']), str(cfg['input']))

# Called by Godot when the window is closed mid-run.
# NOTIFICATION_WM_QUIT_REQUEST = 1006
func _notification(what: int):
    if what == 1006:
        if _bh_events.size() > 0 and not _bh_run_ended:
            _bh_end_run(""quit"")

func _bh_item_rng_for_rarity(rarity: String) -> PCGRng:
    match rarity:
        'common':     return _bh_rng_itm_common
        'uncommon':   return _bh_rng_itm_uncommon
        'rare':       return _bh_rng_itm_rare
        'very_rare':  return _bh_rng_itm_vrare
        _:            return _bh_rng_itm_common
";
}
