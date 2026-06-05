# Better Landlord

<div align="center">

**English** · [简体中文](README_zh.md)

</div>

*Luck be a Landlord* companion mod. Runs on the [SlotWeave](https://github.com/Piraeus42/SlotWeave) framework.

## Features

- **Structured run history** — Every spin, symbol choice, item pick, destruction, and rent cycle saved as JSON
- **Timeline replay viewer** (WPF) — Spin-by-spin walkthrough of any past run
- **DPT analytics** — Total Value, DPT (actual), DPT (effective) per symbol with ranking
- **Seed system** — Random (OS entropy) or custom seed string for reproducible runs
- **Continue support** — RNG state preserved across save/load, cold-boot, and force-close
- **Win-rate tracker** — 50/100/200 game sliding window + overall (seeded runs excluded)
- **End-state handling** — Guillotine, mid-run quit, force-close, and post-victory continue all handled correctly

---

## Installation

1. Install **SlotWeave** (`winmm.dll` in game root, `SlotWeave/` directory in place)
2. Extract the mod into `SlotWeave/mods/Piraeus.BetterLandlord/`

```
Luck be a Landlord/
├── Luck be a Landlord.exe
├── winmm.dll
└── SlotWeave/
    ├── core/
    └── mods/
        └── Piraeus.BetterLandlord/
            ├── manifest.json
            ├── Piraeus.BetterLandlord.dll
            ├── Piraeus.BetterLandlord.UI.exe
            ├── Piraeus.BetterLandlord.UI.dll
            └── Piraeus.BetterLandlord.UI.runtimeconfig.json
```

---

## Usage

### Timeline Viewer
The WPF viewer launches automatically (hidden window). Click the **History** button on the title screen.

- Left panel — run list (result, coins, top-3 symbol icons)
- Right panel — spin-by-spin timeline + DPT ranking
- Bottom bar — win-rate statistics

### Custom Seeds
Enter a seed string on the title screen input field. The lock icon turns blue when a custom seed is active.

---

## Build

```bash
dotnet build Piraeus.BetterLandlord.sln -c Release
```

Output goes to `SlotWeave/mods/Piraeus.BetterLandlord/`.

Debug: `run-lbl-debug.bat` (console + script dumps + no cache).

---

## Architecture

```
Piraeus.BetterLandlord.dll (C# Mod)
├── ISourceMod × 15    — GDScript source injection (RNG routing, event capture, seed UI)
├── [Patch] × 16       — runtime Prefix/Postfix hooks (spin, write_log, title, save...)
├── GameStateBus       — per-frame memory reads (seed change detection)
├── PipeServer         — Named Pipe IPC → WPF viewer
└── HistoryStore        — JSON persistence + manifest management

Piraeus.BetterLandlord.UI.exe (WPF Viewer)
├── UiPipeClient        — Pipe client
├── HistoryViewModel    — data binding + win-rate stats
└── IconConverter       — embedded resource icons (854 PNGs compiled into DLL)
```

### RNG Architecture
```
landlord_seed (FNV-1a hash of seed string)
  ├── derive('sym_rarity') → PCGRng → symbol rarity selection
  ├── derive('sym_common') → PCGRng → common symbol pick
  ├── ... (20 persistent streams)
  └── per-spin: derive('spin_' + N) → reel / effect / scratch RNG
```

---

## FAQ

| Question | Answer |
|----------|--------|
| Where is history stored? | `%AppData%/Godot/app_userdata/Luck be a Landlord/betterHistory/runs/` |
| Seeded runs affect achievements? | **No.** Blocked at engine level in `add_stat`, `add_to_games_played`, `unlock_achievement`, and `add_queued_achievement` |
| Viewer doesn't appear? | Click the History button in-game. Check `SlotWeave.log` if still missing |
| Data after uninstall? | JSON files are not auto-deleted. Remove `betterHistory/` manually if needed |

---

> **Compliance & Fairness**
>
> This mod does **not** include, modify, or redistribute any original game source code or art assets.
> Icons displayed in the timeline viewer are embedded as program resources — the original game files
> are never read, extracted, or repackaged.
>
> **Custom-seeded runs are automatically excluded from native stats and Steam achievements.**
> This is enforced at the engine level — seeded runs do not increment your play count, win/loss
> record, or unlock achievements. The mod's own win-rate tracker also filters them out.

[中文文档](README_zh.md)
