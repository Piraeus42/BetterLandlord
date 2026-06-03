# Card.tscn__1.gd
**Scene:** Card.tscn (~586 lines)
**Role:** Card display widget — shows a detailed card with icon, title, rarity color, value, description text, hover effects, keyboard/controller navigation, and TTS support. Used for tooltip popups (symbol info, item info, email details).

## Symbols
| Name | Kind | Description |
|------|------|-------------|
| `background`, `border` | var | Card frame nodes |
| `active`, `hovering`, `selectable` | var | Interaction state |
| `selector_alignment = "card"` | var | How the selector cursor aligns |
| `data` | var | Card content data dictionary |

## Methods
- **`_ready()`** — Sets up card background/border references
- **`set_icon_size()`** — Scales the icon sprite to fit card
- **`set_card_size()`** — Calculates and sets card dimensions based on content (title, value text, description)
- **`update()`** — Per-frame: handles hover state, delayed appearance, scroll position
- **`hover()`** — Mouse enter: sets hovering, plays hover SFX
- **`unhover()`** — Mouse leave: clears hovering
- **`update_hitboxes()`** — Updates click/hit collision areas
- **`tts()`** — Screen reader: reads card contents aloud

## Control Flow
Used as a transient popup — instantiated, populated with data, positioned near the relevant UI element, then freed when dismissed.
