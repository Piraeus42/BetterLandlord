# Buttons Menu.tscn__1.gd
**Scene:** Buttons Menu.tscn (~181 lines)
**Role:** Creates and manages the main in-game UI buttons: Spin, Options, Inventory/Deck, Item page navigation (left/right), and Removal Token button.

## Variables
- `spin_button`, `options_button`, `deck_button`, `left_button`, `right_button`, `removal_button` — The button instances

## Methods
- **`_ready()`** — Sets alignment tags, calls `add_item_buttons()` to create all buttons
- **`add_item_buttons()`** — Factory method: instantiates TT Button instances for each UI button (spin, options, deck/inventory, left/right scroll, removal), configures their targets/calls/icons/positions, wires them to the relevant game systems

## Control Flow
Buttons are created once at ready. Reels.spin() is called when spin_button is pressed. Other buttons toggle visibility of options/inventory/removal. Left/right scroll the item inventory pages.
