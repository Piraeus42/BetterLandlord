using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

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

# Persistent (cross-spin) RNG instances + item sequence state
var _bh_rng_sym_rarity: PCGRng = null
var _bh_rng_sym_common: PCGRng = null
var _bh_rng_sym_uncommon: PCGRng = null
var _bh_rng_sym_rare: PCGRng = null
var _bh_rng_sym_vrare: PCGRng = null
# Item pool selection moved to skip-owned sequences (per-round deterministic shuffle)
var _bh_item_seq: Dictionary = {}         # rarity → Array[String]
var _bh_item_cursor: Dictionary = {}      # rarity → int
var _bh_item_seq_round: int = -1
var _bh_item_rarity_ctr: int = 0          # per-round counter for deterministic rarity
var _bh_rng_fineprint: PCGRng = null
var _bh_rng_cosmetic: PCGRng = null
var _bh_rng_forced_rarity: PCGRng = null

var _bh_rng_scratch: PCGRng = null  # persistent — cosmetic (SFX/shake), must survive spin boundary

# Per-spin temporary instances (recreated each spin)
var _bh_rng_reel: PCGRng = null
var _bh_rng_reel_shuffle: PCGRng = null
var _bh_rng_effect: PCGRng = null
var _bh_rng_effect_shuffle: PCGRng = null
var _bh_rng_oil_can: PCGRng = null

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

    # === Phase 1: Create persistent RNG instances (9) + per-spin placeholders (2) ===
    var _new_sym_rarity = PCGRng.new(_bh_derive_seed(s, 'sym_rarity'))
    var _new_sym_common     = PCGRng.new(_bh_derive_seed(s, 'sym_common'))
    var _new_sym_uncommon   = PCGRng.new(_bh_derive_seed(s, 'sym_uncommon'))
    var _new_sym_rare       = PCGRng.new(_bh_derive_seed(s, 'sym_rare'))
    var _new_sym_vrare      = PCGRng.new(_bh_derive_seed(s, 'sym_vrare'))
    var _new_fineprint      = PCGRng.new(_bh_derive_seed(s, 'fineprint'))
    var _new_cosmetic       = PCGRng.new(_bh_derive_seed(s, 'cosmetic'))
    var _new_forced_rarity  = PCGRng.new(_bh_derive_seed(s, 'forced_rarity'))
    var _new_reel           = PCGRng.new(_bh_derive_seed(s, 'reel_init'))
    var _new_effect         = PCGRng.new(_bh_derive_seed(s, 'effect_init'))
    var _new_scratch        = PCGRng.new(_bh_derive_seed(s, 'scratch'))

    # === Phase 2: Atomically assign — ALL or NOTHING ===
    _bh_rng_sym_rarity    = _new_sym_rarity
    _bh_rng_sym_common     = _new_sym_common
    _bh_rng_sym_uncommon   = _new_sym_uncommon
    _bh_rng_sym_rare       = _new_sym_rare
    _bh_rng_sym_vrare      = _new_sym_vrare
    _bh_rng_fineprint      = _new_fineprint
    _bh_rng_cosmetic       = _new_cosmetic
    _bh_rng_forced_rarity  = _new_forced_rarity
    _bh_rng_reel           = _new_reel
    _bh_rng_effect         = _new_effect
    _bh_rng_scratch        = _new_scratch

    # === Fix C: Capture Godot global RNG ===
    seed(landlord_seed)

# ============================================================
# Per-spin RNG derivation
# ============================================================

func _bh_begin_spin_rng():
    # Safety net: if RNG was never initialized (missed hook / edge case),
    # fall back to random rather than crashing on null dereference.
    if _bh_rng_sym_rarity == null:
        _bh_init_rng('random', '')
    # Spin RNG is derived deterministically from seed + spin_num,
    # NOT from any RNG consumption. This guarantees that
    # spin N always produces the same reel/effect seeds
    # regardless of Deck mode, Oil Can, or any other inter-spin events.
    var spin_num: int = 1
    var _popup = $'Pop-up Sprite/Pop-up'
    if _popup != null and _popup.has('spins'):
        spin_num = int(_popup.spins) + 1
    var spin_val: int = _bh_derive_seed(_bh_rng_landlord_seed, 'spin_' + str(spin_num))
    _bh_rng_reel   = PCGRng.new(_bh_derive_seed(spin_val, 'reel'))
    _bh_rng_effect = PCGRng.new(_bh_derive_seed(spin_val, 'effect'))
    _bh_rng_reel_shuffle = PCGRng.new(_bh_derive_seed(spin_val, 'reel_shuffle'))
    _bh_rng_effect_shuffle = PCGRng.new(_bh_derive_seed(spin_val, 'effect_shuffle'))
    _bh_rng_oil_can = PCGRng.new(_bh_derive_seed(spin_val, 'oil_can'))

# ============================================================
# RNG state persistence — sidecar file for Continue support
# ============================================================

# Called by SaveGamePatch (save_game Postfix).
# Dumps all 19 PCG stream (state, inc) pairs + seed metadata + fingerprint.
func _bh_save_rng_state():
    if _bh_rng_sym_rarity == null:
        return
    var f = File.new()
    var dir = Directory.new()
    if not dir.dir_exists(""user://betterHistory""):
        dir.make_dir(""user://betterHistory"")
    f.open(""user://betterHistory/rng_state.json"", File.WRITE)
    f.store_string(JSON.print({
        ""version"": 1,
        ""run_id"": _bh_run_id,
        ""seed_type"": _bh_rng_seed_type,
        ""seed_input"": _bh_rng_seed_input,
        ""landlord_seed"": _bh_rng_landlord_seed,
        ""victory_achieved"": _bh_victory_achieved,
        ""fingerprint"": {
            ""total_runs"": $'Pop-up Sprite/Pop-up'.total_runs,
            ""spins"": $'Pop-up Sprite/Pop-up'.spins,
            ""coins"": $'Coins'.coins
        },
        ""streams"": {
            ""sym_rarity"":    [str(_bh_rng_sym_rarity.state), str(_bh_rng_sym_rarity.inc)],
            ""sym_common"":     [str(_bh_rng_sym_common.state),str(_bh_rng_sym_common.inc)],
            ""sym_uncommon"":   [str(_bh_rng_sym_uncommon.state),str(_bh_rng_sym_uncommon.inc)],
            ""sym_rare"":       [str(_bh_rng_sym_rare.state),  str(_bh_rng_sym_rare.inc)],
            ""sym_vrare"":      [str(_bh_rng_sym_vrare.state), str(_bh_rng_sym_vrare.inc)],
            ""fineprint"":      [str(_bh_rng_fineprint.state), str(_bh_rng_fineprint.inc)],
            ""cosmetic"":       [str(_bh_rng_cosmetic.state),  str(_bh_rng_cosmetic.inc)],
            ""forced_rarity"":  [str(_bh_rng_forced_rarity.state), str(_bh_rng_forced_rarity.inc)],
            ""reel"":           [str(_bh_rng_reel.state),      str(_bh_rng_reel.inc)],
            ""effect"":         [str(_bh_rng_effect.state),    str(_bh_rng_effect.inc)],
            ""scratch"":        [str(_bh_rng_scratch.state),   str(_bh_rng_scratch.inc)],
            ""reel_shuffle"":   [str(_bh_rng_reel_shuffle.state), str(_bh_rng_reel_shuffle.inc)],
            ""effect_shuffle"": [str(_bh_rng_effect_shuffle.state), str(_bh_rng_effect_shuffle.inc)],
            ""oil_can"":        [str(_bh_rng_oil_can.state), str(_bh_rng_oil_can.inc)],
        },
        ""item_cursor"":    _bh_item_cursor.duplicate(true),
        ""item_seq_round"": _bh_item_seq_round,
    }))
    f.close()

# Create a PCGRng directly from a saved [state, inc] pair.
# Bypasses _init entirely — just overwrites internal fields.
func _bh_make_rng_from(pair) -> PCGRng:
    var r = PCGRng.new(0)
    r.state = int(pair[0])
    r.inc   = int(pair[1])
    return r

# Called by ContinueGamePatch (continue_game Postfix, after load_data).
# Restores all 19 streams from sidecar. Returns false if sidecar missing,
# version mismatch, or fingerprint doesn't match current save state.
func _bh_restore_rng_state():
    var f = File.new()
    var path = ""user://betterHistory/rng_state.json""
    if not f.file_exists(path):
        return false
    if f.open(path, File.READ) != OK:
        return false
    var text = f.get_as_text()
    f.close()
    var parsed = JSON.parse(text)
    if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
        return false
    var data = parsed.result
    if int(data.get(""version"", 0)) != 1:
        return false

    # Fingerprint validation — refuse restore if sidecar doesn't match this save
    var fp = data.get(""fingerprint"", {})
    if typeof(fp) != TYPE_DICTIONARY:
        return false
    if int(fp.get(""total_runs"", 0)) != $'Pop-up Sprite/Pop-up'.total_runs:
        return false
    if int(fp.get(""spins"", 0)) != $'Pop-up Sprite/Pop-up'.spins:
        return false
    if int(fp.get(""coins"", 0)) != $'Coins'.coins:
        return false

    _bh_rng_seed_type     = str(data.get(""seed_type"", """"))
    _bh_rng_seed_input    = str(data.get(""seed_input"", """"))
    _bh_rng_landlord_seed = int(data.get(""landlord_seed"", 0))

    # Restore run_id so the events temp file can be found
    var _saved_run_id = str(data.get(""run_id"", """"))
    if _saved_run_id != """":
        _bh_run_id = _saved_run_id

    # Load pre-close events from temp dump, truncated to save point
    if has_method(""_bh_load_events_for_continue""):
        var _save_spins = int(fp.get(""spins"", 0))
        _bh_load_events_for_continue(_save_spins)

    # Force the next ending to flush — sidecar events may be from a run
    # that was already flushed once.  Restore victory_achieved from the
    # sidecar so cold-boot Continue preserves the semantic flag.
    _bh_flushed_at_spin = -1
    _bh_victory_achieved = bool(data.get(""victory_achieved"", false))

    var st = data.get(""streams"", {})
    if typeof(st) != TYPE_DICTIONARY:
        return false

    _bh_rng_sym_rarity  = _bh_make_rng_from(st[""sym_rarity""])
    _bh_rng_sym_common   = _bh_make_rng_from(st[""sym_common""])
    _bh_rng_sym_uncommon = _bh_make_rng_from(st[""sym_uncommon""])
    _bh_rng_sym_rare     = _bh_make_rng_from(st[""sym_rare""])
    _bh_rng_sym_vrare    = _bh_make_rng_from(st[""sym_vrare""])
    _bh_rng_fineprint    = _bh_make_rng_from(st[""fineprint""])
    _bh_rng_cosmetic     = _bh_make_rng_from(st[""cosmetic""])
    _bh_rng_forced_rarity = _bh_make_rng_from(st[""forced_rarity""])
    _bh_rng_reel         = _bh_make_rng_from(st[""reel""])
    _bh_rng_effect       = _bh_make_rng_from(st[""effect""])
    _bh_rng_scratch      = _bh_make_rng_from(st[""scratch""])
    _bh_rng_reel_shuffle   = _bh_make_rng_from(st[""reel_shuffle""])
    _bh_rng_effect_shuffle = _bh_make_rng_from(st[""effect_shuffle""])
    _bh_rng_oil_can        = _bh_make_rng_from(st[""oil_can""])

    # Restore item sequence cursors (JSON float → int, B3 fix)
    if data.has(""item_cursor""):
        _bh_item_cursor = {}
        for k in data[""item_cursor""].keys():
            _bh_item_cursor[k] = int(data[""item_cursor""][k])
    if data.has(""item_seq_round""):
        _bh_item_seq_round = int(data[""item_seq_round""])
    _bh_item_seq = {}   # clear; will be rebuilt on next ensure

    # Sync Godot global RNG
    seed(_bh_rng_landlord_seed)
    return true

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
# _bh_end_run is re-entrant and debounced — safe to call unconditionally.
func _notification(what: int):
    if what == 1006:
        if _bh_events.size() > 0:
            _bh_end_run(""quit"")

# ============================================================
# skip-owned item sequences — deterministic, prefix-stable
# ============================================================

# Build the shuffle domain for a rarity: full set minus structural exclusions
# (NOT minus owned/destroyed — that's handled by the pool filter at call site)
func _bh_item_shuffle_domain(rarity: String) -> Array:
    var db = $""/root/Main"".rarity_database['items']
    if not db.has(rarity):
        return []
    var domain = db[rarity].duplicate(true)
    var tbe = []
    for c in domain:
        if $""/root/Main"".is_mod_disabled(c):
            tbe.push_back(c)
    if not $""/root/Main/Stats Sprite/Stats"".essences_unlocked and not $""/root/Main"".demo:
        if domain.has('dishwasher'):
            tbe.push_back('dishwasher')
        if domain.has('popsicle'):
            tbe.push_back('popsicle')
    for c in tbe:
        domain.erase(c)
    return domain

# Build shuffle sequences for all five item rarities for a given round.
# Does NOT touch _bh_item_cursor (cursor is managed by _bh_ensure_item_seqs).
func _bh_build_item_seqs(round_num: int):
    _bh_item_seq = {}
    for rar in ['common', 'uncommon', 'rare', 'very_rare', 'essence']:
        var domain = _bh_item_shuffle_domain(rar)
        domain.sort()   # normalise input order
        var rng = PCGRng.new(_bh_derive_seed(_bh_rng_landlord_seed,
            'itemseq_' + rar + '_' + str(round_num)))
        rng.custom_shuffle(domain)
        _bh_item_seq[rar] = domain

# Ensure the per-round item sequences are ready.
# New round: rebuild seqs + reset cursors.
# Same round after load: rebuild seqs only, preserve cursors.
func _bh_ensure_item_seqs():
    var r = $'Pop-up Sprite/Pop-up'.times_rent_paid
    if _bh_item_seq_round != r:
        _bh_item_seq_round = r
        _bh_item_rarity_ctr = 0
        _bh_build_item_seqs(r)
        _bh_item_cursor = {}
        for rar in _bh_item_seq.keys():
            _bh_item_cursor[rar] = 0
    elif _bh_item_seq.empty():
        _bh_build_item_seqs(r)

# Deterministic per-card rarity roll for add_item.
# Uses (seed, round, counter) — decoupled from consumption history.
# Called by _bh_c_rarity_randf (ChoiceRngPatch) for add_item emails.
func _bh_item_rarity_randf() -> float:
    var r = $'Pop-up Sprite/Pop-up'.times_rent_paid
    var c = _bh_item_rarity_ctr
    _bh_item_rarity_ctr = c + 1
    var rng = PCGRng.new(_bh_derive_seed(_bh_rng_landlord_seed,
        'itmrarity_' + str(r) + '_' + str(c)))
    return rng.randf()
";
}
