# Hover Icon.tscn__1.gd
**Scene:** Hover Icon.tscn (~750 lines)
**Role:** Interactive icon widget — handles hover tooltips, symbol/item removal via right-click, press logic, keyboard navigation, TTS, and the eldritch transformation system. Used as the clickable representation of symbols/items in the UI.

## Key Variables
- `type` — Symbol/item type identifier
- `hovering`, `active`, `selectable` — Interaction states
- `tooltip_card` — Whether a tooltip card is currently shown
- `destroyable` — Whether right-click removal is allowed
- Various hover/press/delay timers

## Methods
- **`_ready()`** — Sets up texture, hitbox, connects to orphan cleanup
- **`update()`** — Per-frame: hover detection, position tracking
- **`hover()`** — Mouse enter: creates tooltip card, plays SFX, highlights
- **`unhover()`** — Mouse leave: removes tooltip, clears highlight
- **`press()`** — Left click: triggers selection/spin depending on context
- **`toggle_disabled()`** — Enables/disables the item
- **`check_removal_triggers(icon)`** — Right-click removal logic with confirmation checks
- **`add_empty()`** — Replaces icon with empty slot after removal
- **`update_eldritch()`** — Handles eldritch transformation animation/state
- **`can_add_tooltip()`** — Checks whether tooltip should appear
- **`update_hitbox()`** — Recalculates click/intersection area
- **`tts()`** — Screen reader: speaks icon details

## Control Flow
Mouse hover → creates Card tooltip. Left click → press → delegate to parent. Right click → removal if destroyable. Controller select → same press logic.
