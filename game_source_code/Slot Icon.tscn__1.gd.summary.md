# Slot Icon.tscn__1.gd
**Scene:** Slot Icon.tscn (extends Outline Icon, ~2100+ lines)
**Role:** Full slot machine symbol — the most complex individual game object. Each symbol has 4 parallel value pipelines (coin, reroll, removal, essence tokens), bonus/multiplier chains, effect evaluation engine, animations, SFX, achievement tracking, destruction/removal logic, adjacency queries, and mod support.

## Value Pipelines (4 parallel sets)
Each currency has: `value` → `value_bonus_arr[]`/`value_multiplier_arr[]` → `final_value` → `non_flat_final_value` → `flat_value_bonus` → `permanent_bonus`/`permanent_multiplier`

## Key Variables
- `type`, `title`, `text`, `rarity`, `groups[]` — Symbol definition
- `wildcarded`, `indestructible`, `destroyed`, `removed`, `dove_destroyed` — State flags
- `prev_data[]` — Previous spin's type/value for transition effects
- `coins_earned`, `times_coins_given`, `times_displayed` — Lifetime stats
- `saved_value`, `saved_values{}` — Persistent counters
- `grid_position` — Vector2(reel_num, row)
- `achievement_values[]` — Per-achievement progress trackers
- `anim_offset`, `base_offset` — Animation offsets
- `bonus_values[]`, `bonus_value_multipliers[]` — Per-value-slot modifiers
- `can_be_removed` — Whether removal token can destroy this
- `texture_type` — Cached type string for texture
- `queued_anims[]` — Pending animation queue

## Major Methods
- **`change_type(p_type, need_cond_effects)`** — Switches symbol type, optionally preserving state, resets stats
- **`get_value(currency)`** — Resolves final value for a currency through the value pipeline
- **`get_non_flat_value(currency)`**, **`get_non_prev_value(currency)`** — Value pipeline accessors
- **`update_value_text()`** — Refreshes displayed value/bonus/multiplier/pointing icons text
- **`get_adjacent_icons()`** — Returns array of up to 8 neighboring symbols
- **`get_directional_icons(dir_arr)`** — Filters adjacent icons by direction mask
- **`add_effect(c)`** — Complex effect application: destruction, bonuses, multipliers, type changes, wildcards, symbol creation, clump joining
- **`add_c_effs(need_cond_effects)`** — Post-creation conditional effects passthrough
- **`parse_var_math(data, giver, eff)`** — Expression evaluator (same engine as Item.tscn): conditions, arithmetic, counted symbols
- **`update_dynamic_diffs(multiplier, p_type, pdo)`** — Dwarf/monkey-like item synergies
- **`check_dove_conditionals(c)`** — Special dove destruction prevention logic
- **`destroy()`** — Full destruction: SFX, stats, visual effects
- **`start_animation(anim)`**, **`animate()`**, **`stop_animations()`** — Animation system
- **`play_sfx(symbol, sfx_type)`**, **`stop_sfx()`** — Sound effect system
- **`press()`** — Click handler: selection or spin trigger
- **`hover()`**, **`unhover()`** — Tooltip create/destroy
- **`add_permanent_bonus(b, c, do_prev)`**, **`add_init_permanent_bonuses()`** — Permanent bonus management
- **`wc_update(s)`** — Wildcard update
- **`get_author_id(...)`** — Mod author ID resolution

## Control Flow
1. Created by `Reel.load_icons()` or `Reel.add_tile()` → `change_type()` initializes
2. Each spin: effects evaluated externally by `Reels.check_effects()` → `add_effect()` called per effect
3. Value resolved via `get_value()` → sent to `EffectText` for display
4. Symbol destroyed by items/effects → `destroy()` cleanup
5. Hover/click bubble events to parent Reel
