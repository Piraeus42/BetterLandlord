# Music Player.tscn__1.gd
**Scene:** Music Player.tscn
**Role:** Music playback manager — handles track selection, cross-fading between tracks, and WAV loading.

## Variables
- `current_music_node` — Reference to currently playing AudioStreamPlayer
- `tween_in`, `tween_out` — Tween nodes for fade transitions
- Various track/path tracking variables

## Methods
- **`play_rand_music()`** — Selects and plays a random music track
- **`fade_in()`** — Fades music volume from -80dB to goal volume via tween
- **`fully_fade_out()`** — Immediately kills all tweens and sets volume to -80dB
- **`load_wav(path)`** — Loads a WAV file into an AudioStreamPlayer

## Control Flow
Called from Main._ready() and various game state transitions (title → game, boss death, etc.). Uses Godot's Tween system for smooth cross-fading.
