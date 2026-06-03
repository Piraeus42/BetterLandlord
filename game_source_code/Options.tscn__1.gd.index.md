# Options.tscn__1.gd — Slice Index (3000 lines)

## Variable Declarations (lines 1-111)
| Lines | Section |
|-------|---------|
| 1-8 | Menu state: menu, menu_buttons, disabled_mods |
| 9-32 | UI elements: option_types, option_buttons, dropdown_buttons, option_texts, option_sliders, hyperlinks, slider_texts |
| 33-35 | Navigation: source_button, last_menu |
| 36-39 | Resolution/framerate/language arrays |
| 40 | Language code mappings (20 languages) |
| 41-42 | Credits/CJK_credits dictionaries (~120 translators) |
| 43-44 | assignable_hotkeys (21), fonts (3), input_types, soundtrack_types |
| 45-49 | default_colors (50+ color keys), colors3, ui_scaling (8 dimensions) |
| 50-111 | Config vars: language, CJK_lang, RTL_lang, resolution, fullscreen, vsync, speeds, volumes, accessibility |

## Methods by Line Range
| Lines | Method | Description |
|-------|--------|-------------|
| 112-177 | `_input(event)` | Input handling for options menu |
| 179-214 | `_ready()` | Setup: alignment, visibility, Steam Deck detection |
| 216-251 | `get_spacing()` | Button spacing calculation from resolution |
| 253-254 | `open_mods(s_b)` | Open mod management submenu |
| 256-309 | `open(s_b)` | Open options menu with transition |
| 311-385 | `close()` | Close options, save settings |
| 387-403 | `set_max_scaling()` | Max UI scaling heuristics |
| 405-487 | `auto_set_scaling()` | Auto-detect optimal UI scaling |
| 489-548 | `add_dropdown(s)` | Dropdown menu factory |
| 550-784 | `add_dropdown_button(...)` | Dropdown button factory (~235 lines) |
| 786-794 | `get_credit(s)` | Credit string formatting |
| 796-890 | `add_option_text(s)` | Text/credit entry factory |
| 892-893 | `godot()` | Easter egg: open Godot website |
| 895-907 | `toggle_mod_display(s)` | Mod toggle button renderer |
| 909-1348 | `add_button(s)` | **Button factory** (~440 lines): settings toggle/cycle buttons with all variants |
| 1350-1362 | `toggle_normal_track/endless_track/change(s)` | Music/endless toggle wrappers |
| 1373-1382 | `disable_mod(mod)` | Toggle individual mod |
| 1384-1407 | `disable_mod_pack(mod)` | Toggle entire mod pack |
| 1409-1423 | `add_menu_buttons()` | Top-level menu category buttons |
| 1425-1443 | `tts()` | Screen reader output |
| 1445-1647 | `change_menu(p_menu, color, ...)` | **Menu switcher** (~200 lines): switch between submenus (graphics, audio, language, input, mods, credits, colors, stats, accessibility) |
| 1649-1761 | `add_system_buttons()` | System button factory (~110 lines) |
| 1763-1815 | `add_menu_button(type)` | Individual menu button factory |
| 1817-1827 | `update_mod_str(...)` | Steam Workshop mod info callback |
| 1829-2223 | `add_buttons()` | **Settings UI generator** (~395 lines): generates ALL buttons for current submenu |
| 2225-2231 | `add_option_slider(setting)` | Slider control factory |
| 2233-2244 | `remove_system_buttons()` | Cleanup system buttons |
| 2246-2290 | `remove_buttons()` | Cleanup all current buttons |
| 2292-2301 | `reset_scrollables()` | Reset scrollbar positions |
| 2303-2397 | `reset_text()` | Refresh all text nodes (~95 lines) |
| 2399-2474 | `reset_email()` | Refresh email texts |
| 2476-2534 | `reset_buttons()` | Rebuild all buttons for current menu |
| 2536-2779 | `update_setting(setting, choice)` | **Settings dispatcher** (~245 lines): resolution, fullscreen, vsync, FPS, language, font, UI scaling, volume, input type, speeds, hotkeys, colors, accessibility |
| 2781-2785 | `update_goal_volume(setting)` | Volume tween update |
| 2787-2915 | `reset_to_default(type, update_and_save)` | **Factory reset** (~130 lines): reset settings category to defaults |
| 2917-2933 | `add_to_base_y_positions(c)` | Layout helper |
| 2935-2960 | `assign_hotkey(btn)` | Hotkey rebinding workflow |
| 2962-3000 | `save()` | Serialize all settings |
