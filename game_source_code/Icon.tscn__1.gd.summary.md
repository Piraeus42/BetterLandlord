# Icon.tscn__1.gd
**Scene:** Icon.tscn
**Role:** Simple Sprite texture setter — loads replacement textures from Main's icon database based on `type`.

## Symbols
- `type` — Icon type string (determines which texture to load)

## Methods
- **`_free_if_orphaned()`** — Frees node if removed from scene tree
- **`_init()`** — Connects to Utils signal for orphan cleanup
- **`set_type(_type)`** — Sets type and loads texture: `"empty"` → empty_border.png, `"hover_coin"` → coin texture (with mod support), anything else → `Main.get_replacement_texture(type)`
