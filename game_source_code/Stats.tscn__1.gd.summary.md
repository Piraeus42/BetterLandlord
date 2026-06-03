# Stats.tscn__1.gd
**Scene:** Stats.tscn
**Role:** Player statistics and Steam achievement tracking — tracks all per-floor stats, manages achievement unlocking with localized unit conversion, and handles Steam achievement sync.

## Key Variables (all arrays indexed by floor or global)
- `highest_unlocked_floor = 1` — Floor progression
- `essences_unlocked`, `stats_unlocked`, `bossfight_unlocked` — Feature gates
- `total_games_played[]`, `total_games_won[]` — Per-floor counts
- `current_winstreaks[]`, `highest_winstreaks[]` — Streak tracking
- `billionaires_guillotined[]`, `time_spent_petting_dog[]`, `rabbit_fluff_shed[]`, `humans_murdered_by_general_zaroff[]`, `alcohol_consumed[]`, `times_executed[]`, `rabbit_hops[]`, `landlord_executions[]` — Miscellaneous per-floor stats
- `achievements_unlocked[186]` — Achievement unlock bitmask
- `chievos[]` — Pending Steam achievement queue
- `unlocking` — Steam callback in progress
- `landlord_fates_seen[]`, `landlord_fates_not_seen[]` — Landlord fate tracking
- `unlocked_modded_floors[]` — Modded floor unlocks
- `killed` — Whether landlord was killed this run
- `just_won[]` — Recently won floors for streak tracking

## Methods
- **`unlock_achievement(a_num, save_stat)`** — Sets achievement bit, queues Steam unlock, calls `unlock_local_chievos()` on first call
- **`unlock_local_chievos()`** — Unlocks Steam-API-independent achievements
- **`unlock_chievo(game, result, user)`** — Steam callback: batch-syncs achievement queue
- **`add_stat(stat, apartment_floor, num, save_stat)`** — Increments a per-floor stat array, auto-triggers achievement checks (e.g., billionaires_guillotined thresholds)
- **`get_converted_stat(stat, apartment_floor)`** — Reads stat with locale-aware unit conversion (lbs↔kg, gal↔L)
- **`add_to_games_played(floor)`**, **`add_to_games_won(floor)`**, **`add_to_games_lost(floor)`** — Game count tracking with winstreak and achievement triggers
- **`check_if_bossfight_unlocked()`** — Gates at 9 total wins
- **`check_if_essences_unlocked()`** — Gates essence items
- **`check_if_stats_unlocked()`** — Gates stats visibility
- **`save()`** — Serializes all stats and achievement arrays

## Control Flow
Stats updated by game events (spins, wins, losses, guillotine). Thresholds trigger achievements. Steam sync is queued via `chievos[]` and batch-synced via callback.
