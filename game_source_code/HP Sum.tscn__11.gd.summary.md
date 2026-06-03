# HP Sum.tscn__11.gd
**Scene:** HP Sum.tscn (extends Outline Label)
**Role:** Boss fight HP damage display — shows the accumulating damage from the current spin, animates toward the Landlord's HP bar, then applies via `Landlord.take_damage()`.

## Variables
- `hp_value` — Accumulated damage being displayed
- `adding`, `delay = 25` — Animation state
- `start_pos` — Starting Y position

## Methods
- **`_ready()`** — Sets CJK/font display, icon z-index, starts invisible
- **`add_value(hp)`** — Only active during boss fights; formats HP display with red HP icon, sets animation start position
- **`update()`** — Per-frame: animates damage text toward landlord HP bar position, flushes damage via `Landlord.take_damage(round(hp_value))`, hides when not in boss fight
- **`save()`** — Serializes position + value state

## Control Flow
Spin damage values → `add_value()` → text animates diagonally toward landlord HP bar → `Landlord.take_damage()` → landlord HP decreases.
