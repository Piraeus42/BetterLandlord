# Popup Scroll Bar.tscn__1.gd
**Scene:** Popup Scroll Bar.tscn
**Role:** Vertical scroll bar for the pop-up email container. Handles mouse drag, scroll wheel, trackpad gestures, and keyboard/controller scrolling. Auto-scrolls to follow the selected node.

## Variables
- `can_drag`, `dragging` — Drag state
- `top`, `bottom`, `base_bottom` — Scroll handle bounds
- `border` — Visual border ColorRect
- `last_pos_y` — Previous Y position for change detection
- `first_email_input` — First keyboard scroll flag
- `alignment_tags` — Right-aligned, bottom-aligned

## Methods
- **`_ready()`** — Positions at right edge, applies theme colors, connects mouse enter/exit for border
- **`update()`** — Keyboard scroll via directional keys, auto-scroll to `selected_node`
- **`update_positions(event)`** — Mouse drag, scroll wheel, trackpad gesture handling with position clamping
- **`enter()`, `exit()`** — Toggle `can_drag` on mouse hover

## Control Flow
Scroll bar position (`rect_position.y` between top/bottom) drives parent `Pop-up` content scroll offset.
