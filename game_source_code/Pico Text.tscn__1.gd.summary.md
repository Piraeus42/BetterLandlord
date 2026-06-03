# Pico Text.tscn__1.gd
**Scene:** Pico Text.tscn (clickable text label, extends Label)
**Role:** A Label with mouse hover highlighting and hyperlink click support. Opens URLs via `OS.shell_open()`. Used for colored text spans, clickable links, and controller-navigable text elements.

## Variables
- `hyperlink` — URL to open on press, or null
- `active`, `hovering`, `selectable` — Interaction states
- `background` — Hitbox ColorRect
- `color`, `hover_color` — Base and highlight colors (hover_color = color.v + 0.2)
- `delay` — Frames before hover re-activates (set to 3 on focus loss)
- `dont_remove` — Prevent parent cleanup from removing
- `selector_alignment = "hyperlink"` — How the controller selector frames this

## Methods
- **`_init()`** — Loads locale-appropriate font
- **`_ready()`** — Sizes background hitbox, sets up hyperlink from parent's hyperlinks array
- **`_input(event)`** — Left-click detection when hovering → `press()`
- **`update()`** — Per-frame: hover detection via mouse position vs background rect; controller selection with confirm key; delay timer for focus-loss debounce
- **`press()`** — Opens hyperlink URL via `OS.shell_open()`

## Control Flow
`update()` checks mouse position vs background rect → sets `hovering`. Controller navigation via `selected_node` comparison. `press()` triggers URL opening when hyperlink is set.
