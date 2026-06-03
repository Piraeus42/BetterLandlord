# Main.tscn__4.gd — Slice Index (2133 lines)

## Variable Declarations (lines 1-70)
| Lines | Section |
|-------|---------|
| 1-12 | Grid: reel_height=4, reel_width=5, reels[], reel_borders[], clumps[] |
| 13-25 | Spin state: spinning, effects_playing, checking_effects, counting_symbols, counting_effects |
| 26-44 | Symbol tracking: displayed_icons[][], conditional_effects[][][], symbol_queue[], symbol_arr[] |
| 45-70 | Item/symbol flags: symbol_destroyed_during_spin, dove_prevention, ninja_timer, queued_milk, etc. |

## Methods by Line Range
| Lines | Method | Description |
|-------|--------|-------------|
| 72-97 | `_ready()` | Init reels, borders, effect texts, item/popup refs |
| 99-134 | `draw_reels()` | Position/size all 5 reel columns + borders + landlord bar |
| 136-176 | `update()` | Per-frame: SFX queue processing with speed scaling |
| 178-180 | `load_icons()` | Delegate to each reel |
| 182-187 | `do_counted_symbols()` | Init counted symbols from group_database |
| 189-315 | `spin()` | **Spin entry** (~125 lines): validate can spin, reset texts, start reels, dud timer, log state, init rarity bonuses |
| 317-350 | `add_tba_symbols()` | Add queued symbols to reels before spin |
| 352-357 | `can_add_highlander()` | Highlander singleton check |
| 359-386 | `check_icon_match(icon1, icon2)` | Type/group match for clumps |
| 388-446 | `shuffle_tiles()` | Randomize symbol positions, handle empties |
| 448-456 | `update_icon_types()` | Sync icon_types/saved_icon_data arrays |
| 458-485 | `swap_icon_positions(i1, i2)` | Swap while preserving persistent data |
| 487-510 | `write_pre_effects_log()` | Debug: board state before effects |
| 512-600 | `write_post_effects_log()` | Debug: board state after effects |
| 602-690 | `generate_icon(type, known_data)` | **Icon factory** (~90 lines): create SlotIcon from database, apply rarity/value/groups/sfx, extra textures (dice, arrows, modded) |
| 692-704 | `get_non_singular_symbols()` | Count types appearing ≥2 times |
| 706-854 | `add_tile(t)` | **Add symbols** (~150 lines): find empty slots, instantiate icons, trigger on-add effects (brown_pepper, lunchbox, adoption_papers, symbol bombs) |
| 856-862 | `add_symbol_position_to_update/tbd` | Update queue management |
| 864-939 | `count_symbols(c_b)` | Count symbols for triggers, achievements |
| 941-969 | `add_effects()` | **First effects pass:** make clumps, add conditional effects, rarity-mod, run first cycle |
| 971-1167 | `check_effects()` | **Main effects loop** (~200 lines): iterate until stable — items, symbol positions, destruction, midas bombs, transform, diff multipliers, last-effects |
| 1169-1648 | `check_values()` | **Value calculation** (~480 lines): final coin/reroll/removal/essence for each symbol and item, wildcards, currency display formatting, special items (black_cat, swear_jar, white_pepper, mod_multiple) |
| 1650-1701 | `make_clumps()` | Scan grid for adjacent matching symbols |
| 1703-1704 | `protractor_adjacent(y, x)` | Check protractor adjacency |
| 1706-1708 | `add_queued_achievement(num)` | Batch achievement unlock |
| 1710-1722 | `add_to_clump(y, x, ...)` | Flood-fill adjacency for clumping |
| 1724-1778 | `combine_clumps()` | Merge overlapping clumps |
| 1780-1807 | `execute_clumps()` | Apply clump-based effects |
| 1809-2133 | `finalize_clumps()` | **Post-combination cleanup** (~325 lines): finalize clump state, trigger effects |
