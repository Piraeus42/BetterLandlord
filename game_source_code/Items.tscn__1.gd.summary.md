# Items.tscn__1.gd
**Scene:** Items.tscn (~392 lines)
**Role:** Item container/inventory manager — holds all item instances, handles adding/removing items, pagination layout, save/load, conditional effect coordination, and item grid positioning.

## Key Variables
- `items[]` — All active Item instances
- `item_types[]` — Type strings (parallel array to items; may include `_d` suffix for disabled)
- `destroyed_items[]`, `destroyed_item_types[]` — Destroyed item tracking
- `items_destroyed_this_spin[]` — Per-spin destruction list
- `page` — Current inventory page (for multi-page item display)
- `visible_items` — How many items fit on screen
- `total_peppers` — Running count of pepper-type items
- `saved_item_data[]`, `saved_destroy_counters[]`, `item_count_data[]` — Parallel save arrays

## Methods
- **`add_item(p_type)`** — Core method: handles modded type resolution, stacking (increments item_count if duplicate), instance creation from Item.tscn, sets rarity/values/groups/disabled, applies destroy counter rules (popsicle/essence interaction), checks guillotine trigger, sets position in grid (4 items per row), creates associated EffectText, triggers on-item-add effects
- **`has_unmodded_item(p_type)`** — Checks if item exists in inventory (strips mod IDs, handles mod inheritance)
- **`has_just_destroyed_unmodded_item(p_type)`** — Checks if item was destroyed this spin
- **`add_cond_effects()`** — Flushes pending cond_effects_to_add to all symbol positions in `symbol_positions_to_update`
- **`load_items()`** — Restores items from saved state (item_types + saved data arrays)
- **`update_positions()`** — Grid layout engine: calculates grid cells avoiding reel area, handles page-based visibility
- **`update_page_buttons()`** — Shows/hides left/right scroll buttons based on page state
- **`scroll_items_left/right()`** — Page navigation (guarded against spinning/effects)
- **`save()`** — Serializes all item state arrays

## Control Flow
1. Items added via `add_item()` from popups, effects, or save loading
2. Grid layout updated via `update_positions()` — items placed left-to-right, top-to-bottom, avoiding reel rect
3. Conditional effects flushed via `add_cond_effects()` each spin evaluation cycle
4. State persisted in `save()` alongside game save
