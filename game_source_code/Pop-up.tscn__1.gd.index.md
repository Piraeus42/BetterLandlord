# Pop-up.tscn__1.gd — Slice Index (3860 lines)

## Variable Declarations (lines 1-152)
| Lines | Section |
|-------|---------|
| 1-28 | Core state: emails, buttons, cards, border, container, label_text, scroll_bar |
| 29-52 | Game state: current_floor, max_floor, spins, doing_boss_fight, endless_mode |
| 53-100 | Rent/token state: times_rent_paid, reroll_tokens, removal_tokens, essence_tokens |
| 101-152 | Mod state: mods, saved_mod_ids, rarity_bonuses, forced_rarities, hex triggers |

## Methods by Line Range
| Lines | Method | Description |
|-------|--------|-------------|
| 153-155 | `_free_if_orphaned()` | Cleanup |
| 157-165 | `_init()` | Signal connect, init arrays |
| 167-196 | `_input(event)` | Keyboard shortcuts for pop-up buttons |
| 198-239 | `_ready()` | Setup: node references, scaling, alignment |
| 241-255 | `load_emails()` | **Data load:** reads email JSON, populates email database |
| 257-611 | `update()` | **Per-frame** (~355 lines): slide animation, content positioning, scroll offset, button/card layout, keyboard nav, tooltip management |
| 613-725 | `add_event(key, extra_values)` | **Event queue** (~110 lines): push email with localization, mod ID resolution, extra values |
| 727-746 | `update_cjk_text_size()` | CJK text sizing |
| 748-1107 | `display()` | **Pop-up renderer** (~360 lines): sizes borders, formats sender/rent/container, creates buttons, manages tooltips |
| 1109-1221 | `add_buttons()` | **Button factory** (~110 lines): creates response buttons (pay rent, reroll, skip) |
| 1223-1465 | `add_cards(f_rarities)` | **Card choice engine** (~240 lines): rarity pool selection, forced_rarity handling, card instantiation |
| 1467-1480 | `update_card_positions()` | Card grid layout |
| 1482-1537 | `draw()` | Legacy draw method |
| 1539-1567 | `add_options_button()` | Options button factory |
| 1569-1609 | `remove(last_email)` | Remove current email, advance queue |
| 1611-1615 | `update_saved_symbol_order(arr)` | Save symbol order for consistency |
| 1617-1656 | `add_deck_button(s)` | Deck button factory |
| 1658-1668 | `draw_prompt_deck()` | Prompt deck view |
| 1670-1695 | `draw_removal_prompt(first_prompt)` | Removal prompt deck |
| 1697-1746 | `check_spend_triggers(effect_type)` | Item triggers for token spending |
| 1748-1769 | `set_tip_values()` | Tooltip value setup |
| 1771-1782 | `invert_ar_rows(arr, n1, n2)` | Arabic RTL row inversion |
| 1784-2562 | `draw_deck()` | **Deck drawing** (~780 lines): symbol/item selection UI, rarity pools, mod integration, deck pagination, Steam Workshop support |
| 2564-2578 | `reset_deck()` | Clear deck state |
| 2580-2706 | `undraw_deck()` | **Deck teardown** (~125 lines): remove cards, process selection, trigger effects |
| 2708-2764 | `tts()` | Screen reader output |
| 2766-2829 | `update_rent_values()` | Rent cost calculation and display |
| 2831-2840 | `can_try_to_pay_rent()` | Rent payment gate |
| 2842-2880 | `spin_modifying_effects()` | Pre-spin item effect application |
| 2882-3095 | `post_rent_symbol_choice()` | Post-rent symbol selection flow |
| 3096-3859 | `resolve_event(...)` | **Event resolver** (~760 lines): handles ALL button/card outcomes — rent payment, reroll, removal, essence, item purchase, symbol choice, Steam Workshop, achievements |
