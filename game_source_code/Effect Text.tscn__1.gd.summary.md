# Effect Text.tscn__1.gd
**Scene:** Effect Text.tscn (extends Outline Label)
**Role:** Animated floating text for spin values — displays coin/reroll/removal/essence values over symbols and items, animates toward the coin counter, and draws connecting slot lines.

## Variables
- `animating`, `effect_timer` — Animation state
- `lines[]`, `line_targets[]` — Slot line connections to draw between matching symbols
- `start_pos`, `goal_pos` — Animation start/end positions
- `coin_value`, `reroll_value`, `removal_value`, `essence_value` — Values to show and transfer
- `instant_fanfare` — Skip animation flag
- `hidden` — Whether this text is on a non-visible page

## Methods
- **`_ready()`** — Sets font, scaling, CJK mode, base_scale
- **`set_goal_pos(num)`** — Sets goal Y position based on number of currency lines (0=bottom, 1=mid, 2=top)
- **`update()`** — Per-frame: animates effect_timer downward, delegates to `execute_effect()` with speed scaling
- **`execute_effect()`** — Animation phases: timer 155-160 = rise up and appear; timer 125-113 = move toward goal; timer 108-113 = flush values to Coin Sum/Extra Sum/HP Sum; timer <=108 = idle visible
- **`add_lines()`** — Creates SlotLine instances connecting this text to target positions
- **`update_lines()`** — Updates line endpoint positions to track text movement

## Control Flow
Created per symbol/item cell each spin. Values displayed at cell, then animated to coin counter position with optional colored lines connecting related symbols.
