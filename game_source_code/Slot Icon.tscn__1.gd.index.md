# Slot Icon.tscn__1.gd — Slice Index (5760 lines)
**Extends:** Outline Icon

## Variable Declarations (lines 1-176)
| Lines | Section |
|-------|---------|
| 1-47 | Value pipelines: coin, reroll, removal, essence (value, bonus_arr, multiplier_arr, final_value, permanent_bonus) |
| 48-88 | State: prev_data, destroyed, removed, coins_earned, hovering, extra_textures, queued_anims |
| 89-176 | Effect state, modded flags, tooltips, delayed_sfx, hex_effects, forced_add/skip |

## Methods by Line Range
| Lines | Method | Description |
|-------|--------|-------------|
| 177-189 | `_free_if_orphaned()` | Cleanup |
| 191-193 | `_init()` | Signal connect |
| 195-230 | `_input(event)` | Click-to-spin per input type |
| 232-261 | `_ready()` | Setup: hitbox, scaling, sprite |
| 263-272 | `update_scale()` | Recalculate from ui_scaling |
| 274-291 | `press()` | Click handler → select or spin |
| 293-344 | `rotate(degrees)` | Rotation animation |
| 346-654 | `change_type(p_type, ...)` | **Core:** switch symbol type, preserve state, init all value pipelines |
| 656-677 | `add_c_effs(...)` | Post-creation conditional effects |
| 679-694 | `destroy()` | Destruction: SFX, removal, stats |
| 696-731 | `update()` | Per-frame: animations, SFX, position |
| 733-765 | `play_sfx(symbol, sfx_type)` | Sound effect dispatcher |
| 767-793 | `start_animation(anim)` | Animation queue |
| 795-976 | `animate()` | **Animation engine:** ~180 lines of frame-by-frame animation logic |
| 978-982 | `stop_animations()` | Clear animation queue |
| 984-985 | `stop_sfx()` | Stop all SFX |
| 987-991 | `can_add_tooltip()` | Tooltip gate |
| 993-1021 | `hover()` | Create tooltip card |
| 1023-1056 | `tts()` | Screen reader |
| 1058-1066 | `unhover()` | Remove tooltip |
| 1068-1085 | `add_permanent_bonus(b, c, ...)` | Permanent bonus management |
| 1087-1102 | `add_init_permanent_bonuses()` | Apply starting bonuses |
| 1104-1114 | `wc_update(s)` | Wildcard update |
| 1116-1170 | `get_non_flat_value(currency)` | Value pipeline: non-flat |
| 1172-1194 | `get_non_prev_value(currency)` | Value pipeline: non-prev |
| 1196-1206 | `get_relevant_final_value(...)` | Value resolution helper |
| 1208-1272 | `get_value(currency)` | **Value resolver:** walks entire pipeline for a currency |
| 1274-1328 | `get_adjacent_icons()` | Returns up to 8 neighbors |
| 1330-1365 | `get_directional_icons(dir_arr)` | Filter by direction mask (1-8) |
| 1367-1371 | `decide_extra_target(...)` | Extra effect target selection |
| 1373-1503 | `update_value_text()` | Refresh displayed value/bonus/multiplier text |
| 1505-1512 | `add_effect_to_symbol(y, x, effect)` | Direct effect application |
| 1514-1526 | `get_source_effect_hash(effect)` | Effect dedup hashing |
| 1528-1537 | `get_prev_cleaned_effect(...)` | Clean prev-data effects |
| 1539-1555 | `get_fully_cleaned_effect(...)` | Full effect normalization |
| 1557-1636 | `get_cleaned_effect(effect)` | Effect validation/strip |
| 1638-2006 | `parse_var_math(data, giver, eff)` | **Expression engine** (~370 lines): conditions, arithmetic, counted symbols — same engine as Item.tscn |
| 2008-2041 | `check_dove_conditionals(c)` | Dove protection logic |
| 2043-2121 | `update_dynamic_diffs(...)` | Dwarf/monkey synergy multipliers |
| 2123-2152 | `get_author_id(...)` | Mod author resolution |
| 2154-3095 | `do_diff(c, target, c_tbe)` | **Diff effect application** (~940 lines): applies bonuses, multipliers, type changes, wildcards, destruction, clump joins, adjacency effects |
| 3097-3225 | `check_destroyed_symbol(target)` | Check if symbol was destroyed |
| 3227-3264 | `check_symbol_value(target, num)` | Check specific symbol value |
| 3266-3295 | `check_shared_symbol(target)` | Check shared type match |
| 3297-3815 | `do_comp(comparison, c, target, ...)` | **Conditional comparison engine** (~520 lines): evaluates effect conditions |
| 3817-3854 | `check_item_triggers(c, target)` | Item trigger evaluation |
| 3856-4310 | `add_effect(c)` | **Effect dispatcher** (~450 lines): routes effects to correct handler |
| 4312-4315 | `check_last_effects(c_effects)` | Last-effects pass |
| 4317-4634 | `check_conditional_effects(...)` | **Conditional effects evaluator** (~320 lines) |
| 4636-5695 | `add_conditional_effects()` | **Effect setup** (~1060 lines): scans symbol data, builds effect queue |
| 5697-5760 | `add_modded_effect(eff, adj_icons)` | Modded effect injection |
