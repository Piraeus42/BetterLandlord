# Option Slider.tscn__1.gd
**Scene:** Option Slider.tscn
**Role:** Draggable slider control widget, used for option adjustments (volume, color channels, scaling, etc.).

## Symbols
- Various drag-state variables: `dragging`, `drag_start_pos`, `value`, `min_value`, `max_value`

## Methods
- **`set_value(v)`** — Sets slider value, clamped to min/max
- Input handling for mouse drag to adjust slider position
- Visual update of slider knob position

## Control Flow
Responds to mouse press/drag/release events. Used as a generic slider component throughout the options menu.
