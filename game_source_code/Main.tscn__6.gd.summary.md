# Main.tscn__6.gd
**Scene:** Main.tscn
**Role:** Title screen controller — main menu, floor selection, stats display, mod info, promo buttons, and external links.

## Variables
- `buttons[]` — Main menu button list
- `floor_buttons[]` — Floor selection grid buttons
- `patch_time` — Unix timestamp for countdown display
- `promo_button`, `promo_button2` — Promotional buttons (Steam, iOS, Android, plushie, etc.)
- `page_button`, `page_button2` — Pagination for modded floors
- `modded_floor_page` — Current page of modded apartment floors
- `floor_mods[]` — Hardcoded array of floor modifier definitions (string + values + position)
- `mod_button` — Mods button
- `back_button`, `achievements_button`, `merch_button`, etc.

## Methods
- **`_ready()`** — Creates logo, social, and merch buttons; sets up page buttons
- **`update()`** — Per-frame: renders version string + patch countdown timer
- **`draw()`** — Full title screen render: localized title, creates all menu buttons (New Game, Continue, Options, Stats, Exit, Mods), shows promo buttons based on time gates and locale
- **`floor_menu()`** — Renders floor selection grid (1 through highest_unlocked_floor), handles modded floor pages
- **`stats_menu()`** — Renders floor grid for stats viewing, includes "All" button and achievements button
- **`set_floor(fl)`** — Displays floor modifier descriptions for selected floor (crunches `floor_mods` data into readable text)
- **`show_stats(fl)`** — Displays stats for selected floor (games played/won, winstreaks, executions, etc.)
- **`draw_title_text()`** — Scales and positions the localized title text to fit screen
- **`update_button_positions()`** — Layout engine for main menu buttons
- **`update_promo_button_positions()`** — Positions promo buttons, avoids overlap with logo
- **`set_mod_text_scale()`** — Scales mod description text to fit available space
- **`scroll_mods_left/right()`** — Pagination through modded floor packs
- **`reset_floor_menu()`** — Destroys and recreates floor buttons
- **`remove()`** — Tears down all title UI, restores in-game menu buttons
- **`website/discord/steam/merch/ios/android/pizza/twitter/tt_data()`** — Opens external URLs via `OS.shell_open()`
- **`tts()`** — Text-to-speech: sends info text + mod text to screen reader

## Control Flow
1. `_ready()` creates static social/promo buttons
2. `draw()` is called when title screen should appear → creates all menu buttons, promo logic
3. `update()` runs per-frame, displays version + countdown
4. User clicks "New Game" → `floor_menu()` → floor grid appears → `set_floor()` on select → game starts
5. User clicks "Stats" → `stats_menu()` → floor grid → `show_stats()` on select
