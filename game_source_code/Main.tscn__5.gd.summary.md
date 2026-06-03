# Main.tscn__5.gd
**Scene:** Main.tscn
**Role:** Thin menu proxy — loads `Buttons Menu.tscn`, monitors the spin button, and delegates menu switching.

## Variables
- `buttons_menu` — instance of Buttons Menu scene
- `current_menu = "buttons"` — tracks active menu

## Methods
- **`_ready()`** — Instantiates `Buttons Menu.tscn`, adds as child, calls `load_menu("buttons")`
- **`update()`** — If the spin button is held down and active, calls `$/root/Main/Reels.spin()`
- **`load_menu(menu_type)`** — Hides all menus, shows only the matched one (`"buttons"` only live; stats/shop/items are commented out)
