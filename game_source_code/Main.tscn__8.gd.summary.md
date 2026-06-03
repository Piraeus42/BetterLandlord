# Main.tscn__8.gd
**Scene:** Main.tscn
**Role:** Error display overlay — manages timed error messages with fade.

## Methods
- **`add_error(msg)`** — Adds an error message to the display queue
- **`display()`** — Per-frame display update, handles timing and fade-out of visible errors

## Control Flow
Called from Main's `_process()` each frame. Errors are added to a queue and displayed with a timer-based auto-dismiss + fade.
