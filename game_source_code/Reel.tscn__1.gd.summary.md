# Reel.tscn__1.gd
**Scene:** Reel.tscn (~740 lines)
**Role:** Individual slot machine reel column — manages one vertical reel: spinning animation, icon placement, tile add/remove, click-to-spin, and pre-spin symbol removal effects from items.

## Variables
- `reel_num` — 0-based column index
- `icons[]`, `icon_types[]`, `icon_types_to_be_added[]` — Active icons and pending additions
- `saved_icon_data[]` — Persistent per-icon data (coins earned, bonuses, multipliers)
- `spinning`, `spin_delay`, `max_spin_delay`, `spin_offset`, `spin_speed (56)`, `spin_diff` — Spin animation state; delay increases per reel_num for cascading stop
- `mod = 112` — Slot height in pixels (scaled)
- `hovering`, `held` — Mouse interaction
- `mini_spin`, `instant_spins` — Special spin modes
- `icon_types_tba_bonus_texts[]` — Pending bonus text for newly added icons

## Methods
- **`_ready()`** — Sets scaling, alignment, connects orphan cleanup
- **`update()`** — Drives spin animation: advances `spin_offset`, checks for reel stop, triggers `press()` on completion, snaps icon positions
- **`update_scale()`** — Recalculates spin_speed and mod from UI scaling
- **`_input(event)`** — Click-to-spin per reel with Steam Deck timer support
- **`press()`** — Reel stop or spin trigger
- **`load_base_icons()`** — Creates starting icon layout per floor (reads from Pop-up's floor data), handles sandbox mode
- **`load_icons()`** — Instantiates SlotIcon nodes from icon_types
- **`add_tile(t)`** — Adds new tiles: finds empty position or expands reel, instantiates SlotIcon, adjusts position, adds to icons array
- **`symbol_removal_effects()`** — Pre-spin item removal effects: egg carton, lint roller, etc. remove symbols before spin
- **`save()`** — Serializes reel state

## Control Flow
1. `load_base_icons()` called by parent Reels at game start
2. During spin: `update()` advances each reel, reels stop in sequence (leftmost first via `spin_delay`)
3. When all reels stop → `Reels.spin()` continues with effects
4. `add_tile()` called when effects/items add symbols to the board
