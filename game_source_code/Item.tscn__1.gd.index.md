# Item.tscn__1.gd — Slice Index (3189 lines)

## Variable Declarations (lines 1-99)

## Methods by Line Range
| Lines | Method | Description |
|-------|--------|-------------|
| 86-98 | `_free_if_orphaned()` | Cleanup |
| 100-102 | `_init()` | Signal connect |
| 104-122 | `_input(event)` | Click-to-toggle per input type |
| 124-145 | `_ready()` | Setup: sprites, hitboxes, themed colors |
| 147-178 | `update()` | Per-frame: hover, position, button state |
| 180-364 | `toggle_disabled()` | **Enable/disable** (~185 lines): toggle animation, effect cleanup, state sync |
| 366-371 | `set_type(_type)` | Type setter |
| 373-395 | `get_author_id(...)` | Mod author resolution |
| 397-401 | `can_add_tooltip()` | Tooltip gate |
| 403-418 | `hover()` | Create tooltip card |
| 420-451 | `tts()` | Screen reader |
| 453-456 | `unhover()` | Remove tooltip |
| 458-467 | `temp_destroy()` | Consume item (single use) |
| 469-486 | `parse_conditional(v1, v2, cond)` | Evaluate one condition |
| 488-816 | `parse_var_math(data, giver, eff)` | **Expression engine** (~330 lines): conditions, arithmetic, counted symbols, item counts — core effect DSL evaluator |
| 818-1121 | `destroy()` | **Destruction pipeline** (~300 lines): removal effects, essence triggers, symbol removal, SFX, stats, modded effects |
| 1123-1658 | `symbol_check()` | **Symbol checker** (~535 lines): check if triggers present on board, update item value, handle per-type item effects |
| 1660-1684 | `add_to_cond_effects(effect)` | Push effect to shared pool |
| 1686-1689 | `add_effect_to_symbol(y, x, effect)` | Direct effect application |
| 1691-1728 | `get_cleaned_effect(effect)` | Effect normalization |
| 1730-2067 | `add_effect(c)` | **Effect dispatcher** (~337 lines): destruction, bonuses, multipliers, symbol removal, token generation, type changes |
| 2069-2126 | `update_value_text()` | Refresh displayed value text |
| 2128-2630 | `check_conditional_effects()` | **Conditional evaluator** (~500 lines): walk effect list, apply value changes, handle item-specific logic |
| 2632-3176 | `add_conditional_effects()` | **Effect setup** (~545 lines): scan item data, build effect queue from item definitions |
| 3178-3189 | `add_modded_effect(eff)` | Modded effect injection |
