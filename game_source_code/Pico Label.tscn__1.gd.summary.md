# Pico Label.tscn__1.gd
**Scene:** Pico Label.tscn (core text label, extends ALabel)
**Role:** The core text rendering engine. Supports CJK line-breaking rules, inline icon placement, colored text spans (`<color_XXXXXX>`), escape tag parsing (`<icon_>`, `<value_N>`, `<hotkey_N>`, etc.), RTL (Arabic) layout, and multi-language font loading per locale.

## Key Constants
- `cant_start_line_zh`, `cant_end_line_zh`, `cant_break_line_zh` — CJK line-breaking prohibition characters for zh, tc, ja, th, ar

## Variables
- `icons[]`, `icon_positions[]` — Inline icon instances and their character indices
- `colors[]`, `color_texts[]`, `color_positions[]` — Colored span tracking
- `values[]` — Injected numeric values for `<value_N>` tags
- `dynamic_icons[]` — Runtime-resolved icon type strings
- `border_text` — Whether this is a border shadow child
- `forced_font` — Externally-forced DynamicFont
- `custom_max_width` — Override for max layout width
- `cjk`, `rtl` — CJK/RTL rendering mode
- `raw_string` — Original unparsed text with markup
- `v_spaced`, `e_spaced`, `i_spaced` — Special spacing modes

## Methods
- **`parse_escape(s, pos, n, dr)`** — Parses markup tags: `<i>` (icon), `<c>` (color hex), `<e>` (end), `<v>` (value ref), `<h>` (hotkey), `<g>` (group), `<l>` (last), `<d>` (dynamic), `<b>` (button), `<t>` (theme color), `<s>` (symbol)
- **`check_locale()`** — Core layout engine: walks text character by character, measures widths, inserts `\n` at break points using per-locale character prohibition rules
- **`parse_num_str(st)`** — Formats numbers: scientific notation for large values, digit separators per locale, decimal separators
- **`change_icon_size_override(size, i_offset)`** — Sets icon scaling and offset
- **`_init()`** — Loads locale-appropriate font (NotoSans per locale or PICO-8)

## Control Flow
1. Text set via `raw_string`
2. `check_locale()` drives layout: walks text, inserts line breaks per locale rules
3. `parse_escape()` converts markup tags to internal placeholder characters
4. After layout: icons positioned, colored spans split into child PicoText nodes
