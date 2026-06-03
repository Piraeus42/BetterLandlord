# Options.tscn__1.gd
**Scene:** Options.tscn
**Role:** Full options/settings menu controller — manages all game settings, mod management, credits, hotkey rebinding, UI scaling, color customization, and save/load of settings.

## Key Data
- `x_resolutions[15]`, `y_resolutions[15]` — Supported resolution pairs
- `framerates[]` — 30, 60, 120, 144, 240, uncapped
- `languages[20]`, `language_codes[20]` — All supported locales
- `credits{}`, `CJK_credits{}` — Full credits dictionaries with translator names
- `assignable_hotkeys[21]` — All rebindable hotkey actions
- `fonts[]` — SinsGold, NotoSans, OpenDyslexic
- `ui_scaling{}` — text, reels_ui, items_ui, buttons, tooltips, emails, inventory, symbol_item_selections
- `default_colors{}`/`colors3{}` — ~50 color keys for all UI elements
- `disabled_mods[]` — List of disabled mod IDs

## Major Methods
- **`_ready()`** — Detects Steam Deck, loads settings, sets up resolution/font scaling
- **`open(s_b)`**, **`close()`** — Show/hide options menu with transition
- **`open_mods(s_b)`** — Opens mod management submenu
- **`change_menu(p_menu, color, menu_button_pushed)`** — Switches between submenus (graphics, audio, language, input, mods, credits, colors, stats, accessibility)
- **`update_setting(setting, choice)`** — Core settings dispatcher: applies resolution, fullscreen, vsync, FPS, language, font, UI scaling, volume, input type, spin/animation/counting/menu speed, hotkeys, colors, accessibility features
- **`reset_to_default(type, update_and_save)`** — Resets settings category to defaults
- **`add_buttons()`** — Generates all settings UI buttons for current submenu
- **`add_menu_buttons()`** — Top-level menu category buttons (graphics, audio, etc.)
- **`add_button(s)`** — Creates individual setting toggle/cycle buttons
- **`add_option_slider(setting)`** — Creates slider controls for volume, scaling
- **`add_dropdown(s)`**, **`add_dropdown_button(s, ...)`** — Dropdown menus for language, resolution, FPS, font
- **`add_option_text(s)`** — Adds text headers and credits entries
- **`get_credit(s)`** — Formats credit strings with color-coded names
- **`assign_hotkey(btn)`** — Handles hotkey rebinding workflow
- **`disable_mod(mod)`**, **`disable_mod_pack(mod)`** — Toggle individual mods or entire mod packs
- **`toggle_mod_display(s)`** — Renders mod toggle buttons with descriptions
- **`toggle_normal_track/endless_track/change(s)`** — Music/endless mode toggles
- **`update_mod_str(handle, result, ...)`** — Steam Workshop mod info callback
- **`reset_scrollables()`** — Resets scrollbar positions
- **`reset_text()`** — Refreshes all text nodes
- **`reset_email()`** — Refreshes email texts
- **`reset_buttons()`** — Rebuilds all buttons for current menu
- **`set_max_scaling()`**, **`auto_set_scaling()`** — UI scaling heuristics
- **`save()`** — Serializes all settings to save dict
- **`tts()`** — Screen reader output for current menu
- **`godot()`** — Easter egg: opens Godot website
- **`get_spacing()`** — Calculates button spacing from resolution

## Control Flow
1. `_ready()` loads settings from disk, detects platform
2. `open()` → `change_menu("graphics")` → `add_buttons()` renders the menu
3. `update_setting()` handles every setting change, triggers save + UI refresh
4. `change_menu()` switches between settings sub-pages
5. Most changes call `save_options()` → writes to `user://LBAL-Settings.save`
