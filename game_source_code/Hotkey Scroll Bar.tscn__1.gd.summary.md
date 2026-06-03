# Hotkey Scroll Bar.tscn__1.gd
**Scene:** Hotkey Scroll Bar.tscn (~211 lines)
**Role:** Options menu scroll bar — vertical draggable scroll bar with mouse drag, wheel scroll, and keyboard/controller support. Used for scrolling option lists.

## Symbols
- `can_drag`, `dragging` — Drag state
- `top`, `bottom`, `base_bottom` — Scroll handle bounds
- `border` — Visual border node
- `alignment_tags` — Right-aligned, bottom
- `need_to_update` — Dirty flag

## Methods
- **`_ready()`** — Sets up border reference, theme colors, mouse enter/exit signals
- **`update()`** — Keyboard/controller scroll via directional keys
- **`update_positions(event)`** — Mouse drag, wheel, trackpad handling with position clamping
- **`enter()`, `exit()`** — Toggle `can_drag` on hover

## Control Flow
Instanced by Options menu. Position drives the scroll offset of the parent container's content.
