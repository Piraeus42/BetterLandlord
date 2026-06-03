# Scripts Summary Index

37 GDScript files organized by architectural layer. Each has a `.summary.md` companion; files over 2000 lines also have a `.index.md` slice index.

---

## Core Engine (3 files)

| File | Lines | .index | Summary |
|------|-------|--------|---------|
| `Main.tscn__1.gd` | 3382 | [✓](Main.tscn__1.gd.index.md) | Root controller: Steam, input, main loop, save/load, mod loading, cursor nav |
| `Main.tscn__4.gd` | 2133 | [✓](Main.tscn__4.gd.index.md) | Reels/slot-machine engine: spin, effects, value calculation, clumps |
| `Pop-up.tscn__1.gd` | 3860 | [✓](Pop-up.tscn__1.gd.index.md) | Event/popup system: emails, cards, rent, deck drawing, game flow |

## Game Objects (4 files)

| File | Lines | .index | Summary |
|------|-------|--------|---------|
| `Slot Icon.tscn__1.gd` | 5760 | [✓](Slot Icon.tscn__1.gd.index.md) | Full symbol: 4 value pipelines, effect engine, animations, SFX |
| `Item.tscn__1.gd` | 3189 | [✓](Item.tscn__1.gd.index.md) | Item logic: var_math expressions, conditional effects, destroy pipeline |
| `Reel.tscn__1.gd` | ~740 | — | Single reel column: spin animation, tile add/remove, click-to-spin |
| `Landlord.tscn__9.gd` | ~446 | — | Boss fight: HP bar, damage, fine print, entrance/death animations |

## Menus/Screens (8 files)

| File | Lines | Summary |
|------|-------|---------|
| `Options.tscn__1.gd` | 3000 | [✓](Options.tscn__1.gd.index.md) | Full options menu: settings, mods, credits, hotkeys, colors |
| `Main.tscn__6.gd` | ~1173 | Title screen: main menu, floor select, stats display, promo, mod info |
| `Main.tscn__5.gd` | ~41 | Menu proxy: loads Buttons Menu, delegates spin button |
| `Main.tscn__7.gd` | ~5 | Trivial ColorRect visibility trigger |
| `Main.tscn__8.gd` | ~20 | Error display overlay: timed messages with fade |
| `Buttons Menu.tscn__1.gd` | ~181 | In-game buttons: spin, options, inventory, removal, page nav |
| `Items.tscn__1.gd` | ~392 | Item container: add, paginate, save/load, conditional effects |
| `Stats.tscn__1.gd` | ~250 | Stats & achievements: per-floor tracking, Steam sync, unit conversion |
| `Options.tscn__2.gd` | ~6 | Spacer node (saves rect_size.y) |
| `Options.tscn__3.gd` | ~6 | Spacer node (saves rect_size.y) — identical to #2 |

## Inheritance Chain — Text Rendering (3 files)

| File | Lines | Summary |
|------|-------|---------|
| `Pico Label.tscn__1.gd` | ~1340 | Core text engine: CJK line-breaking, icons, colors, escape tags, RTL |
| `Outline Label.tscn__10.gd` | ~1561 | 3×3 border/outline text grid, icon sizing, scaling — base of all text |
| `Pico Text.tscn__1.gd` | ~139 | Clickable text label with hyperlinks and hover highlight |

## Inheritance Chain — Icons (2 files)

| File | Lines | Summary |
|------|-------|---------|
| `Outline Icon.tscn__1.gd` | ~30 | Base Sprite: texture loading from Main's replacement database |
| `Icon.tscn__1.gd` | ~27 | Simple sprite texture setter with mod support |

## UI Widgets (5 files)

| File | Lines | Summary |
|------|-------|---------|
| `TT Button.tscn__1.gd` | ~1000 | Universal button: keyboard/mouse/controller, hotkeys, toggle, TTS |
| `Card.tscn__1.gd` | ~586 | Card display: icon, title, rarity, value, description, hover |
| `Card.tscn__2.gd` | ~3 | Minimal ColorRect border element for Card |
| `Hover Icon.tscn__1.gd` | ~750 | Interactive icon: tooltips, removal, press, eldritch transform |
| `Popup Scroll Bar.tscn__1.gd` | ~200 | Scroll bar: drag, wheel, keyboard, auto-scroll to selected |
| `Hotkey Scroll Bar.tscn__1.gd` | ~211 | Options menu scroll bar: drag, wheel, keyboard |
| `Option Slider.tscn__1.gd` | ~100 | Draggable slider control for volume/color settings |

## Display/Sum Widgets (5 files)

| File | Lines | Summary |
|------|-------|---------|
| `Coins.tscn__1.gd` | ~84 | Coin counter display with animated queued_increase |
| `Coin Sum.tscn__10.gd` | ~124 | Animated coin sum → flushes to Coins |
| `Extra Sum.tscn__11.gd` | ~164 | Token sum (reroll/removal/essence) → updates removal button |
| `HP Sum.tscn__11.gd` | ~129 | Boss HP damage display → flushes to Landlord.take_damage() |
| `Effect Text.tscn__1.gd` | ~143 | Floating value text with slot line connections |

## Visual/Audio (3 files)

| File | Lines | Summary |
|------|-------|---------|
| `Music Player.tscn__1.gd` | ~50 | Music playback: track selection, cross-fading, WAV loading |
| `Reel Border.tscn__1.gd` | ~18 | Theme-colored reel border and container line |
| `Slot Line.tscn__1.gd` | ~22 | Decorative Line2D connecting related symbols |

---

## How to Use This Index

1. **Find the area** you need in the table above
2. **Read the `.summary.md`** first — it covers purpose, symbols, methods, and control flow
3. **If you need exact line ranges**, check the `.index.md` (for files >2000 lines)
4. **Only then read** the `.gd` source file, using the line range from the index

## Key Dependency Links

- `Main.tscn__1` → everything (root controller)
- `Main.tscn__4` → Reel.tscn, Slot Icon.tscn, Item.tscn, Landlord.tscn
- `Pop-up.tscn__1` → Card.tscn, TT Button.tscn, Items.tscn, Main.tscn__4
- `Slot Icon.tscn__1` → Outline Icon.tscn, Outline Label.tscn, Effect Text.tscn
- `Item.tscn__1` → Hover Icon.tscn, Items.tscn, Slot Icon.tscn
- `Outline Label.tscn__10` → Pico Label.tscn, Pico Text.tscn
- `Options.tscn__1` → TT Button.tscn, Option Slider.tscn, Hotkey Scroll Bar.tscn
