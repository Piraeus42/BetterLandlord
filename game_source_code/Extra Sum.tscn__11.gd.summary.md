# Extra Sum.tscn__11.gd
**Scene:** Extra Sum.tscn (extends Outline Label)
**Role:** Token sum display — shows accumulating reroll/removal/essence tokens from the current spin, animates toward the coin counter, updates the removal button visibility when tokens are available.

## Variables
- `reroll_value`, `removal_value`, `essence_value` — Accumulated token counts
- `adding`, `delay = 25` — Animation state
- `start_pos` — Target Y position

## Methods
- **`_ready()`** — Sets CJK/font mode, icon z-index
- **`add_value(reroll, removal, essence)`** — Adds token counts, formats multi-currency display string with colored icons, sets start position
- **`update()`** — Per-frame: animates text toward coin counter, on completion updates removal button visibility and flushes values
- **`save()`** — Serializes position + token values

## Control Flow
Tokens earned from spins accumulate here → animate upward → flush → update removal button in buttons menu. Only shown during boss fights alongside HP Sum.
