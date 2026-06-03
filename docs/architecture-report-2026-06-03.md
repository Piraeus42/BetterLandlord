# BetterHistoryMod Architecture Report — 2026-06-03

## 1. Overall Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Luck be a Landlord (Godot 3.4.4)                          │
│                                                             │
│  Title (Main.tscn::6)                                       │
│  ├── History Button (TTButton) → _bh_toggle_ui()            │
│  │   └── writes user://betterHistory/ui_requested           │
│  ├── Custom Seed Button (plain Button) → _bh_open_custom_seed()│
│  │   └── writes user://betterHistory/flag_seed              │
│  └── HistoryButtonPatch / TitleDrawSeedPatch /              │
│      FloorMenuSeedPatch / TitleSeedSourceMod                │
│                                                             │
│  Main (Main.tscn::1)                                        │
│  └── _bh_apply_seed() → title._bh_get_seed_config()         │
│      └── reads user://betterHistory/seed_config.json        │
└──────────────────────┬──────────────────────────────────────┘
                       │ Named Pipe
                       │ "Piraeus.BetterHistoryMod.Pipe"
┌──────────────────────▼──────────────────────────────────────┐
│  GamePipeServer (C#, in-game)                               │
│  ├── ServerLoop: request-response pipe handler              │
│  │   ├── get_run_list → BuildRunListJson()                  │
│  │   ├── get_run → BuildRunDataJson()                       │
│  │   ├── set_seed → write seed_config.json                  │
│  │   └── close                                              │
│  └── FlagPollLoop (500ms): watches for flag files           │
│      ├── ui_requested → LaunchUiProcess(seedMode: false)    │
│      └── flag_seed → LaunchUiProcess(seedMode: true)        │
│                                                             │
│  userDataDir: %APPDATA%/Godot/app_userdata/Luck be a Landlord│
│  HistoryDir: userDataDir/betterHistory/                     │
│  Files:                                                     │
│  ├── ui_requested (flag, deleted by GamePipeServer)          │
│  ├── flag_seed (flag, deleted by WPF or IsSeedMode path)    │
│  ├── seed_config.json (written by set_seed handler)         │
│  └── runs/*.json (history data written by GDScript)         │
└──────────────────────┬──────────────────────────────────────┘
                       │ launch Piraeus.BetterHistory.UI.exe
                       │ --data-dir "..." [--seed]
┌──────────────────────▼──────────────────────────────────────┐
│  WPF UI (Piraeus.BetterHistory.UI.exe)                      │
│                                                             │
│  App.OnStartup                                              │
│  ├── base.OnStartup(e) → creates MainWindow (from StartupUri)│
│  ├── Parse --data-dir → App.DataDir                         │
│  └── Parse --seed → App.IsSeedMode                          │
│                                                             │
│  MainWindow (HistoryViewModel)                              │
│  ├── UiPipeClient → pipe I/O                                │
│  ├── Seed polling (500ms): watches flag_seed                │
│  │   └── detected → ShowSeedDialog() (modal)               │
│  └── IsSeedMode → Hide() → ShowSeedDialog() → Show()        │
│                                                             │
│  SeedDialog (modal dialog)                                  │
│  └── Confirm → SendSetSeed(input) → pipe → game             │
└─────────────────────────────────────────────────────────────┘
```

## 2. Control Flow: History Button

```
User clicks "History" (floor menu)
  → Title._bh_toggle_ui()
    → File.write("user://betterHistory/ui_requested", "")
  
  → GamePipeServer.FlagPollLoop (next 500ms tick)
    → detects ui_requested
    → deletes ui_requested
    → LaunchUiProcess(seedMode: false)
      → if WPF already running: return
      → else: Process.Start("Piraeus.BetterHistory.UI.exe",
               "--data-dir \"C:\\Users\\...\\Luck be a Landlord\"")
      
  → WPF App.OnStartup
    → base.OnStartup(e) → MainWindow created & shown
    → IsSeedMode = false
    → DataDir = "C:\\Users\\...\\Luck be a Landlord"
    
  → MainWindow.OnWindowLoaded
    → pipeClient.Start() → connect pipe → get_run_list
    → IsSeedMode == false → skip Hide/ShowSeedDialog
    → StartSeedPolling() → watch flag_seed
```

## 3. Control Flow: Custom Seed Button (WPF not running)

```
User clicks "Custom Seed" (floor menu)
  → Title._bh_open_custom_seed()
    → File.write("user://betterHistory/flag_seed", "")
  
  → GamePipeServer.FlagPollLoop (next 500ms tick)
    → detects flag_seed (does NOT delete)
    → LaunchUiProcess(seedMode: true)
      → Process.Start("Piraeus.BetterHistory.UI.exe",
           "--data-dir \"...\" --seed")
      
  → WPF App.OnStartup
    → base.OnStartup(e) → MainWindow created & shown
    → IsSeedMode = true
    → DataDir = "..."
    
  → MainWindow.OnWindowLoaded
    → pipeClient.Start()
    → IsSeedMode == true:
      → Hide()                    ← MainWindow hidden
      → delete flag_seed          ← so poller doesn't re-fire
      → ShowSeedDialog()          ← modal dialog
      → Show()                    ← reveal after close
    → StartSeedPolling()
    
  → User types seed, clicks Confirm
    → SeedDialog.Confirm_Click
      → pipeClient.SendSetSeed(input) → pipe → game
      → GamePipeServer writes seed_config.json
    → DialogResult = true → Close()
    
  → _bh_get_seed_config() (next new_game)
    → reads seed_config.json → returns {type: 'custom', input: '...'}
    → RNG initialized with custom seed
```

## 4. Control Flow: Custom Seed Button (WPF already running)

```
User clicks "Custom Seed" (WPF showing History)
  → Title._bh_open_custom_seed()
    → writes flag_seed
  
  → GamePipeServer.FlagPollLoop
    → detects flag_seed → LaunchUiProcess(seedMode: true)
      → WPF already running → return (no-op)
  
  → MainWindow seed poller (500ms)
    → detects flag_seed → deletes it → ShowSeedDialog()
      → marshals to UI thread via Dispatcher.Invoke
      → _seedDialogOpen guard
      → SeedDialog shows as modal over History window
  
  → Confirm → SendSetSeed → pipe → seed_config.json written
```

## 5. 🐛 Known Bug: Startup Race Condition

```
Problem:
  App.OnStartup() {
    base.OnStartup(e);  // ← creates MainWindow synchronously!
                        // Loaded event fires HERE
                        // IsSeedMode is still false, DataDir is still null
                        // So: Hide/ShowSeedDialog skipped,
                        //     StartSeedPolling skipped

    // Below runs AFTER MainWindow is already visible:
    DataDir = args[...];
    IsSeedMode = true;  // ← TOO LATE
  }
```

**Effect**: When launched with `--seed`, WPF defaults to showing History window, ignores seed mode entirely.

**Fix needed**: Parse CLI args BEFORE `base.OnStartup(e)`, or remove `StartupUri` from XAML and create MainWindow manually after parsing.

## 6. Pipe Protocol

```
Request (UI → Game):
  {"type": "get_run_list"}
  {"type": "get_run", "run_id": "2026-06-03_001"}
  {"type": "set_seed", "input": "ABC123"}
  {"type": "close"}

Response (Game → UI):
  {"type": "run_list", "runs": [...]}
  {"type": "run_data", "record": {...}}
  {"type": "error", "message": "..."}
  {"type": "status", "status": "ok"}
```

## 7. File Map

| File | Purpose |
|------|---------|
| `user://betterHistory/ui_requested` | History button flag (game deletes) |
| `user://betterHistory/flag_seed` | Seed button flag (WPF deletes) |
| `user://betterHistory/seed_config.json` | `{type, input, updated_at}` written by GamePipeServer |
| `user://betterHistory/runs/*.json` | Per-run history data |
| `user://betterHistory/manifest.json` | Lightweight run list cache |
| `user://betterHistory/debug.log` | GDScript debug append-log |

## 8. Key Design Decisions

1. **Seed input in WPF, not Godot** — avoids Godot 3.4.4 input bugs (backspace→title exit, IME→Chinese chars, placeholder not rendering, no click-to-exit)
2. **Plain Button (not TTButton)** — avoids BaseButton.shortcut conflict, simpler signal handling
3. **Two-mode WPF launch** — `--seed` flag separates History vs Seed dialog startup paths
4. **Polling + flags** — file-based flag system bridges Godot ↔ C# IPC without needing push messages
5. **seed_config.json as single source of truth** — `_bh_get_seed_config()` always reads from disk, no UI state dependency
