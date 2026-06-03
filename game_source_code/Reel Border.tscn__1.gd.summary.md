# Reel Border.tscn__1.gd
**Scene:** Reel Border.tscn
**Role:** Purely visual — applies the theme's `reel_border` color to the Border and Container/Line children. Centered alignment.

## Methods
- **`_ready()`** — Reads `colors3["reel_border"]` from Options, applies to `$Border` and `$Container/Line` colors

## Control Flow
Single `_ready()` entry, no update loop. 18 lines total.
