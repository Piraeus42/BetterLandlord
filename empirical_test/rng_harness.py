#!/usr/bin/env python3
"""
BetterLandlord RNG Empirical Test Harness
==========================================
Faithful GDScript→Python port of the mod's PCGRng, FNV-1a, djb2.
Preserves all 64-bit signed integer quirks exactly as they appear in
RngInfrastructureSourceMod.cs:26-55.

Tests:
  Task 1a: 100M steady-state randf() — 1000-bin histogram + threshold pass rates
  Task 1b: 1M+ first-draw randf() — ephemeral PCGRng instances
  Task 2:  Rarity determination end-to-end simulation (10M rolls)
  Task 3:  Skip-owned / with-replacement selection comparison
"""

import sys
import math
import time
import array
import struct

# ============================================================
# Constants (verbatim from RngInfrastructureSourceMod.cs)
# ============================================================
PCG_DEFAULT_INC = 1442695040888963407
PCG_MULT        = 6364136223846793005
MASK_63         = 0x7FFFFFFFFFFFFFFF   # max positive signed 64-bit
MASK_31         = 0x7FFFFFFF           # max positive signed 32-bit
MASK_64         = 0xFFFFFFFFFFFFFFFF   # full 64-bit unsigned mask

DENOMINATOR     = 2147483648.0         # 2^31


# ============================================================
# PCGRng — GDScript→Python faithful port
# ============================================================
class PCGRng:
    """Exact port of the GDScript PCGRng class from RngInfrastructureSourceMod.cs:31-82.

    KEY QUIRKS PRESERVED:
    - 64-bit signed state with MASK_63 (NOT MASK_64)
    - inc derived as (PCG_DEFAULT_INC << 1) | 1
    - _init: _step → state+=PCG_MULT → _step → _step
    - randf: (old>>18)^old, >>27, rot=old>>59 (NOT old>>58)
    - No uint32_t truncation on x (GDScript keeps full width)
    - 64-bit wrapping on left-shift overflow (simulated via MASK_64)
    - & MASK_31 applied only at the very end
    - Divide by 2^31 (2147483648.0), NOT 2^32
    """
    __slots__ = ('state', 'inc')

    def __init__(self, seed_val: int):
        self.state = seed_val & MASK_63
        self.inc = ((PCG_DEFAULT_INC << 1) | 1) & MASK_63
        self._step()
        self.state = (self.state + PCG_MULT) & MASK_63
        self._step()
        self._step()

    def _step(self) -> int:
        old = self.state
        # (old * MULT) can exceed 64 bits → mask to 64-bit, then MASK_63
        self.state = ((old * PCG_MULT) + self.inc) & MASK_63
        return old  # returns old state (pre-update)

    def randf(self) -> float:
        old = self._step()
        # GDScript: old is always in [0, 2^63), so old>>18 and XOR stay ≥0
        x = (old >> 18) ^ old
        # GDScript keeps full 64-bit width — no uint32_t truncation here
        x = x >> 27
        # GDScript: rot = old >> 59  (top 5 bits for rotation, 0..31)
        rot = old >> 59
        # GDScript left-shift: 64-bit signed wrapping on overflow
        # Simulate: mask with full 64 bits after left shift
        left_part = (x << ((-rot) & 31)) & MASK_64
        # If left_part has bit 63 set (negative in signed 64-bit),
        # GDScript interprets it as negative. The >> below is arithmetic.
        # Convert to signed 64-bit representation for the OR:
        if left_part >= 0x8000000000000000:
            left_part = left_part - 0x10000000000000000
        # GDScript: (x >> rot) — arithmetic right shift.
        # Both x and left_part may now be "signed" Python ints.
        # x is always non-negative (bit 63 = 0 per MASK_63 chain),
        # so arithmetic == logical for x >> rot.
        result = ((x >> rot) | left_part) & MASK_31
        return float(result) / DENOMINATOR

    def randi_max(self, max_val: int) -> int:
        return int(math.floor(self.randf() * float(max_val)))

    def pick(self, arr: list):
        if len(arr) == 0:
            return None
        return arr[self.randi_max(len(arr))]

    def custom_shuffle(self, arr: list):
        n = len(arr)
        for i in range(n - 1, 0, -1):
            j = int(math.floor(self.randf() * float(i + 1)))
            arr[i], arr[j] = arr[j], arr[i]

    def chance(self, percent: float) -> bool:
        return self.randf() * 100.0 < percent


# ============================================================
# Hash functions (verbatim from RngInfrastructureSourceMod.cs:89-101)
# ============================================================
def fnv1a(text: str) -> int:
    """FNV-1a: string → 31-bit positive int"""
    h = 2166136261
    for ch in text:
        h = (h ^ ord(ch)) & MASK_63
        h = (h * 16777619) & MASK_63
    return h & MASK_31


def derive_seed(base: int, name: str) -> int:
    """djb2: int + string → 31-bit positive int (seed derivation)"""
    h = base & MASK_63
    for ch in name:
        h = (((h << 5) + h) ^ ord(ch)) & MASK_63
    return h & MASK_31


# ============================================================
# Generate first 10 randf() values for a given seed (verification)
# ============================================================
def verify_reference_output(seed_val: int):
    """Print first 10 randf() values for manual verification."""
    rng = PCGRng(seed_val)
    print("=== PCGRng Verification ===")
    print(f"Seed: {seed_val} (0x{seed_val:X})")
    print(f"Inc:  {rng.inc} (0x{rng.inc:X})")
    print(f"Initial state: {rng.state} (0x{rng.state:X})")
    print()
    print("First 10 randf() values:")
    print(f"{'#':>4s}  {'randf()':>20s}  {'raw_int':>12s}  {'hex':>10s}")
    print("-" * 58)
    for i in range(10):
        rng2 = PCGRng(seed_val)  # fresh instance to verify reproducibility
        for _ in range(i + 1):
            val = rng2.randf()
        # Reconstruct the raw integer for comparison
        raw = int(val * DENOMINATOR)
        print(f"{i+1:4d}  {val:20.15f}  {raw:12d}  0x{raw:08X}")

    # Also show sequential output from a single instance
    print()
    print("Single-instance sequential output (should match above):")
    rng3 = PCGRng(seed_val)
    for i in range(10):
        val = rng3.randf()
        raw = int(val * DENOMINATOR)
        print(f"  [{i}]: {val:.15f}  raw={raw}  0x{raw:08X}")

    # Show internal state transitions for first 3 steps
    print()
    print("State transitions (first 3 _step + randf cycles):")
    rng4 = PCGRng(seed_val)
    for i in range(3):
        old_state = rng4.state
        val = rng4.randf()
        print(f"  step[{i}]: old_state=0x{old_state:016X}  new_state=0x{rng4.state:016X}  randf={val:.15f}")


# ============================================================
# TASK 1a: Steady-state randf() — 100M samples
# ============================================================
def task_1a_steady_state(seed_val: int, n_samples: int = 100_000_000):
    """100M randf() samples from a persistent PCGRng instance.

    Uses the seed derivation pattern of _bh_rng_sym_rarity:
    djb2(landlord_seed, 'sym_rarity')
    """
    print(f"\n{'='*70}")
    print(f"TASK 1a: Steady-State randf() — {n_samples:,} samples")
    print(f"{'='*70}")

    landlord_seed = seed_val
    rng_seed = derive_seed(landlord_seed, 'sym_rarity')
    rng = PCGRng(rng_seed)

    print(f"Landlord seed: {landlord_seed} (0x{landlord_seed:08X})")
    print(f"Derived seed ('sym_rarity'): {rng_seed} (0x{rng_seed:08X})")

    # Thresholds from game rarity_chances
    thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30]

    n_bins = 1000
    bin_counts = [0] * n_bins
    threshold_counts = {t: 0 for t in thresholds}

    t0 = time.time()
    chunk_size = 1_000_000

    for chunk_start in range(0, n_samples, chunk_size):
        chunk_end = min(chunk_start + chunk_size, n_samples)
        for _ in range(chunk_end - chunk_start):
            val = rng.randf()
            bin_idx = min(int(val * n_bins), n_bins - 1)
            bin_counts[bin_idx] += 1
            for t in thresholds:
                if val < t:
                    threshold_counts[t] += 1

        progress = chunk_end / n_samples * 100
        elapsed = time.time() - t0
        rate = chunk_end / elapsed if elapsed > 0 else 0
        print(f"  {chunk_end:>10,} samples ({progress:5.1f}%)  {rate:,.0f} samples/s")

    elapsed = time.time() - t0
    print(f"Total time: {elapsed:.1f}s")

    # --- 1000-bin histogram ---
    expected_per_bin = n_samples / n_bins
    print(f"\n--- 1000-bin Histogram (expected={expected_per_bin:.0f}/bin) ---")
    print(f"{'Bin':>6s}  {'Range':>12s}  {'Count':>12s}  {'Deviation':>10s}  {'Ratio':>8s}")
    print("-" * 62)

    # Show first 20 bins with detail
    for b in range(20):
        dev = bin_counts[b] - expected_per_bin
        ratio = bin_counts[b] / expected_per_bin
        lo = b / n_bins
        hi = (b + 1) / n_bins
        print(f"{b:6d}  [{lo:.3f},{hi:.3f})  {bin_counts[b]:12,d}  {dev:+12.1f}  {ratio:8.5f}")

    if n_bins > 20:
        print(f"  ... ({n_bins - 20} more bins)")
        # Show summary stats for all bins
        min_count = min(bin_counts)
        max_count = max(bin_counts)
        avg_count = sum(bin_counts) / n_bins
        variance = sum((c - avg_count)**2 for c in bin_counts) / n_bins
        std_dev = math.sqrt(variance)
        print(f"\nAll {n_bins} bins summary:")
        print(f"  Expected per bin: {expected_per_bin:.1f}")
        print(f"  Min:    {min_count:,}  ({min_count/expected_per_bin:.5f}x)")
        print(f"  Max:    {max_count:,}  ({max_count/expected_per_bin:.5f}x)")
        print(f"  Mean:   {avg_count:,.1f}")
        print(f"  StdDev: {std_dev:,.1f}  (ratio: {std_dev/expected_per_bin:.5f})")

    # --- Threshold pass rates ---
    print(f"\n--- Threshold Pass Rates: P(randf() < t) ---")
    print(f"{'t':>8s}  {'Pass Count':>14s}  {'Empirical P':>14s}  {'Expected':>12s}  {'Ratio':>10s}")
    print("-" * 64)
    for t in thresholds:
        count = threshold_counts[t]
        empirical = count / n_samples
        ratio_val = empirical / t if t > 0 else float('nan')
        print(f"{t:8.4f}  {count:14,d}  {empirical:14.8f}  {t:12.8f}  {ratio_val:10.6f}")

    return bin_counts, threshold_counts


# ============================================================
# TASK 1b: First-draw randf() — ephemeral PCGRng instances
# ============================================================
def task_1b_first_draw(seed_val: int, n_samples: int = 1_050_000):
    """Create ephemeral PCGRng instances and take only the first randf().

    Uses the exact pattern from _bh_item_rarity_randf():
    rng = PCGRng.new(_bh_derive_seed(_bh_rng_landlord_seed, 'itmrarity_' + str(r) + '_' + str(c)))
    return rng.randf()

    Generates a large grid of (round, counter) pairs covering the game's
    parameter space and beyond.
    """
    print(f"\n{'='*70}")
    print(f"TASK 1b: First-Draw randf() — {n_samples:,} ephemeral instances")
    print(f"{'='*70}")

    landlord_seed = seed_val

    # Compute how many (round, counter) combos we need
    # Game uses round=0..11 (times_rent_paid), counter increments per card
    # For statistical power, we use a much wider range
    n_rounds = 1000
    n_counters_per_round = (n_samples + n_rounds - 1) // n_rounds

    print(f"Landlord seed: {landlord_seed} (0x{landlord_seed:08X})")
    print(f"Rounds: 1..{n_rounds}, counters per round: 0..{n_counters_per_round-1}")
    print(f"Total instances: {n_rounds * n_counters_per_round:,}")

    # Thresholds
    thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30]
    n_bins = 1000
    bin_counts = [0] * n_bins
    threshold_counts = {t: 0 for t in thresholds}

    actual_samples = 0
    t0 = time.time()

    for r in range(1, n_rounds + 1):
        for c in range(n_counters_per_round):
            seed_str = f'itmrarity_{r}_{c}'
            child_seed = derive_seed(landlord_seed, seed_str)
            rng = PCGRng(child_seed)
            val = rng.randf()  # ONLY the first randf() from this instance

            bin_idx = min(int(val * n_bins), n_bins - 1)
            bin_counts[bin_idx] += 1

            for t in thresholds:
                if val < t:
                    threshold_counts[t] += 1

            actual_samples += 1

        if r % 100 == 0:
            elapsed = time.time() - t0
            rate = actual_samples / elapsed if elapsed > 0 else 0
            print(f"  round={r:4d}  {actual_samples:>10,} samples  {rate:,.0f} samples/s")

    elapsed = time.time() - t0
    print(f"Total time: {elapsed:.1f}s  Actual samples: {actual_samples:,}")

    expected_per_bin = actual_samples / n_bins

    # --- 1000-bin histogram ---
    print(f"\n--- 1000-bin Histogram [FIRST DRAW] (expected={expected_per_bin:.0f}/bin) ---")
    print(f"{'Bin':>6s}  {'Range':>12s}  {'Count':>12s}  {'Deviation':>10s}  {'Ratio':>8s}")
    print("-" * 62)

    for b in range(20):
        dev = bin_counts[b] - expected_per_bin
        ratio = bin_counts[b] / expected_per_bin
        lo = b / n_bins
        hi = (b + 1) / n_bins
        print(f"{b:6d}  [{lo:.3f},{hi:.3f})  {bin_counts[b]:12,d}  {dev:+12.1f}  {ratio:8.5f}")

    if n_bins > 20:
        print(f"  ... ({n_bins - 20} more bins)")
        min_count = min(bin_counts)
        max_count = max(bin_counts)
        avg_count = sum(bin_counts) / n_bins
        variance = sum((c - avg_count)**2 for c in bin_counts) / n_bins
        std_dev = math.sqrt(variance)
        print(f"\nAll {n_bins} bins summary:")
        print(f"  Expected per bin: {expected_per_bin:.1f}")
        print(f"  Min:    {min_count:,}  ({min_count/expected_per_bin:.5f}x)")
        print(f"  Max:    {max_count:,}  ({max_count/expected_per_bin:.5f}x)")
        print(f"  Mean:   {avg_count:,.1f}")
        print(f"  StdDev: {std_dev:,.1f}  (ratio: {std_dev/expected_per_bin:.5f})")

    # --- Threshold pass rates ---
    print(f"\n--- Threshold Pass Rates [FIRST DRAW]: P(randf() < t) ---")
    print(f"{'t':>8s}  {'Pass Count':>14s}  {'Empirical P':>14s}  {'Expected':>12s}  {'Ratio':>10s}")
    print("-" * 64)
    for t in thresholds:
        count = threshold_counts[t]
        empirical = count / actual_samples
        ratio_val = empirical / t if t > 0 else float('nan')
        print(f"{t:8.4f}  {count:14,d}  {empirical:14.8f}  {t:12.8f}  {ratio_val:10.6f}")

    return bin_counts, threshold_counts, actual_samples


# ============================================================
# TASK 1c: Compare steady-state vs first-draw distributions
# ============================================================
def task_1c_compare(steady_bins, steady_n, first_bins, first_n):
    """Compare steady-state and first-draw distributions, especially low end."""
    print(f"\n{'='*70}")
    print(f"TASK 1c: Steady-State vs First-Draw Comparison")
    print(f"{'='*70}")

    n_bins = len(steady_bins)

    # Focus on [0, 0.05) — first 50 bins
    print(f"\n--- Low-End Comparison [0.000, 0.050) — bins 0-49 ---")
    print(f"{'Bin':>6s}  {'Range':>12s}  {'Steady':>12s}  {'FirstDr':>12s}  {'Ratio(S)':>10s}  {'Ratio(FD)':>10s}  {'FD/S':>10s}")
    print("-" * 86)

    for b in range(50):
        s_exp = steady_n / n_bins
        f_exp = first_n / n_bins
        s_ratio = steady_bins[b] / s_exp if s_exp > 0 else 0
        f_ratio = first_bins[b] / f_exp if f_exp > 0 else 0
        fd_vs_s = f_ratio / s_ratio if s_ratio > 0 else float('nan')
        lo = b / n_bins
        hi = (b + 1) / n_bins
        print(f"{b:6d}  [{lo:.3f},{hi:.3f})  {steady_bins[b]:12,d}  {first_bins[b]:12,d}  {s_ratio:10.5f}  {f_ratio:10.5f}  {fd_vs_s:10.5f}")

    # Summary of low-end aggregate
    for cutoff_bins, label in [(10, '[0.000, 0.010)'), (20, '[0.000, 0.020)'), (50, '[0.000, 0.050)')]:
        s_sum = sum(steady_bins[:cutoff_bins])
        f_sum = sum(first_bins[:cutoff_bins])
        s_exp_sum = steady_n * cutoff_bins / n_bins
        f_exp_sum = first_n * cutoff_bins / n_bins
        print(f"\n{label}:")
        print(f"  Steady:  {s_sum:,} / {steady_n:,} = {s_sum/steady_n:.6f}  (exp={s_exp_sum/steady_n:.6f}, ratio={s_sum/s_exp_sum:.5f})")
        print(f"  FirstDr: {f_sum:,} / {first_n:,} = {f_sum/first_n:.6f}  (exp={f_exp_sum/first_n:.6f}, ratio={f_sum/f_exp_sum:.5f})")


# ============================================================
# TASK 2: Rarity determination end-to-end
# ============================================================
def task_2_rarity_simulation(seed_val: int, n_rolls: int = 10_000_000):
    """Simulate rarity determination for both symbol and item paths.

    Uses the actual rarity_chances from Main.tscn__1.gd:2945-2959
    and the mod's RNG routing (ChoiceRngPatch.cs:21-49).
    """
    print(f"\n{'='*70}")
    print(f"TASK 2: Rarity Determination Simulation — {n_rolls:,} rolls")
    print(f"{'='*70}")

    # --- Vanilla behavior documentation (from game source) ---
    print("""
=== VANILLA BEHAVIOR ANSWERS ===

Q1: Single roll vs multiple rolls?
A1: SINGLE roll. The original code at Pop-up.tscn__1.gd:1346-1380
    generates ONE rand_range(0,1) per card, then cascades through
    cumulative thresholds:

    if rand_num < r_chances.very_rare and pool_has("very_rare"):
        rarity = "very_rare"
    elif rand_num < r_chances.very_rare + r_chances.rare and pool_has("rare"):
        rarity = "rare"
    elif rand_num < r_chances.very_rare + r_chances.rare + r_chances.uncommon and pool_has("uncommon"):
        rarity = "uncommon"
    elif pool_has("common"):
        rarity = "common"

    The mod's _bh_c_rarity_randf() (ChoiceRngPatch.cs:21-38) also
    returns ONE float per card. Both roll exactly once per card.

Q2: Does card_pool exclude owned items before selection?
A2: YES, for the main add_cards branch. Pop-up.tscn__1.gd:1253-1257:

    card_pool = rarity_database["items"].duplicate(true)
    for i in Items.items:
        card_pool[i.rarity].erase(i.type)        # remove owned
    for i in Items.recently_destroyed_items:
        card_pool[i.rarity].erase(i.type)        # remove recently destroyed

    For the ELSE branch (line 1424-1427), an UNFILTERED pool is rebuilt:

    card_pool = rarity_database["items"][rarity].duplicate(true)
    for d in cards:
        card_pool.erase(d.data.type)   # only same-choice dedup
    card.data = database[card_pool[rand_range(0, card_pool.size())]]

    The mod catches this via _bh_c_pick_item filtering (ChoiceRngPatch.cs:78-92).

Q3: With or without replacement within one add_cards event?
A3: WITHOUT replacement. Card erasure at lines 1399,1406,1426,1448,2160.
    After picking symbol X from rarity Y's pool, X is erased from that pool.
    Same for items (line 1426). The mod's skip-owned preserves this via
    cursor advancement through the shuffled sequence.
""")

    landlord_seed = seed_val

    # Rarity chances by rent payment (times_rent_paid)
    # From Main.tscn__1.gd:2945-2959
    rarity_chances_table = {
        0: {"symbols": {"uncommon": 0.0,  "rare": 0.0,   "very_rare": 0.0},
            "items":   {"uncommon": 0.0,  "rare": 0.0,   "very_rare": 0.0}},
        1: {"symbols": {"uncommon": 0.10, "rare": 0.0,   "very_rare": 0.0},
            "items":   {"uncommon": 0.0,  "rare": 0.0,   "very_rare": 0.0}},
        2: {"symbols": {"uncommon": 0.20, "rare": 0.010, "very_rare": 0.0},
            "items":   {"uncommon": 0.10, "rare": 0.0,   "very_rare": 0.0}},
        3: {"symbols": {"uncommon": 0.25, "rare": 0.010, "very_rare": 0.0},
            "items":   {"uncommon": 0.20, "rare": 0.025, "very_rare": 0.0}},
        4: {"symbols": {"uncommon": 0.29, "rare": 0.015, "very_rare": 0.005},
            "items":   {"uncommon": 0.25, "rare": 0.025, "very_rare": 0.0}},
        5: {"symbols": {"uncommon": 0.30, "rare": 0.015, "very_rare": 0.005},
            "items":   {"uncommon": 0.30, "rare": 0.0375,"very_rare": 0.0125}},
        6: {"symbols": {"uncommon": 0.30, "rare": 0.015, "very_rare": 0.005},
            "items":   {"uncommon": 0.375,"rare": 0.050, "very_rare": 0.015}},
    }

    # Simulate for each round
    for round_num in range(7):
        chances = rarity_chances_table[round_num]

        for domain in ["symbols", "items"]:
            ch = chances[domain]
            uc = ch["uncommon"]
            ra = ch["rare"]
            vr = ch["very_rare"]
            co = 1.0 - uc - ra - vr  # common is the remainder

            # Nominal probabilities
            nominal = {
                "common":    max(0, co),
                "uncommon":  uc,
                "rare":      ra,
                "very_rare": vr,
            }

            # --- Mod RNG path ---
            # Uses per-card ephemeral RNG: _bh_item_rarity_randf()
            # seed_str = 'itmrarity_{round}_{counter}'
            mod_counts = {"common": 0, "uncommon": 0, "rare": 0, "very_rare": 0}
            for c in range(n_rolls):
                seed_str = f'itmrarity_{round_num}_{c}'
                child_seed = derive_seed(landlord_seed, seed_str)
                rng = PCGRng(child_seed)
                rand_num = rng.randf()  # one randf() per card

                # Rarity cascade matching game code
                if rand_num < vr and vr > 0:
                    mod_counts["very_rare"] += 1
                elif rand_num < vr + ra and ra > 0:
                    mod_counts["rare"] += 1
                elif rand_num < vr + ra + uc and uc > 0:
                    mod_counts["uncommon"] += 1
                else:
                    mod_counts["common"] += 1

            # --- Ideal uniform RNG ---
            # Use Python's random for comparison — same logic, ideal RNG
            import random as py_random
            py_random.seed(42 + round_num * 100)
            ideal_counts = {"common": 0, "uncommon": 0, "rare": 0, "very_rare": 0}
            for _ in range(n_rolls):
                rand_num = py_random.random()  # Mersenne Twister, near-ideal [0,1)
                if rand_num < vr and vr > 0:
                    ideal_counts["very_rare"] += 1
                elif rand_num < vr + ra and ra > 0:
                    ideal_counts["rare"] += 1
                elif rand_num < vr + ra + uc and uc > 0:
                    ideal_counts["uncommon"] += 1
                else:
                    ideal_counts["common"] += 1

            # Print table
            print(f"\nRound {round_num} — {domain} — {n_rolls:,} rolls")
            print(f"  Nominal probs: common={co:.4f}  uncommon={uc:.4f}  rare={ra:.4f}  very_rare={vr:.4f}")
            print(f"  {'Tier':>12s}  {'Ideal':>10s}  {'Mod':>10s}  {'Nominal':>10s}  {'|ΔIdeal|':>10s}  {'|ΔMod|':>10s}")
            print(f"  {'-'*70}")

            for tier in ["common", "uncommon", "rare", "very_rare"]:
                n = nominal[tier]
                i_pct = ideal_counts[tier] / n_rolls
                m_pct = mod_counts[tier] / n_rolls
                delta_ideal = i_pct - n
                delta_mod = m_pct - n
                print(f"  {tier:>12s}  {i_pct:10.6f}  {m_pct:10.6f}  {n:10.6f}  {delta_ideal:+10.6f}  {delta_mod:+10.6f}")


# ============================================================
# TASK 3: Skip-owned / with-replacement selection comparison
# ============================================================
def task_3_selection_comparison(seed_val: int, n_events: int = 1_000_000):
    """Compare skip-owned (mod) vs with-replacement (vanilla) item selection.

    Simulates the mod's _bh_build_item_seqs + _bh_c_pick_item logic
    against the vanilla card_pool[rand_range(...)] + erase logic.
    """
    print(f"\n{'='*70}")
    print(f"TASK 3: Selection Comparison — {n_events:,} events")
    print(f"{'='*70}")

    landlord_seed = seed_val

    # Synthetic item pools matching typical game structure
    # Items per rarity (approximate from game data)
    item_pools = {
        "common":    [f"common_{i}"  for i in range(25)],
        "uncommon":  [f"uncommon_{i}" for i in range(15)],
        "rare":      [f"rare_{i}"     for i in range(10)],
        "very_rare": [f"vrare_{i}"    for i in range(5)],
    }

    # Simulate ownership: player owns ~30% of items at game start
    owned_items = set()
    for rarity, items in item_pools.items():
        n_owned = len(items) // 3
        for item in items[:n_owned]:
            owned_items.add(item)

    print(f"Pool sizes: " + ", ".join(f"{r}={len(p)}" for r, p in item_pools.items()))
    print(f"Owned items: {len(owned_items)}")

    # K values to test (cards offered per event)
    k_values = [3, 4, 5]

    import random as py_random
    py_random.seed(12345)

    for K in k_values:
        print(f"\n--- K={K} cards per event ---")

        # --- Mod path: skip-owned with shuffle sequences ---
        mod_pick_counts = {rarity: {item: 0 for item in items}
                          for rarity, items in item_pools.items()}
        mod_rarity_seq = {"common": 0, "uncommon": 0, "rare": 0, "very_rare": 0}

        for event in range(n_events):
            # Rebuild sequences for this event (like _bh_build_item_seqs)
            sequences = {}
            cursors = {}
            for rarity in ["common", "uncommon", "rare", "very_rare"]:
                domain = sorted(item_pools[rarity])  # domain.sort()
                seed_str = f'itemseq_{rarity}_1_{event}'
                child_seed = derive_seed(landlord_seed, seed_str)
                rng = PCGRng(child_seed)
                rng.custom_shuffle(domain)
                sequences[rarity] = domain
                cursors[rarity] = 0

            # Pick K items using skip-owned
            for pick_num in range(K):
                # Random rarity via mod's _bh_item_rarity_randf
                rar_seed_str = f'itmrarity_1_{event * K + pick_num}'
                rar_seed = derive_seed(landlord_seed, rar_seed_str)
                rar_rng = PCGRng(rar_seed)
                rr = rar_rng.randf()

                # Rarity determination (round 6+ item chances)
                if rr < 0.015:
                    rarity = "very_rare"
                elif rr < 0.015 + 0.05:
                    rarity = "rare"
                elif rr < 0.015 + 0.05 + 0.375:
                    rarity = "uncommon"
                else:
                    rarity = "common"

                # Skip-owned from shuffled sequence
                seq = sequences[rarity]
                cursor = cursors[rarity]
                picked = None

                # Check remaining items against owned set
                for idx in range(cursor, len(seq)):
                    cand = seq[idx]
                    if cand not in owned_items:
                        picked = cand
                        cursors[rarity] = idx + 1
                        break

                if picked is None:
                    # Fallback: deterministic from pool (not owned)
                    available = [item for item in item_pools[rarity] if item not in owned_items]
                    if available:
                        fb_idx = derive_seed(landlord_seed, f'itemfb_{rarity}_{event}_{pick_num}') % len(available)
                        picked = available[fb_idx]
                    else:
                        picked = f"{rarity}_fallback"
                    cursors[rarity] = len(seq)  # exhausted

                if picked:
                    mod_pick_counts[rarity][picked] += 1
                    mod_rarity_seq[rarity] += 1

        # --- Vanilla path: with-replacement, rand_range + erase ---
        vanilla_pick_counts = {rarity: {item: 0 for item in items}
                               for rarity, items in item_pools.items()}
        vanilla_rarity_counts = {"common": 0, "uncommon": 0, "rare": 0, "very_rare": 0}

        for _ in range(n_events):
            # Build card_pool (like vanilla Pop-up.tscn__1.gd:1252-1257)
            card_pool = {rarity: items.copy() for rarity, items in item_pools.items()}

            for pick_num in range(K):
                rr = py_random.random()
                if rr < 0.015:
                    rarity = "very_rare"
                elif rr < 0.015 + 0.05:
                    rarity = "rare"
                elif rr < 0.015 + 0.05 + 0.375:
                    rarity = "uncommon"
                else:
                    rarity = "common"

                pool = card_pool[rarity]
                if pool:
                    idx = py_random.randint(0, len(pool) - 1)
                    picked = pool[idx]
                    pool.pop(idx)  # erase (without replacement within event)
                    vanilla_pick_counts[rarity][picked] += 1
                    vanilla_rarity_counts[rarity] += 1

        # --- Comparison ---
        print(f"\n  Rarity distribution ({K} picks × {n_events:,} events):")
        print(f"  {'Rarity':>12s}  {'Mod':>10s}  {'Vanilla':>10s}  {'Mod%':>10s}  {'Van%':>10s}  {'Ratio':>10s}")
        print(f"  {'-'*60}")
        total_mod = sum(mod_rarity_seq.values())
        total_van = sum(vanilla_rarity_counts.values())
        for rarity in ["common", "uncommon", "rare", "very_rare"]:
            m = mod_rarity_seq[rarity]
            v = vanilla_rarity_counts[rarity]
            mp = m / total_mod * 100 if total_mod > 0 else 0
            vp = v / total_van * 100 if total_van > 0 else 0
            ratio = mp / vp if vp > 0 else float('nan')
            print(f"  {rarity:>12s}  {m:10,d}  {v:10,d}  {mp:9.4f}%  {vp:9.4f}%  {ratio:10.5f}")

        # Per-item distribution analysis
        print(f"\n  Per-item pick count distribution:")
        all_mod_counts = []
        all_van_counts = []
        for rarity in ["common", "uncommon", "rare", "very_rare"]:
            all_mod_counts.extend(mod_pick_counts[rarity].values())
            all_van_counts.extend(vanilla_pick_counts[rarity].values())

        mod_nonzero = [c for c in all_mod_counts if c > 0]
        van_nonzero = [c for c in all_van_counts if c > 0]

        if mod_nonzero:
            print(f"  Mod:    mean={sum(mod_nonzero)/len(mod_nonzero):.1f}  "
                  f"min={min(mod_nonzero)}  max={max(mod_nonzero)}  "
                  f"nonzero={len(mod_nonzero)}/{len(all_mod_counts)}")
        if van_nonzero:
            print(f"  Vanilla: mean={sum(van_nonzero)/len(van_nonzero):.1f}  "
                  f"min={min(van_nonzero)}  max={max(van_nonzero)}  "
                  f"nonzero={len(van_nonzero)}/{len(all_van_counts)}")


# ============================================================
# MAIN
# ============================================================
def main():
    # Use a fixed seed for reproducibility
    # This simulates a player using seed "TESTSEED1" → FNV-1a → landlord_seed
    test_seed_string = "TESTSEED1"
    landlord_seed = fnv1a(test_seed_string)

    print("=" * 70)
    print("BetterLandlord RNG Empirical Test Suite")
    print("=" * 70)
    print(f"Test seed string: '{test_seed_string}'")
    print(f"Landlord seed (FNV-1a): {landlord_seed} (0x{landlord_seed:08X})")
    print()

    # --- Verification ---
    # Use a small, well-known seed for the reference output
    ref_seed = 42  # simple seed for verification
    verify_reference_output(ref_seed)

    # Also show with actual landlord_seed
    verify_reference_output(landlord_seed)

    # --- TASK 1a: Steady-state ---
    # Use 10M for quicker iteration, 100M for final
    n_steady = 10_000_000
    steady_bins, steady_thresh = task_1a_steady_state(landlord_seed, n_steady)

    # --- TASK 1b: First-draw ---
    first_bins, first_thresh, first_n = task_1b_first_draw(landlord_seed, 1_050_000)

    # --- TASK 1c: Comparison ---
    task_1c_compare(steady_bins, n_steady, first_bins, first_n)

    # --- TASK 2: Rarity ---
    task_2_rarity_simulation(landlord_seed, 10_000_000)

    # --- TASK 3: Selection ---
    task_3_selection_comparison(landlord_seed, 1_000_000)

    print("\n" + "=" * 70)
    print("All tests complete.")
    print("=" * 70)


if __name__ == "__main__":
    main()
