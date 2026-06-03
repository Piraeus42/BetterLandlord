# Outline Icon.tscn__1.gd
**Scene:** Outline Icon.tscn (base icon for slot symbols)
**Role:** Base Sprite class for all icon representations. Manages orphan cleanup and texture loading from Main's replacement texture database.

## Variables
- `type` — Icon type string; defaults to `"empty"` in `_ready()`

## Methods
- **`_free_if_orphaned()`** — Frees if removed from tree
- **`_init()`** — Connects to `Utils.freeing_orphans`
- **`_ready()`** — If type is null, sets to `"empty"`. For non-popup containers, loads texture via `Main.get_replacement_texture(type)`

## Control Flow
Texture resolution: check parent path → call `$/root/Main.get_replacement_texture(type)` → set child sprite texture. Extended by `Slot Icon.tscn` (full symbol logic) and `Icon.tscn` (simple texture setter).
