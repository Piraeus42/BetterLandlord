#!/usr/bin/env python3
"""
Fixed PCGRng — standard PCG32 XSH RR, correct 64-bit signed semantics.
GDScript simulation: arithmetic right shifts + explicit masks for logical results.
Output: full 32-bit / 2^32 denominator (not 31-bit / 2^31).
"""

import sys
import math
import time

# ============================================================
# Constants
# ============================================================
PCG_DEFAULT_INC = 1442695040888963407
PCG_MULT        = 6364136223846793005
DENOMINATOR     = 4294967296.0         # 2^32 (not 2^31!)


# ============================================================
# Fixed PCGRng — standard PCG32 XSH RR with GDScript signed 64-bit semantics
# ============================================================
class PCGRng_Fixed:
    """Standard PCG32 XSH RR implemented correctly for GDScript 64-bit signed.

    KEY DIFFERENCES from the buggy mod version:
    - State uses FULL 64 bits (bit 63 can be set). No MASK_63 truncation.
    - Arithmetic right shifts simulated, then masked for logical results.
    - rot = (old >> 59) & 0x1F ensures full 0..31 range.
    - Output is full 32-bit, divided by 2^32.
    - Seeding steps kept identical (no MASK_63).
    """
    __slots__ = ('state', 'inc')

    @staticmethod
    def _as_signed64(x: int) -> int:
        """Convert unsigned 64-bit → signed 64-bit for arithmetic shift."""
        x = x & 0xFFFFFFFFFFFFFFFF
        if x >= 0x8000000000000000:
            return x - 0x10000000000000000
        return x

    def __init__(self, seed_val: int):
        # Full 64-bit, no MASK_63
        self.state = seed_val & 0xFFFFFFFFFFFFFFFF
        self.inc = ((PCG_DEFAULT_INC << 1) | 1) & 0xFFFFFFFFFFFFFFFF
        self._step()
        self.state = (self.state + PCG_MULT) & 0xFFFFFFFFFFFFFFFF
        self._step()
        self._step()

    def _step(self) -> int:
        old = self.state
        # Natural 64-bit wrap (simulating GDScript signed overflow = complement wrap)
        self.state = (old * PCG_MULT + self.inc) & 0xFFFFFFFFFFFFFFFF
        return old

    def randf(self) -> float:
        old = self._step()  # advance state and get old value

        # Convert to signed 64-bit for arithmetic right shifts
        old_s64 = self._as_signed64(old)

        # Logical right shift 18: arithmetic >> then clear sign-extended bits
        lsr18 = (old_s64 >> 18) & 0x3FFFFFFFFFFF

        # XOR (works correctly on unsigned)
        x = lsr18 ^ old

        # (x >> 27) & 0xFFFFFFFF — arithmetic >> then take lower 32 bits
        x_s64 = self._as_signed64(x)
        x = (x_s64 >> 27) & 0xFFFFFFFF

        # Rotation amount: arithmetic >> 59, mask to 0..31
        rot = (old_s64 >> 59) & 0x1F

        # 32-bit rotate right
        result = ((x >> rot) | (x << ((-rot) & 31))) & 0xFFFFFFFF

        return float(result) / DENOMINATOR

    def randf_no_sign_sim(self) -> float:
        """Same algorithm WITHOUT signed arithmetic simulation.
        For comparison: this is what you'd get if all shifts were logical.
        """
        old = self._step() & 0xFFFFFFFFFFFFFFFF

        lsr18 = (old >> 18) & 0x3FFFFFFFFFFF
        x = (lsr18 ^ old)
        x = (x >> 27) & 0xFFFFFFFF
        rot = (old >> 59) & 0x1F
        result = ((x >> rot) | (x << ((-rot) & 31))) & 0xFFFFFFFF
        return float(result) / DENOMINATOR


# ============================================================
# Hash functions (unchanged)
# ============================================================
MASK_63 = 0x7FFFFFFFFFFFFFFF
MASK_31 = 0x7FFFFFFF

def fnv1a(text: str) -> int:
    h = 2166136261
    for ch in text:
        h = (h ^ ord(ch)) & MASK_63
        h = (h * 16777619) & MASK_63
    return h & MASK_31

def derive_seed(base: int, name: str) -> int:
    h = base & MASK_63
    for ch in name:
        h = (((h << 5) + h) ^ ord(ch)) & MASK_63
    return h & MASK_31


# ============================================================
# Test helper
# ============================================================
def test_fixed_version(label, rng_class, seed_val, n_samples=10_000_000):
    print(f"\n{'='*60}")
    print(f"Testing: {label}")
    print(f"{'='*60}")
    print(f"  Samples: {n_samples:,}")
    print(f"  Seed: {seed_val} (0x{seed_val:X})")

    rng = rng_class(seed_val)

    # Show first 10 randf() values
    print(f"\n  First 10 randf() values:")
    rng2 = rng_class(seed_val)
    for i in range(10):
        v = rng2.randf()
        raw = int(v * DENOMINATOR)
        print(f"    [{i}]: {v:.15f}  raw=0x{raw:08X}")

    # Histogram
    n_bins = 1000
    bins = [0] * n_bins
    thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30, 0.50]
    thresh_counts = {t: 0 for t in thresholds}

    t0 = time.time()
    chunk = 1_000_000
    for chk_start in range(0, n_samples, chunk):
        chk_end = min(chk_start + chunk, n_samples)
        for _ in range(chk_end - chk_start):
            val = rng.randf()
            bi = min(int(val * n_bins), n_bins - 1)
            bins[bi] += 1
            for t in thresholds:
                if val < t:
                    thresh_counts[t] += 1
        progress = chk_end / n_samples * 100
        elapsed = time.time() - t0
        rate = chk_end / elapsed if elapsed > 0 else 0
        print(f"    {chk_end:>10,} ({progress:5.1f}%)  {rate:,.0f} samples/s", end='\r')

    elapsed = time.time() - t0
    print(f"\n  Time: {elapsed:.1f}s")

    expected = n_samples / n_bins
    min_bin = min(bins)
    max_bin = max(bins)
    avg_bin = sum(bins) / n_bins
    variance = sum((b - avg_bin)**2 for b in bins) / n_bins
    std_dev = math.sqrt(variance)
    chi2 = sum((b - expected)**2 / expected for b in bins)

    print(f"\n  --- 1000-bin Histogram ---")
    print(f"  Expected/bin: {expected:.0f}")
    print(f"  {'Bin':>6s}  {'Range':>12s}  {'Count':>12s}  {'Ratio':>8s}")
    print(f"  {'-'*44}")
    for b in range(20):
        lo = b / n_bins
        hi = (b + 1) / n_bins
        ratio = bins[b] / expected
        print(f"  {b:6d}  [{lo:.3f},{hi:.3f})  {bins[b]:12,d}  {ratio:8.5f}")

    print(f"  ... ({n_bins - 20} more bins)")
    print(f"\n  All {n_bins} bins summary:")
    print(f"  Min:    {min_bin:,}  ({min_bin/expected:.5f}x)")
    print(f"  Max:    {max_bin:,}  ({max_bin/expected:.5f}x)")
    print(f"  Mean:   {avg_bin:,.1f}")
    print(f"  StdDev: {std_dev:,.1f}  (ratio: {std_dev/expected:.5f})")
    print(f"  Chi2 (999 df): {chi2:.1f}  (expected ~1000 for uniform)")

    print(f"\n  --- Threshold Pass Rates: P(randf() < t) ---")
    print(f"  {'t':>8s}  {'Pass Count':>14s}  {'Empirical P':>14s}  {'Expected':>12s}  {'Ratio':>10s}")
    print(f"  {'-'*64}")
    all_ratios = []
    for t in thresholds:
        c = thresh_counts[t]
        emp = c / n_samples
        ratio = emp / t if t > 0 else 0
        all_ratios.append(ratio)
        print(f"  {t:8.4f}  {c:14,d}  {emp:14.8f}  {t:12.8f}  {ratio:10.6f}")
    print(f"\n  Avg ratio: {sum(all_ratios)/len(all_ratios):.6f}")

    return bins, thresh_counts, chi2


# ============================================================
# Side-by-side: Fixed vs Original Mod
# ============================================================
def compare_fixed_vs_mod(seed_val):
    """Run both fixed and mod versions side-by-side."""
    from rng_harness import PCGRng as PCGRng_Mod  # original buggy version

    print("\n" + "=" * 70)
    print("SIDE-BY-SIDE COMPARISON: Fixed vs Mod (buggy)")
    print("=" * 70)

    for name, cls in [("FIXED", PCGRng_Fixed), ("MOD (buggy)", PCGRng_Mod)]:
        rng = cls(seed_val)
        thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30]
        counts = {t: 0 for t in thresholds}
        n = 1_000_000

        for _ in range(n):
            v = rng.randf()
            for t in thresholds:
                if v < t:
                    counts[t] += 1

        print(f"\n  {name}:")
        print(f"  {'t':>8s}  {'count':>10s}  {'ratio':>8s}")
        for t in thresholds:
            ratio = counts[t] / (n * t)
            print(f"  {t:8.4f}  {counts[t]:10d}  {ratio:8.4f}")


# ============================================================
# MAIN
# ============================================================
def main():
    seed_string = "TESTSEED1"
    landlord_seed = fnv1a(seed_string)

    print("=" * 70)
    print("FIXED PCGRng Validation Suite")
    print("=" * 70)
    print(f"Test seed: '{seed_string}' → FNV-1a → {landlord_seed} (0x{landlord_seed:08X})")

    # Test 1: Direct seeded
    test_fixed_version("Fixed PCGRng (direct seed=42)", PCGRng_Fixed, 42, 1_000_000)

    # Test 2: Via landlord seed derivation (simulating actual mod flow)
    sym_seed = derive_seed(landlord_seed, 'sym_rarity')
    test_fixed_version(
        f"Fixed PCGRng (derived seed 'sym_rarity'={sym_seed})",
        PCGRng_Fixed, sym_seed, 10_000_000
    )

    # Test 3: First-draw ephemeral instances
    print(f"\n{'='*60}")
    print(f"Fixed PCGRng: First-Draw Test (1,050,000 ephemeral instances)")
    print(f"{'='*60}")
    thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30]
    counts = {t: 0 for t in thresholds}
    n_first = 1_050_000

    t0 = time.time()
    n_rounds = 1000
    n_per_round = 1050
    actual = 0
    for r in range(1, n_rounds + 1):
        for c in range(n_per_round):
            child_seed = derive_seed(landlord_seed, f'itmrarity_{r}_{c}')
            rng = PCGRng_Fixed(child_seed)
            v = rng.randf()
            for t in thresholds:
                if v < t:
                    counts[t] += 1
            actual += 1
    elapsed = time.time() - t0

    print(f"  Samples: {actual:,}  Time: {elapsed:.1f}s")
    print(f"  {'t':>8s}  {'count':>10s}  {'ratio':>8s}")
    for t in thresholds:
        ratio = counts[t] / (actual * t)
        print(f"  {t:8.4f}  {counts[t]:10d}  {ratio:8.4f}")

    # Test 4: Side-by-side comparison
    compare_fixed_vs_mod(landlord_seed)

    print("\n" + "=" * 70)
    print("All tests complete.")
    print("=" * 70)


if __name__ == "__main__":
    main()
