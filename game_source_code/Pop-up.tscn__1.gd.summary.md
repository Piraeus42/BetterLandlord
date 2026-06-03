# Pop-up.tscn__1.gd
**Scene:** Pop-up.tscn (~2900+ lines)
**Role:** The central pop-up/modal/email system — manages the entire game flow UI: event emails, card choice prompts, button responses, rent payment, symbol/item selection, deck drawing, and game state transitions. This is the primary player interaction interface.

## Key Variables
- `emails[]` — Event queue (from email_data JSON)
- `buttons[]`, `cards[]`, `item_info_texts[]`, `symbol_info_texts[]` — Active UI elements
- `border`, `container`, `label_text`, `scroll_bar` — Child node references
- `offset_y = 1024` — Vertical slide-in position (animates to `offset_top`)
- `delay_timer`, `prompt_delay` — Animation timers
- `current_floor`, `max_floor = 20` — Floor tracking
- `current_modded_floor`, `modded_floor_string` — Modded floor state
- `spins` — Spin counter for current floor
- `times_rent_paid`, `times_to_pay_rent = 12` — Rent payment tracking
- `reroll_tokens`, `removal_tokens`, `essence_tokens` — Token inventories
- `endless_mode`, `doing_boss_fight` — State flags
- `mods`, `saved_mod_ids` — Mod state dictionaries
- `rarity_bonuses` — Per-rarity bonus multipliers
- `symbols_to_choose_from = 3` — Card choice count
- `landlord_fates_data[]` — Landlord fate numbers
- `hex_of_emptiness_trigger`, `hex_of_hoarding_trigger` — Special state flags

## Major Methods
- **`add_event(key, extra_values)`** — Pushes a new email to queue with localization and mod ID handling
- **`update()`** — Per-frame: slides pop-up from `offset_y` toward `offset_top`, locks in position, positions content
- **`display()`** — Prepares pop-up: sizes borders, formats sender/rent containers, creates buttons/cards
- **`add_buttons()`** — Creates response buttons (pay rent, reroll, skip, Steam)
- **`add_cards(f_rarities)`** — Generates card choices from rarity pools with mod support
- **`update_card_positions()`** — Layout engine for card grid
- **`resolve_event(...)`** — Handles button/card selection outcomes
- **`draw_deck()`** — Symbol/item selection screen (drawing from thematic decks)
- **`reset_deck()`**, **`undraw_deck()`** — Clear selection UI
- **`draw_prompt_deck()`**, **`draw_removal_prompt(first_prompt)`** — Specialized deck views
- **`remove(last_email)`** — Removes current email, advances queue
- **`check_spend_triggers(effect_type)`** — Checks item triggers for reroll/removal/essence spending
- **`load_emails()`** — Reads email JSON file, populates email database
- **`can_try_to_pay_rent()`** — Validates rent payment prerequisites
- **`spin_modifying_effects()`** — Applies pre-spin item effects
- **`post_rent_symbol_choice()`** — Post-rent symbol selection flow
- **`update_rent_values()`** — Updates rent cost display
- **`update_saved_symbol_order(arr)`** — Saves symbol order for consistency
- **`tts()`** — Screen reader output for current pop-up content
- **`add_options_button()`**, **`add_deck_button(s)`** — Button factory helpers

## Control Flow
1. `_ready()` sets up references, `load_emails()` loads database
2. Events pushed via `add_event()` → `display()` → `update()` animates slide-in
3. Player interacts with buttons/cards → `resolve_event()` → state changes → `remove()` → next event
4. Rent cycle: spin 4 times → rent email appears → pay/skip → next floor or endless loop
5. Boss fight: special emails → Landlord fight → victory/death emails
