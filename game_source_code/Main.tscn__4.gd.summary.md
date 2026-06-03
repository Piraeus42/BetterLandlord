# Main.tscn__4.gd
**Scene:** Main.tscn (~2134 lines)
**Role:** Reels/slot-machine engine — the core gameplay system: manages the 5×4 grid of symbols, spin mechanics, symbol effect evaluation, value calculation, clump combining, tile generation, and post-spin animations.

## Constants
- `reel_height = 4`, `reel_width = 5` — Grid dimensions (5 columns × 4 rows)
- `line_colors = ["005499", "CD0074", "FF3333", "00CCCC", "990056", "BF2626"]` — Slot line highlight colors

## Key Variables
- `reels[]` (5) — Reel column nodes
- `reel_borders[]` (5) — Border/UI nodes for each reel
- `displayed_icons[][]` — 2D array [y][x] of currently visible SlotIcon nodes
- `selected_icons[]`, `selected_reels[]`, `added_icons[]` — Spin result tracking
- `conditional_effects[][][]` — 2D array of active effect objects per grid cell
- `symbol_queue[]`, `symbol_arr[]` — Pending symbols to add, all symbols in play
- `clumps[]`, `group_clumps[]` — Symbol grouping for adjacency-based effects
- `texts[]` — EffectText nodes for displaying coin values over icons/items
- `spinning`, `effects_playing`, `counting_symbols`, `checking_effects`, `counting_effects` — State booleans
- `sfx_queue[]`, `sfx_queue_hashes[]` — Queued sound effects with delay
- `items_being_added_during_spin`, `destroyed_item_this_spin` — Cross-system flags
- `symbol_destroyed_during_spin`, `symbol_removed_during_spin`, `symbol_transformed_during_spin` — Trigger flags
- `ninja_timer`, `stealing_magpie`, `grown_strawberries`, `grown_apples` — Specific symbol/item state
- `queued_milk`, `queued_banana_peels`, `queued_honey`, `queued_seeds` — Food item queues
- `big_wildcards[]`, `bad_arrows[]` — Special symbol tracking

## Major Methods

### Setup
- **`_ready()`** — Initializes reel references, creates EffectText nodes, loads refs to items/popup
- **`draw_reels()`** — Positions and sizes all 5 reel columns and their borders based on UI scaling; sizes landlord HP bar
- **`load_icons()`** — Delegates to each reel to reload icon references

### Spin Cycle
- **`spin()`** — Entry point: validates can spin (no effects playing, has coins, no pending emails), resets all effect texts, starts all 5 reels spinning, handles dud timer insertion, logs spin state, resets rarity bonuses
- **`add_tba_symbols()`** — Adds any queued symbols to reels before spin; resets icon positions + visibility
- **`shuffle_tiles()`** — Randomizes symbol positions across all reels (unless sandbox consistent mode or modded floor consistent_spins); handles edge case of empties + non-empties being offscreen
- **`update_icon_types()`** — Syncs each reel's `icon_types[]` and `saved_icon_data[]` arrays from current icon state
- **`swap_icon_positions(i1, i2)`** — Swaps two icons' grid positions while preserving persistent data (coins earned, bonuses, multipliers, etc.)

### Effects Engine
- **`add_effects()`** — First pass after spin completes: makes clumps, adds conditional effects from all symbols and items, handles rarity-mod symbols, runs first effects cycle
- **`check_effects()`** — Main effects resolution loop: iterates until no more changes. On each pass: checks item effects, processes `symbol_positions_to_update` (checking conditional effects per cell), handles symbol destruction/removal/transformation, midas bombs, counts symbols, checks diff multipliers (anvil/dwarf, monkey), runs last-effects pass. Breaks when stable.
- **`check_values()`** — Post-effects: calculates final coin/reroll/removal/essence values for each symbol and item; handles wildcards; formats display strings with currency icons; processes special items (black_cat, swear_jar, white_pepper, devil's_deal, mod_multiple_effects); starts value counting animations
- **`count_symbols(c_b)`** — Counts symbols by type for conditional triggers (achievements, item effects). Returns whether counting is stable.

### Clump System (Adjacency Groups)
- **`make_clumps()`** — Scans grid for adjacent matching symbols, builds clump data structures
- **`add_to_clump(y, x, telescope, protractor)`** — Flood-fill adjacency check adding cells to current clump
- **`combine_clumps()`** — Merges overlapping clumps
- **`execute_clumps()`** — Applies clump-based effects
- **`finalize_clumps()`** — Post-combination cleanup
- **`check_icon_match(icon1, icon2)`** — Returns true if icons match by type or group (for group clumps)
- **`protractor_adjacent(y, x)`** — Checks if cell is adjacent to a protractor symbol

### Symbol Management
- **`generate_icon(type, known_data)`** — Factory: creates SlotIcon instance, applies tile database data, sets rarity/value/groups/sfx, handles extra textures (dice, arrows, modded art), applies known_data if restoring from save
- **`add_tile(t)`** — Adds symbols to reels (from effects, items, etc.): finds reels with empty slots, handles overflow, triggers on-symbol-add effects (brown_pepper, pizza essence, lunchbox, adoption_papers, symbol bombs), updates saved state
- **`can_add_highlander()`** — Returns true if no "highlander" symbol exists on board
- **`get_non_singular_symbols()`** — Counts symbol types that appear ≥2 times on board

### Helpers
- **`add_symbol_position_to_update(grid_pos)`**, **`add_symbol_position_tbd(grid_pos)`** — Queue management for effect re-evaluation
- **`add_queued_achievement(num)`** — Batches achievement unlocks
- **`write_pre_effects_log()`**, **`write_post_effects_log()`** — Debug logging of board state

## Control Flow
1. `_ready()` sets up grid + effect texts
2. User presses SPIN → `spin()` → reels animate → `add_effects()` → `check_effects()` loops until stable → `check_values()` calculates final values
3. Values flow into `Sums/Coin Sum`, `Sums/HP Sum`, `Sums/Extra Sum`
4. Each frame: `update()` processes SFX queue and triggers `check_effects()` if `checking_effects` is set
