# Coins.tscn__1.gd
**Scene:** Coins.tscn (extends Outline Label)
**Role:** Coin counter display — shows the player's current coin balance at the bottom of the screen, with animated counting from `queued_increase`.

## Variables
- `coins = 1` — Current coin balance
- `queued_increase` — Pending coins to animate in (can be positive or negative)

## Methods
- **`_ready()`** — Sets CJK/font display, saves settings if needed, calls `align_text()`
- **`align_text()`** — Positions text at bottom-left of screen based on font/CJK/scaling
- **`update()`** — Per-frame: drains `queued_increase` into `coins` at speed-determined rate, checks for guillotine essence trigger (coins >= threshold → execution animation), formats coin display string
- **`save()`** — Serializes coin + queued_increase state

## Control Flow
Coins flow: spin values → Coin Sum → `queued_increase` → `coins`. The display updates every frame with smooth counting animation.
