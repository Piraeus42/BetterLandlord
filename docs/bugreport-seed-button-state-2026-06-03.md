# Bug Report: Seed Button State Never Updates to "ON"

**Date**: 2026-06-03

## Symptom

The "Seed: OFF" / "Seed: ON" button on the floor menu always shows "Seed: OFF", even after the user successfully sets a custom seed via the WPF dialog.

The rest of the flow works correctly:
- Button click → GameStateBus signal fires ✓
- WPF dialog opens ✓
- User enters seed, confirms → `set_seed` pipe → `seed_config.json` written ✓
- GamePipeServer log confirms: `Seed saved: 123` ✓

## Root Cause Analysis

The button text is updated in `_bh_draw_seed_ui()` which calls `_bh_update_seed_button_text()` which calls `_bh_read_seed_config()` to read `user://betterHistory/seed_config.json`.

This flow is triggered from `TitleDrawSeedPatch.Postfix` on the Title node's `draw()` method. **If Title's `draw()` is not called on every frame while the floor menu is active**, the button text never refreshes after `seed_config.json` is written.

The button remains interactive because Godot input processing is separate from `draw()`.

## Suspected Cause (2 hypotheses)

### Hypothesis A: `draw()` not called on floor menu

Godot 3.4.4 Title node's `draw()` may only fire during screen transitions, not continuously while the floor menu overlay is active. The floor menu (`floor_menu`) may be a different scene/node that takes over the render loop.

Evidence for:
- Button created and positioned correctly on entry (draw() fires on transition)
- Button clickable (input separate from draw)
- Button text never changes after entry (draw() not re-called)

Evidence against:
- `_bh_update_seed_visibility()` also runs from the same draw Postfix — if draw() stops firing, the reset-on-entry logic still works because it fires on the transition frame
- `HistoryButtonPatch` also patches Title's `draw()` — History button works, suggesting draw() does fire

### Hypothesis B: `_bh_read_seed_config()` always returns `{active: false}`

The file `user://betterHistory/seed_config.json` may exist on disk but GDScript's `File.file_exists()` returns false due to path resolution, encoding, or filesystem caching.

Evidence for:
- GamePipeServer writes to absolute path (via C# `File.WriteAllText`)
- GDScript reads via `user://` virtual path
- These should resolve to the same location but Godot 3.4.4 may have quirks

## Suggested Fix

Add minimal diagnostic: write the result of `_bh_read_seed_config()` to the button's tooltip text, which is visible without needing draw() updates:

```gdscript
func _bh_update_seed_button_text():
    if not _bh_seed_btn_created:
        return
    var cfg = _bh_read_seed_config()
    _bh_custom_seed_btn.hint_tooltip = str(cfg.active) + ' | ' + cfg.input
    if cfg.active:
        _bh_custom_seed_btn.text = 'Seed: ON'
        ...
```

This would show whether `_bh_read_seed_config` is even being called and what it returns. If the tooltip never appears, `draw()` isn't firing. If the tooltip shows `false |`, the file isn't being read.

## Alternative Fix (if draw() isn't firing)

Move the button text update to a `_process(delta)` override on Title, or use a Timer, or update from `_bh_update_seed_visibility()` which is patched into `floor_menu` via `FloorMenuSeedPatch`.
