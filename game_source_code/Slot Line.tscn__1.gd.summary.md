# Slot Line.tscn__1.gd
**Scene:** Slot Line.tscn
**Role:** Draws a decorative `Line2D` connecting related symbols in the slot area. Used by Effect Text to show symbolic connections.

## Methods
- **`_ready()`** — Sets line color to `#06799F`, adds two origin points, round end caps, line width 3

## Control Flow
Single `_ready()` entry. Endpoint positions updated later by parent Effect Text's `update_lines()`.
