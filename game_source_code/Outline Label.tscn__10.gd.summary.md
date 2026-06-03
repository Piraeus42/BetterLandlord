# Outline Label.tscn__10.gd
**Scene:** Outline Label.tscn (extends Pico Label)
**Role:** Outline/border text renderer — creates a 3×3 grid of shadow text nodes (8 border + 1 foreground) for a chunky outline effect. Handles scaling, CJK font switching, icon size overrides, and dynamic layout. The base class for all text displays in the game (coin sums, HP sum, extra sum, effect texts, etc.).

## Variables
- `color = "FFFFFF"` — Font color hex
- `texts[]` — Array of child Pico Label instances (8 border + 1 foreground in non-CJK mode)
- `force_update`, `size_update` — Dirty flags triggering re-layout
- `current_scale`, `base_scale`, `saved_scale` — Font scaling
- `scale_mod`, `text_mod` — UI scaling modifiers
- `custom_icon_offset` — Vector2 offset for icon placement
- `forced_font_size` — Explicit font size override
- `hyperlinks[]` — Associated hyperlink data
- `tooltip_desc`, `effect_text` — Context flags
- `forced_pico` — Force PICO-8 rendering in CJK mode
- `button_text` — Whether this is button label text
- `difference_cjk_space` — CJK spacing adjustment
- `can_display_decimals` — Decimal display toggle

## Methods
- **`_init()`** — Locale check; non-CJK mode builds 8+1 border text grid via `add_texts()`
- **`_ready()`** — Reads Options.display_font + ui_scaling, sets up fonts
- **`remove_texts()`** — Clears all border children, reverts to single text node
- **`add_texts()`** — Creates 3×3 Pico Text grid: 8 border positions + 1 foreground
- **`update_border()`** — Repositions border children based on current_scale
- **`set_icon_size()`** — Calculates per-pixel icon offsets (1000+ lines across variants for CJK, NotoSans, OpenDyslexic, PICO-8, each locale, each ui_scaling tier)
- **`change_set_size(n)`** — Sets forced font size after applying UI scale modifiers and CJK adjustments
- **`remove_icons(force)`** — Cleans up color texts and icons
- **`update()`** — Per-frame: handles alignment, size changes, scaling

## Control Flow
External callers set `raw_string` → `update()` → `check_locale()` (inherited from Pico Label) does line breaking → `set_icon_size()` positions inline icons → border children repositioned via `update_border()`.
