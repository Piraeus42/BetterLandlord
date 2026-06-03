# Item.tscn__1.gd
**Scene:** Item.tscn (~3190 lines)
**Role:** Core item implementation — the most complex single object in the game. Each item has value tracking, conditional effect evaluation, an expression engine (`parse_var_math`), enable/disable logic, destruction/consumption, symbol checking, and modded effect support.

## Key Variables
- `type`, `title`, `rarity`, `groups[]`, `values[]`, `value` — Item definition and value
- `item_count` — Stack count
- `disabled`, `destroyed`, `destroyable`, `modded`, `inherit_effects` — State flags
- `c_effects[]` — Conditional effects applied this spin
- `item_adding_effects[]` — Effects triggered on item addition
- `bonus_values[]`, `bonus_value_multipliers[]` — Per-value-slot modifiers
- `reroll_value`, `removal_value`, `essence_value` — Token value pipelines
- `saved_value` — Persistent counter (e.g., piggy bank, swear jar)
- `destroy_counters` — Usage/destruction countdown
- `symbol_triggers[]` — Symbol types that trigger this item
- `symbols_removed_pre_spin[]` — Symbols to destroy before spin
- `delayed_removal_symbols[]` — Symbols queued for post-spin removal

## Methods
### Core
- **`_ready()`** — Sets up sprite textures, hitboxes, themed colors
- **`update()`** — Per-frame: hover detection, position updates, button state

### Item Lifecycle
- **`set_type(_type)`** — Initializes item from database: sets rarity, values, groups, description, SFX, modded state, destroyability
- **`toggle_disabled()`** — Toggle enable/disable with animation
- **`temp_destroy()`** — Consume/use the item (single use, decrements count)
- **`destroy()`** — Full destruction pipeline: handles removal effects, essence triggers, symbol removal, sound, stats, modded effects

### Effect System
- **`add_conditional_effects()`** — Scans item's effect definitions, parses conditions, adds effects to symbols
- **`check_conditional_effects()`** — Evaluates conditional effects, applies value changes
- **`add_to_cond_effects(effect)`** — Adds effect to shared cond_effects_to_add pool
- **`add_effect_to_symbol(y, x, effect)`** — Directly applies an effect to a specific grid cell
- **`get_cleaned_effect(effect)`** — Strips/validates effect data before application
- **`add_effect(c)`** — Complex effect dispatcher: handles destruction effects, value bonuses/multipliers, symbol removal, token generation, type changes, wildcards, adjacency, etc.
- **`add_modded_effect(eff)`** — Applies user-mod-defined effects

### Expression Engine
- **`parse_var_math(data, giver, eff)`** — Evaluates effect expressions: supports conditional operators (`>=`, `<=`, `!=`, `>`, `<`, `==`), arithmetic (`+`, `-`, `*`, `/`), value references (`<value_N>`), counted symbol counts, item counts, and nested conditions
- **`parse_conditional(v1, v2, cond)`** — Evaluates a single conditional expression
- **`symbol_check()`** — Checks if item's symbol triggers are present on board, updates item value accordingly

### Helper
- **`get_author_id(c, p_id, comp, target, v_num)`** — Resolves mod author IDs for Steam Workshop items
- **`can_add_tooltip()`** — Whether tooltip card should appear on hover
- **`hover()`**, **`unhover()`** — Tooltip create/destroy
- **`update_value_text()`** — Refreshes displayed value text on item sprite

## Control Flow
1. Created via `Items.add_item()` → `set_type()` initializes from database
2. Each spin: `add_conditional_effects()` → `check_conditional_effects()` → value changes flow to Reels
3. Items destroyed by threshold/player action → `destroy()` pipeline
4. `symbol_check()` called post-effects to update dynamic values

## Key Systems
- **var_math expressions**: Items use a mini DSL for effects, e.g., `<value_0> + counted_coin * <value_1>`
- **Conditional effects**: `{condition: "counted_coin >= 3", effect: {...}}` pattern
- **Essence system**: Special items that have limited uses (destroy_counters) before being consumed
- **Mod inheritance**: Modded items can inherit base item effects via `inherit_effects`
