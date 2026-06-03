# Coin Sum.tscn__10.gd
**Scene:** Coin Sum.tscn (extends Outline Label)
**Role:** Animated coin sum display — shows the accumulating coin value from the current spin, animating toward the coin counter, then flushes to `Coins.queued_increase`.

## Variables
- `value` — Accumulated coin amount being displayed
- `adding` — Whether currently in "adding" animation
- `delay = 25` — Animation delay counter
- `start_pos` — Target Y position (at coin counter level)

## Methods
- **`_ready()`** — Sets CJK/font display mode, icon z-index
- **`set_start_pos()`** — Calculates Y position near the coin counter
- **`add_value(num)`** — Adds to value, formats display string with coin icon, starts at `start_pos`
- **`update()`** — Per-frame animation: handles counting speed scaling, animates text upward, triggers music cycle on rent milestone, flushes value to `Coins.queued_increase` when animation completes
- **`save()`** — Serializes position + value state

## Control Flow
Each spin's coin values flow here → `add_value()` → visible text animates upward → value transfers to `Coins.queued_increase` → coin counter increments → text hides.
