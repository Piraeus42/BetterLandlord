# TT Button.tscn__1.gd
**Scene:** TT Button.tscn
**Role:** General-purpose interactive button — the universal button widget used everywhere in the UI. Supports keyboard/controller/mouse input, hotkeys, toggle mode, hover highlight with color shift, press animation (shift +8px right), texture sprites, dynamic sizing, and TTS.

## Key Variables
- `color`, `color_type` — Background color and theme key
- `target`, `call`, `args[]` — Method dispatch (up to 3 args)
- `shortcuts[]` — Hotkey names from Options.hotkeys
- `active`, `hovering`, `down`, `held`, `toggle` — Interaction state
- `title_button`, `options_button`, `email_button`, `tall_button`, `scrollable_button` — Context flags
- `text_node`, `background`, `top`, `bottom`, `left`, `right` — Visual components
- `base_x` — Rest position X (shifts +8 when pressed)
- `current_scale`, `border_thickness`, `scale_mod` — Sizing
- `texture`, `sprite` — Optional texture icon
- `selector_alignment` — Controller nav alignment
- `delayed`, `dont_reset` — Special behavior flags
- `was_down_while_active`, `delay` — State machine helpers
- `centered_text_button` — Center text within button

## Methods
- **`_input(event)`** — Keyboard/mouse/controller against shortcuts; hover+click; press/release with input_type mode (0=on_press, 1=on_release)
- **`update()`** — Hover detection, controller selection, delay timer
- **`hover()`, `unhover()`** — Toggle background highlight
- **`press()`** — Shift right +8px, gold text, `do_call()` (input type 0)
- **`unpress()`** — Visual reset, `do_call()` (input type 1)
- **`visual_reset()`** — Restore position/color/text, set `down = false`
- **`do_call()`** — `target.call(call, args...)` with fallback for null target
- **`change_size()`, `update_size()`, `correct_size()`** — Button sizing pipeline with scale_mod and forced_size
- **`add_lines()`** — Redraw border edge Line2Ds
- **`reset_position()`** — Snaps to alignment anchor
- **`tts()`** — Screen reader: speaks button text
- **`can_be_pressed()`** — Validates parent UI is visible and focused

## Control Flow
Created everywhere a clickable element is needed. `_input()` handles raw input events. `update()` per-frame for hover/selection state. Press/release cycle calls `do_call()` to dispatch to target method (e.g., `set_floor(5)`, `spin()`, `resolve_event("pay_rent")`).
