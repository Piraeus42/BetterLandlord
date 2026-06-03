# Main.tscn__1.gd
**Scene:** Main.tscn (~3383 lines)
**Role:** Root game controller — the central hub for everything: Steam init, input handling (keyboard/mouse/controller), game loop (`_process`), save/load, data loading, sandbox mode, mod management, cursor/selector navigation, screen reader TTS, and scene transitions.

## Key Data Structures
- **Databases:** `tile_database`, `item_database`, `fine_print_database`, `apartment_floor_database`, `icon_texture_database`, `sfx_database`, `rarity_database`, `group_database` — All game content loaded from JSON
- **Mod state:** `mod_packs`, `mod_pack_nums`, `mod_names`, `mod_data`, `mod_groups`, `modded_existing`, `modded_existing_base_types`, `starting`, `disabled_mods`, `mod_reverse_effects[]`, `mod_multiple_effects[]`, `mod_on_symbol_add_effects[]`, `mod_on_item_add_effects[]`, `mod_on_rent_paid_effects[]`, `modded_fine_print_nums[]`, `modded_apartment_floors{}`
- **Input state:** `down_keys{}`, `down_scancodes[]`, `down_key_delay=4`, `lmb_down`, `mouse_position`, `controller_type`, `last_input_was_controller`, `controllers`
- **UI state:** `selected_node`, `cursor_timer`, `hide_selector`, `displayed_hotkey_sources[]`, `hotkey_button_strings[]`, `selector_buttons[]`
- **Game state:** `frame_timer`, `guillotine_essence_anim`, `sandbox_mode`, `sandbox_icons`, `sandbox_consistent`, `testing_fine_print`
- **Constants:** `content_patch_num=2`, `hotfix_num=24`, `version_str`, `demo`
- **Config:** `init_config{}`, `need_config`, `save_string`
- **Tracking:** `existing_symbols{}`, `existing_items{}`, `counted_symbols{}`, `log_queue[]`, `error_queue[]`, `queued_errors[]`

## Major Methods

### Initialization
- **`_init()`** — Preloads config; sets locale, FPS, vsync from saved settings; calls `load_data(false, false, false)`
- **`_ready()`** — Steam init, loads save/stats/options, connects HTTP request, sets up resolution/font/CJK scaling, handles Steam Deck detection, loads mods, connects signals, initializes cursor/selector, calls `title()` or first-time config

### Per-Frame
- **`_process(delta)`** — Main game loop (runs at 60fps via delta accumulator): Steam callbacks, reload timer, guillotine animation, hidden key combos (UI reset with 9, endless toggle with F7/7, screen reader toggle with F3/3, Dunya easter egg with DUNYA), background mute, resolution change timer, cursor movement via held keys/controller, selector animation, hotkey display, node alignment updates, delegates to group "Update"/"Pause Update"/"Visible Update" nodes

### Input
- **`_input(event)`** — All input: F8 opens logs dir; tracks held keys D/U/N/Y/A; fast-forward speed offsets; F7/F3 hold timers for toggles; mouse motion hides selector; keyboard/mouse/controller hotkey processing with key repeat and clear logic; joystick axis → directional movement; LMB tracking

### Data Loading
- **`load_data(save_ids, load_saved_ids, past_init)`** — Massive method: populates all databases (tile, item, fine_print, floor, rarity, group, sfx) from JSON files; handles mod loading/merging; sets up `existing_symbols`/`existing_items` mappings; applies art replacements; processes starting symbols/items; populates `mod_on_*_effects` and `mod_reverse/multiple_effects` arrays

### Save/Load
- **`save_game()`**, **`load_game()`** — Serialize/deserialize full game state
- **`save_options()`**, **`load_options()`** — Settings persistence
- **`save_stats()`**, **`load_stats()`**, **`backup_stats()`** — Stats persistence with backup
- **`preload_config(p_str)`** — Reads config files to init_config

### Mod System
- **`load_mods()`** — Scans mod directories, loads JSON manifests, validates
- **`is_mod_disabled(m_str)`** — Checks if a mod/type is in disabled_mods
- **`malicious_mod(path, m)`** — Security: checks for OS.execute, FileAccess, etc. in mod scripts
- **`check_for_allowed_function(file_text, inc)`** — Blacklist-based security scan
- **`append_steam_id(string, id)`**, **`get_appended_steam_id(string, type)`** — Mod ID handling
- **`increase_string_values(string, num)`** — Increments value tags in mod strings
- **`check_valid_var(string, type, ...)`** — Validates mod data fields against `base_mod_fields`

### UI/Cursor
- **`move_cursor(direction)`** — Finds next selectable node in given direction
- **`change_current_menu_path(path)`** — Tracks current menu for cursor context
- **`get_selector_buttons()`** — Finds cardinal neighbor nodes for selector
- **`get_init_selectable_node()`** — Finds default selected element
- **`update_alignments()`** — Applies alignment tags (centered, right, bottom, v_centered) to nodes after resolution change
- **`display_error(error_type, error)`** — Queues error for display
- **`get_replacement_texture(type)`** — Handles texture replacement from mod art packs
- **`get_empty_data()`** — Creates an "empty" slot icon instance

### Game Flow
- **`title()`** — Shows title screen
- **`new_game()`** — Starts a new game session
- **`continue_game()`** — Resumes from save
- **`reset_values()`** — Clears game state for new run
- **`reload()`** — Triggers scene reload
- **`exit()`** — Quits the game
- **`delete_save()`** — Deletes save file

### Debug/Logging
- **`write_log(string)`**, **`save_log()`** — Game event logging to `run_logs/`
- **`write_error(string)`**, **`save_errors()`** — Error logging

### Sandbox
- **`init_sandbox()`**, **`load_sandbox()`** — Sandbox mode setup

### Misc
- **`check_controller_type(device_id, connected)`** — Detects Xbox/PlayStation/Switch controller by name
- **`tts(string, values, node)`** — Text-to-speech output
- **`get_rarity(db, type)`** — Gets rarity tier for symbol/item
- **`add_to_counted_symbols(dict)`** — Registers counted symbol groups
- **`get_last_tab_or_space(string)`** — String helper
- **`_http_request_completed(...)`** — Fetches remote TT data JSON for promo display

## Control Flow Summary
1. `_init()` → preload config, set locale/FPS/vsync, load data
2. `_ready()` → init Steam, load saves/mods/stats, set up UI scaling, show title (`title()`) or first-time config
3. `_process()` → main loop: handles input, cursor, alignment, timers, delegates to subsystems
4. `_input()` → all hardware input routing: keyboard, mouse, controller, hotkeys
5. User clicks "New Game" → `new_game()` → `reset_values()` → floor selection → game loop
6. Game loop: `Reels.spin()` → effects evaluation → coin counting → rent payment → repeat
