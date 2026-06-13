#!/usr/bin/env python3
"""
Cross-validate the GDScript PCGRng port against:
1. The standard PCG32 reference implementation
2. A "corrected" version with MASK_64 instead of MASK_63
3. Python's built-in random for sanity checks

This verifies whether the observed non-uniformity is:
(a) A real bug in the mod's GDScript code, or
(b) An error in our Python port
"""

import random as py_random
import time
import math

# ============================================================
# Constants
# ============================================================
PCG_DEFAULT_INC = 1442695040888963407
PCG_MULT        = 6364136223846793005
MASK_63         = 0x7FFFFFFFFFFFFFFF   # [0, 2^63)  — mod's choice
MASK_64         = 0xFFFFFFFFFFFFFFFF   # [0, 2^64)  — standard PCG
MASK_31         = 0x7FFFFFFF
DENOMINATOR     = 2147483648.0         # 2^31


# ============================================================
# Version A: "Faithful" port — MASK_63, exactly matching GDScript
# ============================================================
class PCGRng_Mod:
    """Exact GDScript port: MASK_63, 64-bit signed wrapping."""
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
        self.state = ((old * PCG_MULT) + self.inc) & MASK_63
        return old

    def randf(self) -> float:
        old = self._step()
        x = (old >> 18) ^ old
        x = x >> 27
        rot = old >> 59
        left_part = (x << ((-rot) & 31)) & MASK_64
        if left_part >= 0x8000000000000000:
            left_part = left_part - 0x10000000000000000
        result = ((x >> rot) | left_part) & MASK_31
        return float(result) / DENOMINATOR


# ============================================================
# Version B: "Corrected" — MASK_64, full 64-bit state like standard PCG32
# ============================================================
class PCGRng_Fixed:
    """Corrected version: MASK_64 replaces MASK_63. State spans full 64 bits."""
    __slots__ = ('state', 'inc')
    def __init__(self, seed_val: int):
        self.state = seed_val & MASK_64
        self.inc = ((PCG_DEFAULT_INC << 1) | 1) & MASK_64
        self._step()
        self.state = (self.state + PCG_MULT) & MASK_64
        self._step()
        self._step()

    def _step(self) -> int:
        old = self.state
        self.state = ((old * PCG_MULT) + self.inc) & MASK_64
        return old

    def randf(self) -> float:
        old = self._step()
        # Standard PCG32: truncate to 32 bits for xorshifted
        xorshifted = ((old >> 18) ^ old) & 0xFFFFFFFF  # uint32_t cast
        xorshifted = xorshifted >> 27  # now 5 bits
        rot = old >> 59  # with MASK_64, rot in [0, 31]
        result = ((xorshifted >> rot) | (xorshifted << ((-rot) & 31))) & MASK_31
        return float(result) / DENOMINATOR


# ============================================================
# Version C: Godot-style — MASK_63 but NO uint32_t truncation (what mod does)
# Version D: GDScript with big-int semantics (no 64-bit wrapping)
# ============================================================
class PCGRng_Mod_BigInt:
    """GDScript port assuming Python big-int semantics (no 64-bit wrapping)."""
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
        self.state = ((old * PCG_MULT) + self.inc) & MASK_63
        return old

    def randf(self) -> float:
        old = self._step()
        x = (old >> 18) ^ old  # full 64-bit (or wider) int
        x = x >> 27
        rot = old >> 59
        # No 64-bit wrapping — left shift produces big integer
        # MASK_31 at the end clears all high bits
        result = ((x >> rot) | (x << ((-rot) & 31))) & MASK_31
        return float(result) / DENOMINATOR


# ============================================================
# Version E: MASK_63 + uint32_t truncation (hybrid)
# ============================================================
class PCGRng_Hybrid:
    """MASK_63 state + uint32_t truncation on x."""
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
        self.state = ((old * PCG_MULT) + self.inc) & MASK_63
        return old

    def randf(self) -> float:
        old = self._step()
        # uint32_t truncation like standard PCG32
        xorshifted = ((old >> 18) ^ old) & 0xFFFFFFFF
        xorshifted = xorshifted >> 27
        rot = old >> 59  # still only 0..15 with MASK_63
        result = ((xorshifted >> rot) | (xorshifted << ((-rot) & 31))) & MASK_31
        return float(result) / DENOMINATOR


# ============================================================
# Test each version
# ============================================================
def test_version(name, rng_class, n_samples=1_000_000):
    print(f"\n{'='*60}")
    print(f"Testing: {name}")
    print(f"{'='*60}")
    print(f"  {n_samples:,} samples")

    rng = rng_class(42)
    n_bins = 100
    bins = [0] * n_bins
    thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30, 0.50]
    thresh_counts = {t: 0 for t in thresholds}

    t0 = time.time()
    for _ in range(n_samples):
        val = rng.randf()
        bi = min(int(val * n_bins), n_bins - 1)
        bins[bi] += 1
        for t in thresholds:
            if val < t:
                thresh_counts[t] += 1
    elapsed = time.time() - t0

    expected = n_samples / n_bins
    min_bin = min(bins)
    max_bin = max(bins)

    # Compute chi-squared
    chi2 = sum((b - expected)**2 / expected for b in bins)

    print(f"  Time: {elapsed:.1f}s")
    print(f"  Expected/bin: {expected:.0f}")
    print(f"  Min bin: {min_bin} ({min_bin/expected:.3f}x)")
    print(f"  Max bin: {max_bin} ({max_bin/expected:.3f}x)")
    print(f"  Chi2 (99 bins): {chi2:.1f}  (expected ~99 for uniform)")

    # Show first 10 bins
    print(f"\n  First 10 bins (0.00-0.10):")
    for b in range(10):
        print(f"    bin[{b:2d}] [{b/100:.2f}-{(b+1)/100:.2f}): {bins[b]:8d}  ({bins[b]/expected:.4f}x)")

    # Threshold pass rates
    print(f"\n  Threshold pass rates:")
    print(f"  {'t':>8s}  {'count':>10s}  {'empirical':>12s}  {'expected':>10s}  {'ratio':>8s}")
    for t in thresholds:
        c = thresh_counts[t]
        emp = c / n_samples
        ratio = emp / t if t > 0 else 0
        print(f"  {t:8.4f}  {c:10d}  {emp:12.8f}  {t:10.6f}  {ratio:8.4f}")

    # Summary statistic: average ratio across low thresholds
    low_ratios = [thresh_counts[t] / (n_samples * t) for t in thresholds[:5]]
    print(f"\n  Avg ratio for t <= 0.05: {sum(low_ratios)/len(low_ratios):.4f}")

    return bins, thresh_counts


def main():
    py_random.seed(12345)
    print("Cross-Validation of PCGRng Implementations")
    print("=" * 60)
    print()
    print("Version A: Mod (MASK_63, no uint32_t trunc, 64-bit wrapping)")
    print("Version B: Fixed (MASK_64, uint32_t truncation) = standard PCG32")
    print("Version C: BigInt (MASK_63, no uint32_t trunc, Python big ints)")
    print("Version D: Hybrid (MASK_63, WITH uint32_t truncation)")
    print("Version E: Python random() — Mersenne Twister (ideal reference)")
    print()

    n = 1_000_000

    # Version A: Faithful mod port
    test_version("VERSION A: Mod port (MASK_63, no uint32_t trunc, 64-bit wrap)", PCGRng_Mod, n)

    # Version B: Corrected
    test_version("VERSION B: Fixed (MASK_64, uint32_t trunc) = standard PCG32", PCGRng_Fixed, n)

    # Version C: Big int
    test_version("VERSION C: BigInt (MASK_63, no trunc, big-int shift)", PCGRng_Mod_BigInt, n)

    # Version D: Hybrid
    test_version("VERSION D: Hybrid (MASK_63, WITH uint32_t trunc)", PCGRng_Hybrid, n)

    # Version E: Python random
    print(f"\n{'='*60}")
    print(f"Testing: VERSION E: Python Mersenne Twister (reference)")
    print(f"{'='*60}")
    bins = [0] * 100
    thresholds = [0.005, 0.0125, 0.015, 0.0375, 0.05, 0.10, 0.20, 0.25, 0.30, 0.50]
    thresh_counts = {t: 0 for t in thresholds}
    t0 = time.time()
    for _ in range(n):
        val = py_random.random()
        bi = min(int(val * 100), 99)
        bins[bi] += 1
        for t in thresholds:
            if val < t:
                thresh_counts[t] += 1
    elapsed = time.time() - t0
    expected = n / 100
    chi2 = sum((b - expected)**2 / expected for b in bins)
    print(f"  Expected/bin: {expected:.0f}")
    print(f"  Min bin: {min(bins)} ({min(bins)/expected:.3f}x)")
    print(f"  Max bin: {max(bins)} ({max(bins)/expected:.3f}x)")
    print(f"  Chi2 (99 bins): {chi2:.1f} (expected ~99 for uniform)")
    print(f"\n  Threshold pass rates:")
    for t in thresholds:
        c = thresh_counts[t]
        emp = c / n
        ratio = emp / t if t > 0 else 0
        print(f"  t={t:8.4f}:  emp={emp:10.8f}  ratio={ratio:8.4f}")

    # === ADDITIONAL: Show the rot distribution for MASK_63 vs MASK_64 ===
    print(f"\n{'='*60}")
    print(f"Rotation Amount Distribution Check")
    print(f"{'='*60}")

    for name, rng_class in [("MASK_63", PCGRng_Mod), ("MASK_64", PCGRng_Fixed)]:
        rng = rng_class(42)
        rot_counts = [0] * 32
        for _ in range(1_000_000):
            old = rng._step()
            rot = old >> 59
            rot_counts[rot] += 1
        print(f"\n{name} rot distribution (first 10 values, 1M samples):")
        for r in range(min(32, len(rot_counts))):
            if rot_counts[r] > 0 or r < 16:
                pct = rot_counts[r] / 1_000_000 * 100
                print(f"  rot={r:2d}: {rot_counts[r]:8d} ({pct:6.3f}%)")

    # === CRITICAL: Check x-width distribution ===
    print(f"\n{'='*60}")
    print(f"Xorshifted Bit Width Check")
    print(f"{'='*60}")
    rng_mod = PCGRng_Mod(42)
    rng_ref = PCGRng_Fixed(42)
    mod_x_bits = [0] * 64
    fix_x_bits = [0] * 64
    for _ in range(1_000_000):
        old = rng_mod._step()
        x_mod = ((old >> 18) ^ old) >> 27
        bitlen = x_mod.bit_length()
        mod_x_bits[min(bitlen, 63)] += 1

        old2 = rng_ref._step()
        x_fix = ((((old2 >> 18) ^ old2) & 0xFFFFFFFF) >> 27)
        bitlen2 = x_fix.bit_length()
        fix_x_bits[min(bitlen2, 63)] += 1

    print("Mod (MASK_63) xorshifted bit length distribution:")
    for b in range(37):
        if mod_x_bits[b] > 0:
            print(f"  {b:2d} bits: {mod_x_bits[b]:8d}")

    print("Fix (MASK_64) xorshifted bit length distribution (should be 0-5 bits):")
    for b in range(6):
        print(f"  {b:2d} bits: {fix_x_bits[b]:8d}")


if __name__ == "__main__":
    main()
