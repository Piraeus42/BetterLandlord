# Main.tscn__1.gd — Slice Index (3382 lines)

## Variable Declarations (lines 1-109)
| Lines | Section |
|-------|---------|
| 1-15 | Databases: icon_texture, tile, item, fine_print, floor, inherited_effects, sfx, rarity |
| 16-26 | Config/state: init_config, save_string, window_focus, content_patch_num, version_str |
| 27-50 | Mod data: mod_packs, mod_names, mod_data, mod_groups, modded_existing, base_mod_fields, base_types |
| 51-69 | Sandbox state: sandbox_mode, sandbox_icons, sandbox_consistent |
| 70-99 | Input state: queued_errors, holding_*, down_keys, controller_type, mouse_position |
| 100-109 | Misc: existing_symbols, existing_items, tt_data |

## Methods by Line Range
| Lines | Method | Description |
|-------|--------|-------------|
| 111-114 | `_initialize_Steam()` | Steamworks init |
| 116-299 | `_input(event)` | **Input router** (~183 lines): keyboard/mouse/controller events, hotkeys, fast-forward, cursor hide, F8 log open, hidden key combos (DUNYA, F7, F3, 9) |
| 301-322 | `_init()` | Preload config, set locale/FPS/vsync, call load_data |
| 324-488 | `_ready()` | **Init sequence** (~165 lines): Steam init, load saves/mods/stats, resolution setup, grid sizing, email loading, title/config flow, font/CJK scaling, controller setup, HTTP request |
| 490-498 | `_http_request_completed(...)` | Remote TT data fetch callback |
| 500-807 | `_process(delta)` | **Main loop** (~308 lines): Steam callbacks, delta accumulator (60fps), reload timer, guillotine animation, hidden combo timers (UI reset, endless toggle, screen reader, Dunya), background mute, resolution change timer, cursor movement (held keys + controller), selector animation, hotkey display, alignment updates, group delegation, frame_timer |
| 809-830 | `check_controller_type(device_id, connected)` | Detect Xbox/PlayStation/Switch/Deck by name |
| 832-856 | `update_alignments()` | Apply alignment tags (centered, right, bottom, v_centered) |
| 858-869 | `get_replacement_texture(type)` | Texture replacement from mod art packs |
| 871-884 | `get_empty_data()` | Create empty SlotIcon instance |
| 886-1189 | `move_cursor(direction)` | **Cursor navigator** (~300 lines): find next selectable node in direction |
| 1191-1196 | `change_current_menu_path(path)` | Track current menu for cursor context |
| 1198-1255 | `get_selector_buttons()` | Cardinal neighbor detection for selector N/S/E/W buttons |
| 1257-1300 | `get_init_selectable_node()` | Find default selected element |
| 1302-1328 | `tts(string, values, node)` | Text-to-speech output |
| 1330-1341 | `title()` | Show title screen |
| 1343-1544 | `reset_values()` | **Game reset** (~200 lines): clear state for new run |
| 1546-1648 | `new_game()` | **New game** (~100 lines): init floor, symbols, items, save |
| 1650-1668 | `reload()` | Trigger scene reload |
| 1670-1811 | `continue_game()` | **Load and resume** (~140 lines): restore from save |
| 1813-1835 | `write_log(string)` | Game event logging |
| 1837-1849 | `save_log()` | Flush log to file |
| 1851-1870 | `write_error(string)` | Error logging |
| 1872-1881 | `save_errors()` | Flush errors to file |
| 1883-1893 | `init_sandbox()` | Sandbox mode setup |
| 1895-1911 | `save_game()` | Serialize full game state |
| 1913-1928 | `save_options()` | Settings persistence |
| 1930-1946 | `save_stats()` | Stats persistence |
| 1948-1964 | `backup_stats()` | Stats backup |
| 1966-1993 | `preload_config(p_str)` | Read config files |
| 1995-2071 | `load_sandbox()` | Sandbox state restore |
| 2073-2895 | `load_data(save_ids, load_saved_ids, past_init)` | **Data loader** (~820 lines): populate ALL databases from JSON, mod merging, art replacements, starting items/symbols, mod_on_*_effects arrays |
| 2897-2914 | `load_mods()` | Scan mod directories, load JSON manifests |
| 2916-2959 | `load_game()` | Deserialize full game state |
| 2961-2994 | `load_options()` | Restore settings |
| 2996-3083 | `load_stats()` | Restore stats |
| 3085-3088 | `get_rarity(db, type)` | Rarity lookup |
| 3090-3094 | `get_last_tab_or_space(string)` | String helper |
| 3096-3102 | `check_for_allowed_function(...)` | Security blacklist scan |
| 3104-3192 | `malicious_mod(path, m)` | **Security check** (~90 lines): scan mod scripts for OS.execute, FileAccess, etc. |
| 3194-3200 | `get_appended_steam_id(string, type)` | Mod ID resolution |
| 3202-3208 | `append_steam_id(string, id)` | Steam ID → type string |
| 3210-3230 | `increase_string_values(string, num)` | Value tag increment |
| 3232-3285 | `is_mod_disabled(m_str)` | Check if mod/type is disabled |
| 3287-3300 | `add_to_counted_symbols(dict)` | Register counted symbol groups |
| 3302-3357 | `check_valid_var(string, type, ...)` | Validate mod data against base_mod_fields |
| 3359-3374 | `display_error(error_type, error)` | Queue error for display |
| 3376-3377 | `exit()` | Quit game |
| 3379-3382 | `delete_save()` | Delete save file |
