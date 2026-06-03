# Landlord.tscn__9.gd
**Scene:** Landlord.tscn
**Role:** Boss fight controller — manages the Landlord's HP bar, damage queue, fine print system (boss abilities), entrance/death animations, and victory logic.

## Variables
- `hp = 750`, `max_hp = 750` — Current/max boss HP; scales with floor (1000 at F11, 1500 at F13+) or modded floor values
- `queued_damage` — Damage waiting to animate off the HP bar
- `fine_print_counter`, `fine_print_threshhold` — Fine print (boss ability) trigger; threshold = max_hp / 10
- `queued_fine_print[]`, `fine_print[]` — Pending and active fine print effects
- `possible_fine_print[]` — Pool of fine print numbers available to roll
- `total_fine_print = 31` — Total fine print effects in base game
- `stolen_symbols[]`, `stolen_items[]` — Items/symbols stolen by the boss, returned on death
- `doing_entrance_anim`, `anim_time` — Animation state

## Methods
- **`_ready()`** — UI scaling setup for CJK/font variations; calls `init_fine_print()`
- **`init_fine_print()`** — Builds pool of possible fine print: from modded floor's fine_print list (filtered by mod pack), or all 1-30+4 for base game
- **`spawn()`** — Entry point when boss fight begins: sets max_hp, thresholds, saves stats, calls `entrance_anim()`
- **`entrance_anim()`** — Makes landlord bar visible, sets initial HP for counting-up animation, re-inits fine print pool
- **`update()`** — Per-frame: updates HP display text, positions bar; handles HP entrance counting animation; applies queued damage animation; triggers `die()` when HP reaches 0; handles screen shake on hit
- **`take_damage(dmg_num)`** — Applies damage to HP, queues damage animation, plays hit SFX, triggers fine print additions when `fine_print_counter >= threshold` (1-3 fine prints per threshold depending on floor)
- **`get_fine_print(fp_arr)`** — Core fine print selection algorithm: filters by reliant types/groups (only spawns FP for symbols/items present on the board), by difficulty (F<15 excludes difficulty 1), favoritism toward symbols with highest count on board, handles dynamic icon selection
- **`die()`** — Victory handler: clears fine print, hides landlord bar, increments stats (landlord_executions, games_won), unlocks next floor if needed, returns stolen items/symbols, writes VICTORY log, triggers ending emails/events, restarts music, unlocks achievement 83

## Control Flow
1. `spawn()` called when boss fight starts → sets HP + entrance animation
2. `update()` runs each frame via Main._process() group "Update" → counts up HP, drains queued damage
3. `take_damage()` called each spin when coins deal damage → accumulates fine print threshold
4. `get_fine_print()` selects fine print effects based on board state
5. `die()` triggers on HP=0 after anim time → victory sequence
