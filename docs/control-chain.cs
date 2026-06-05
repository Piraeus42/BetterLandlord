// ============================================================
// TitleSeedSourceMod.cs
// ============================================================
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

public class TitleSeedSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::6";

    public string Modify(string path, string source)
    {
        return source + "\n" + GdscriptUtil.Tabify(SeedUiGdscript);
    }

    private const string SeedUiGdscript = @"

# ---- BetterHistoryMod Seed UI (stateful button 鈫?WPF dialog) ----

var _bh_custom_seed_btn = null
var _bh_seed_btn_created = false
var _bh_seed_request = 0
var _bh_seed_timer = null

func _bh_read_seed_config():
    var file = File.new()
    var path = ""user://betterHistory/seed_config.json""
    if file.file_exists(path):
        if file.open(path, File.READ) == OK:
            var text = file.get_as_text()
            file.close()
            var parsed = JSON.parse(text)
            if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
                var cfg = parsed.result
                if cfg.get('type', '') == 'custom':
                    var input = str(cfg.get('input', ''))
                    if input.length() > 0:
                        return {'active': true, 'input': input}
    return {'active': false, 'input': ''}

func _bh_update_seed_button_text():
    if not _bh_seed_btn_created:
        return
    var cfg = _bh_read_seed_config()
    if cfg.active:
        _bh_custom_seed_btn.text = 'Seed: ON'
        _bh_custom_seed_btn.add_color_override('font_color', Color(0.4, 1.0, 0.5, 1))
    else:
        _bh_custom_seed_btn.text = 'Seed: OFF'
        _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))

# Timer callback 鈥?polls seed_config.json independently of draw()
func _bh_on_seed_timer():
    if not _bh_seed_btn_created:
        return
    var cfg = _bh_read_seed_config()
    var want = 'Seed: ON' if cfg.active else 'Seed: OFF'
    if _bh_custom_seed_btn != null and _bh_custom_seed_btn.text != want:
        _bh_custom_seed_btn.text = want
        if cfg.active:
            _bh_custom_seed_btn.add_color_override('font_color', Color(0.4, 1.0, 0.5, 1))
        else:
            _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))
        _bh_custom_seed_btn.update()

func _bh_draw_seed_ui():
    if not _bh_seed_btn_created:
        if _bh_custom_seed_btn != null:
            _bh_custom_seed_btn.queue_free()
        if _bh_seed_timer != null:
            _bh_seed_timer.queue_free()

        _bh_custom_seed_btn = Button.new()
        _bh_custom_seed_btn.name = 'BHCustomSeed'
        _bh_custom_seed_btn.text = 'Seed: OFF'
        _bh_custom_seed_btn.flat = false
        var _sb = StyleBoxFlat.new()
        _sb.bg_color = Color(0.15, 0.15, 0.25, 0.95)
        _sb.border_width_left = 1
        _sb.border_width_right = 1
        _sb.border_width_top = 1
        _sb.border_width_bottom = 1
        _sb.border_color = Color(0.3, 0.3, 0.5, 1)
        _sb.corner_radius_top_left = 4
        _sb.corner_radius_top_right = 4
        _sb.corner_radius_bottom_left = 4
        _sb.corner_radius_bottom_right = 4
        _bh_custom_seed_btn.add_stylebox_override('normal', _sb)
        _bh_custom_seed_btn.add_stylebox_override('hover', _sb)
        _bh_custom_seed_btn.add_color_override('font_color', Color(0.8, 0.8, 0.9, 1))
        _bh_custom_seed_btn.connect('pressed', self, '_bh_open_custom_seed')
        add_child(_bh_custom_seed_btn)

        # Timer to poll seed_config.json periodically 鈥?draw() is not called
        # continuously on the floor menu, so we need an independent refresh source.
        _bh_seed_timer = Timer.new()
        _bh_seed_timer.name = 'BHSeedTimer'
        _bh_seed_timer.wait_time = 0.5
        _bh_seed_timer.one_shot = false
        _bh_seed_timer.connect('timeout', self, '_bh_on_seed_timer')
        add_child(_bh_seed_timer)
        _bh_seed_timer.start()

        _bh_seed_btn_created = true

    # Update button text from seed_config.json on every frame
    _bh_update_seed_button_text()

func _bh_open_custom_seed():
    # Signal GameStateBus reader with a timestamp (always unique per click)
    _bh_seed_request = OS.get_ticks_msec()

func _bh_position_seed_ui():
    if not _bh_seed_btn_created:
        return
    var res_x = $'/root/Main/Options Sprite/Options'.resolution_x
    var res_y = $'/root/Main/Options Sprite/Options'.resolution_y
    var base_x = res_x / 2 + 80
    var base_y = res_y - 70
    _bh_custom_seed_btn.rect_position = Vector2(base_x, base_y)
    _bh_custom_seed_btn.rect_size = Vector2(160, 30)
    _bh_custom_seed_btn.rect_scale = Vector2(1.1, 1.1)

var _bh_prev_on_floor = false

func _bh_update_seed_visibility():
    if not _bh_seed_btn_created:
        return
    var on_floor = $""/root/Main"".current_menu_path == ""floor_menu""
    _bh_custom_seed_btn.visible = on_floor

    # Reset seed state every time we enter the floor menu
    if on_floor and not _bh_prev_on_floor:
        var file = File.new()
        var path = ""user://betterHistory/seed_config.json""
        _bh_update_seed_button_text()

    _bh_prev_on_floor = on_floor

# Called by _bh_apply_seed() in RngInfrastructureSourceMod 鈥?reads seed_config.json
# written by GamePipeServer when WPF dialog confirms.
func _bh_get_seed_config():
    var cfg = _bh_read_seed_config()
    if cfg.active:
        var input = cfg.input.replace('O', '0').replace('I', '1')
        return {'type': 'custom', 'input': input}
    return {'type': 'random', 'input': ''}
";
}


// ============================================================
// TitleDrawSeedPatch.cs
// ============================================================
using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

[Patch("res://Main.tscn::6", "draw")]
class TitleDrawSeedPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main/Title".has_method("_bh_draw_seed_ui"):
            $"/root/Main/Title"._bh_draw_seed_ui()
        if $"/root/Main/Title".has_method("_bh_position_seed_ui"):
            $"/root/Main/Title"._bh_position_seed_ui()
        if $"/root/Main/Title".has_method("_bh_update_seed_visibility"):
            $"/root/Main/Title"._bh_update_seed_visibility()
        """);
}


// ============================================================
// FloorMenuSeedPatch.cs
// ============================================================
using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

[Patch("res://Main.tscn::6", "floor_menu")]
class FloorMenuSeedPatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main/Title".has_method("_bh_update_seed_visibility"):
            $"/root/Main/Title"._bh_update_seed_visibility()
        """);
}


// ============================================================
// RngInfrastructureSourceMod.cs
// ============================================================
using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Injects PCGRng class, FNV-1a/djb2 hash, custom_shuffle,
/// and init_all_rngs() into Main.tscn::1.
/// </summary>
public class RngInfrastructureSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Main.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("class PCGRng:")) return source;
        return source + "\n" + GdscriptUtil.Tabify(RngInfrastructureGdscript);
    }

    private const string RngInfrastructureGdscript = @"

# ============================================================
# PCGRng 鈥?Deterministic RNG (PCG-family, 64-bit state)
# Replaces Godot's global randomize()/rand_range() entirely.
# ============================================================

const PCG_DEFAULT_INC: int = 1442695040888963407
const PCG_MULT: int = 6364136223846793005
const MASK_63: int = 0x7FFFFFFFFFFFFFFF  # max positive signed 64-bit
const MASK_31: int = 0x7FFFFFFF

class PCGRng:
    var state: int  # kept in [0, 2^63) 鈥?always non-negative
    var inc: int    # stream id

    func _init(seed_val: int):
        state = seed_val
        inc = (PCG_DEFAULT_INC << 1) | 1
        _step()
        state = (state + PCG_MULT) & MASK_63
        _step()
        _step()

    func _step():
        var old: int = state
        state = ((old * PCG_MULT) + inc) & MASK_63
        return old

    # Returns float in [0, 1)
    func randf() -> float:
        var old: int = _step()
        var x: int = (old >> 18) ^ old
        x = x >> 27
        var rot: int = old >> 59        # PCG32 standard: top 6 bits for rotation
        var result: int = ((x >> rot) | (x << ((-rot) & 31))) & MASK_31
        return float(result) / 2147483648.0

    # Returns int in [0, max_val)
    func randi_max(max_val: int) -> int:
        return int(floor(self.randf() * float(max_val)))

    # Returns float in [min_val, max_val)
    func rand_range(min_val: float, max_val: float) -> float:
        return min_val + self.randf() * (max_val - min_val)

    # Pick a random element from an array
    func pick(arr: Array):
        if arr.size() == 0:
            return null
        return arr[self.randi_max(arr.size())]

    # Fisher-Yates shuffle using THIS RNG (NOT Godot's global random)
    func custom_shuffle(arr: Array):
        var n: int = arr.size()
        for i in range(n - 1, 0, -1):
            var j: int = int(floor(self.randf() * float(i + 1)))
            var tmp = arr[i]
            arr[i] = arr[j]
            arr[j] = tmp

    # Chance test: randf() * 100 < percent
    func chance(percent: float) -> bool:
        return self.randf() * 100.0 < percent

# ============================================================
# Hash functions
# ============================================================

# FNV-1a: any string 鈫?31-bit positive int (deterministic, cross-platform)
func _bh_fnv1a(text: String) -> int:
    var h: int = 2166136261
    for c in text:
        h = (h ^ ord(c)) & MASK_63
        h = (h * 16777619) & MASK_63
    return h & MASK_31

# djb2: int + string 鈫?31-bit positive int (seed derivation)
func _bh_derive_seed(base: int, name: String) -> int:
    var h: int = base & MASK_63
    for c in name:
        h = (((h << 5) + h) ^ ord(c)) & MASK_63
    return h & MASK_31

# Generate random 10-char [0-9A-Z] seed string
const _BH_SEED_CHARS = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'

func _bh_generate_random_seed() -> String:
    # Use OS entropy (not Godot global randi 鈥?seed() captures it to landlord_seed,
    # making randi() deterministic within a session)
    var _entropy = OS.get_unix_time() + OS.get_ticks_msec()
    var _h = _bh_fnv1a(str(_entropy))
    var result: String = ''
    for _i in range(10):
        _h = ((_h * 1103515245) + 12345) & 0x7FFFFFFF
        result += _BH_SEED_CHARS[_h % 34]
    return result

# ============================================================
# RNG instance registry
# ============================================================

var _bh_rng_seed_type: String = ''      # 'random' | 'custom'
var _bh_rng_seed_input: String = ''     # 10-char or user input
var _bh_rng_landlord_seed: int = 0      # hash result

# 17 persistent (cross-spin) RNG instances
var _bh_rng_spin: PCGRng = null
var _bh_rng_rarity: PCGRng = null
var _bh_rng_sym_common: PCGRng = null
var _bh_rng_sym_uncommon: PCGRng = null
var _bh_rng_sym_rare: PCGRng = null
var _bh_rng_sym_vrare: PCGRng = null
var _bh_rng_itm_common: PCGRng = null
var _bh_rng_itm_uncommon: PCGRng = null
var _bh_rng_itm_rare: PCGRng = null
var _bh_rng_itm_vrare: PCGRng = null
var _bh_rng_ess_common: PCGRng = null
var _bh_rng_ess_uncommon: PCGRng = null
var _bh_rng_ess_rare: PCGRng = null
var _bh_rng_ess_vrare: PCGRng = null
var _bh_rng_fineprint: PCGRng = null
var _bh_rng_cosmetic: PCGRng = null

# Per-spin temporary instances (recreated each spin)
var _bh_rng_reel: PCGRng = null
var _bh_rng_effect: PCGRng = null
var _bh_rng_scratch: PCGRng = null  # cosmetic/frame-driven discard stream

# ============================================================
# Initialize all RNG from seed
# ============================================================

func _bh_init_rng(seed_type: String, seed_input: String):
    _bh_rng_seed_type = seed_type
    _bh_rng_seed_input = seed_input
    seed_input = seed_input.replace('O', '0').replace('I', '1')

    if seed_type == 'random' or seed_input == '':
        _bh_rng_seed_input = _bh_generate_random_seed()
        _bh_rng_seed_type = 'random'
    else:
        _bh_rng_seed_input = seed_input
        _bh_rng_seed_type = 'custom'

    var landlord_seed: int = _bh_fnv1a(_bh_rng_seed_input)
    _bh_rng_landlord_seed = landlord_seed
    var s: int = landlord_seed

    # === Phase 1: Create ALL 19 instances to local variables ===
    var _new_spin           = PCGRng.new(_bh_derive_seed(s, 'spin'))
    var _new_rarity         = PCGRng.new(_bh_derive_seed(s, 'rarity'))
    var _new_sym_common     = PCGRng.new(_bh_derive_seed(s, 'sym_common'))
    var _new_sym_uncommon   = PCGRng.new(_bh_derive_seed(s, 'sym_uncommon'))
    var _new_sym_rare       = PCGRng.new(_bh_derive_seed(s, 'sym_rare'))
    var _new_sym_vrare      = PCGRng.new(_bh_derive_seed(s, 'sym_vrare'))
    var _new_itm_common     = PCGRng.new(_bh_derive_seed(s, 'itm_common'))
    var _new_itm_uncommon   = PCGRng.new(_bh_derive_seed(s, 'itm_uncommon'))
    var _new_itm_rare       = PCGRng.new(_bh_derive_seed(s, 'itm_rare'))
    var _new_itm_vrare      = PCGRng.new(_bh_derive_seed(s, 'itm_vrare'))
    var _new_ess_common     = PCGRng.new(_bh_derive_seed(s, 'ess_common'))
    var _new_ess_uncommon   = PCGRng.new(_bh_derive_seed(s, 'ess_uncommon'))
    var _new_ess_rare       = PCGRng.new(_bh_derive_seed(s, 'ess_rare'))
    var _new_ess_vrare      = PCGRng.new(_bh_derive_seed(s, 'ess_vrare'))
    var _new_fineprint      = PCGRng.new(_bh_derive_seed(s, 'fineprint'))
    var _new_cosmetic       = PCGRng.new(_bh_derive_seed(s, 'cosmetic'))
    var _new_reel           = PCGRng.new(_bh_derive_seed(s, 'reel_init'))
    var _new_effect         = PCGRng.new(_bh_derive_seed(s, 'effect_init'))
    var _new_scratch        = PCGRng.new(_bh_derive_seed(s, 'scratch_init'))

    # === Phase 2: Atomically assign 鈥?ALL or NOTHING ===
    _bh_rng_spin           = _new_spin
    _bh_rng_rarity         = _new_rarity
    _bh_rng_sym_common     = _new_sym_common
    _bh_rng_sym_uncommon   = _new_sym_uncommon
    _bh_rng_sym_rare       = _new_sym_rare
    _bh_rng_sym_vrare      = _new_sym_vrare
    _bh_rng_itm_common     = _new_itm_common
    _bh_rng_itm_uncommon   = _new_itm_uncommon
    _bh_rng_itm_rare       = _new_itm_rare
    _bh_rng_itm_vrare      = _new_itm_vrare
    _bh_rng_ess_common     = _new_ess_common
    _bh_rng_ess_uncommon   = _new_ess_uncommon
    _bh_rng_ess_rare       = _new_ess_rare
    _bh_rng_ess_vrare      = _new_ess_vrare
    _bh_rng_fineprint      = _new_fineprint
    _bh_rng_cosmetic       = _new_cosmetic
    _bh_rng_reel           = _new_reel
    _bh_rng_effect         = _new_effect
    _bh_rng_scratch        = _new_scratch

    # === Fix C: Capture Godot global RNG ===
    seed(landlord_seed)

# ============================================================
# Per-spin RNG derivation
# ============================================================

func _bh_begin_spin_rng():
    var spin_val: int = _bh_rng_spin.randi_max(2147483647)
    _bh_rng_reel   = PCGRng.new(_bh_derive_seed(spin_val, 'reel'))
    _bh_rng_effect = PCGRng.new(_bh_derive_seed(spin_val, 'effect'))
    _bh_rng_scratch = PCGRng.new(_bh_derive_seed(spin_val, 'scratch'))

# ============================================================
# Per-rarity RNG dispatch for symbol choice
# ============================================================

func _bh_symbol_rng_for_rarity(rarity: String) -> PCGRng:
    match rarity:
        'common':     return _bh_rng_sym_common
        'uncommon':   return _bh_rng_sym_uncommon
        'rare':       return _bh_rng_sym_rare
        'very_rare':  return _bh_rng_sym_vrare
        _:            return _bh_rng_sym_common

# Called by new_game() Prefix 鈥?applies seed config from Title UI
func _bh_apply_seed():
    var title = $""/root/Main/Title""
    if title == null:
        printerr(""[BetterHistory] FATAL: /root/Main/Title is null in _bh_apply_seed!"")
        return
    if not title.has_method(""_bh_get_seed_config""):
        printerr(""[BetterHistory] FATAL: Title does not have _bh_get_seed_config!"")
        return
    var cfg = title._bh_get_seed_config()
    _bh_init_rng(str(cfg['type']), str(cfg['input']))

# Called by Godot when the window is closed mid-run.
# NOTIFICATION_WM_QUIT_REQUEST = 1006
func _notification(what: int):
    if what == 1006:
        if _bh_events.size() > 0 and not _bh_run_ended:
            _bh_end_run(""quit"")

func _bh_item_rng_for_rarity(rarity: String) -> PCGRng:
    match rarity:
        'common':     return _bh_rng_itm_common
        'uncommon':   return _bh_rng_itm_uncommon
        'rare':       return _bh_rng_itm_rare
        'very_rare':  return _bh_rng_itm_vrare
        _:            return _bh_rng_itm_common
";
}


// ============================================================
// SeedSignalReader.cs
// ============================================================
using SlotWeave.GameState;
using SlotWeave.NativeInterop;

namespace Piraeus.BetterLandlord.Ipc;

/// <summary>
/// GameStateBus reader: reads _bh_seed_request from Title node every frame.
/// Fires SeedRequested when value changes to non-zero.
/// </summary>
public class SeedSignalReader : IGameStateReader
{
    private long _prevValue;

    public event Action? SeedRequested;

    public void Read(EngineObjectReader reader, IntPtr sceneTree, GameStateSnapshot snap)
    {
        var node = reader.FindNode("Main/Title");
        if (node == IntPtr.Zero) return;

        var val = EngineObjectReader.ReadScriptProp(node, "_bh_seed_request");
        long curVal = 0;
        if (val is long l) curVal = l;
        else if (val is int i) curVal = i;

        if (curVal > 0 && curVal != _prevValue)
        {
            _prevValue = curVal;
            SeedRequested?.Invoke();
        }
    }
}


// ============================================================
// GamePipeServer.cs
// ============================================================
using System.Diagnostics;
using System.IO.Pipes;
using System.Text;
using System.Text.Json;
using Piraeus.BetterLandlord.Storage;
using ILogger = Serilog.ILogger;

namespace Piraeus.BetterLandlord.Ipc;

public class GamePipeServer : IDisposable
{
    private const string PipeName = "Piraeus.BetterLandlord.Pipe";
    private const string PushPipeName = "Piraeus.BetterLandlord.Push";
    private const string UiExeName = "Piraeus.BetterLandlord.UI.exe";
    private const int FlagPollIntervalMs = 500;

    private readonly HistoryStore _store;
    private readonly string _userDataDir;
    private readonly string _flagFilePath;
    private readonly string _seedFlagPath;
    private readonly string _uiExePath;
    private readonly ILogger _logger;
    private readonly CancellationTokenSource _cts = new();
    private Thread? _serverThread;
    private Thread? _pushThread;
    private Thread? _flagPollThread;
    private Process? _uiProcess;
    private NamedPipeServerStream? _pushServer;
    private readonly object _pushLock = new();
    private SeedSignalReader? _seedReader;

    public SeedSignalReader SeedReader => _seedReader ??= new SeedSignalReader();

    public GamePipeServer(HistoryStore store, string userDataDir, string modDir, ILogger logger)
    {
        _store = store;
        _userDataDir = userDataDir;
        _flagFilePath = Path.Combine(userDataDir, "betterHistory", "ui_requested");
        _seedFlagPath = Path.Combine(userDataDir, "betterHistory", "flag_seed");
        _uiExePath = Path.Combine(modDir, UiExeName);
        _logger = logger.ForContext("SourceContext", "GamePipe");
    }

    public void Start()
    {
        // 1. Request-response pipe
        _serverThread = new Thread(ServerLoop)
        {
            Name = "BetterHistory-PipeServer",
            IsBackground = true
        };
        _serverThread.Start();

        // 2. Push pipe 鈥?WPF connects and keeps connection open
        _pushThread = new Thread(PushLoop)
        {
            Name = "BetterHistory-PushServer",
            IsBackground = true
        };
        _pushThread.Start();

        // 3. Flag poll (for History button and seed flag)
        _flagPollThread = new Thread(FlagPollLoop)
        {
            Name = "BetterHistory-FlagPoll",
            IsBackground = true
        };
        _flagPollThread.Start();

        // 4. Hook seed signal from GameStateBus reader
        SeedReader.SeedRequested += OnSeedSignal;

        // 5. Launch WPF immediately (cold start happens during menu, not at button click)
        LaunchUiProcess();

        _logger.Information("[PipeServer] Started (push pipe + WPF pre-launch)");
    }

    // ---- Seed signal from GameStateBus ----

    private void OnSeedSignal()
    {
        _logger.Information("[PipeServer] Seed signal from GameStateBus");
        PushToClient("{\"type\":\"seed_request\"}");
    }

    // ---- Push pipe (server 鈫?WPF, persistent) ----

    private void PushLoop()
    {
        while (!_cts.IsCancellationRequested)
        {
            NamedPipeServerStream? server = null;
            try
            {
                server = new NamedPipeServerStream(PushPipeName, PipeDirection.Out, 1,
                    PipeTransmissionMode.Byte, PipeOptions.None);

                _logger.Information("[PushServer] Waiting for WPF push client...");
                server.WaitForConnection();
                _logger.Information("[PushServer] WPF push client connected");

                lock (_pushLock) { _pushServer = server; _pushBroken = false; }

                // Keep alive until Write fails or cancelled
                while (!_pushBroken && !_cts.IsCancellationRequested)
                {
                    try { Task.Delay(500, _cts.Token).Wait(); }
                    catch { break; }
                }

                lock (_pushLock) { _pushServer = null; }
                _logger.Information("[PushServer] WPF push client disconnected");
            }
            catch (OperationCanceledException) { break; }
            catch (IOException ex)
            {
                lock (_pushLock) { _pushServer = null; }
                _logger.Information("[PushServer] Connection ended: {Msg}", ex.Message);
            }
            catch (Exception ex)
            {
                lock (_pushLock) { _pushServer = null; }
                _logger.Error(ex, "[PushServer] Error");
            }
            finally
            {
                try { server?.Dispose(); } catch { }
            }

            try { Task.Delay(500, _cts.Token).Wait(); }
            catch { break; }
        }
    }

    private volatile bool _pushBroken;

    private void PushToClient(string message)
    {
        NamedPipeServerStream? server;
        lock (_pushLock) { server = _pushServer; }

        if (server == null)
        {
            _logger.Debug("[PushServer] No client, dropping: {Msg}", message);
            return;
        }

        try
        {
            var bytes = Encoding.UTF8.GetBytes(message + "\n");
            server.Write(bytes, 0, bytes.Length);
            server.Flush();
            _logger.Information("[PushServer] Pushed: {Msg}", message);
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "[PushServer] Write failed, marking broken");
            _pushBroken = true;
            lock (_pushLock) { _pushServer = null; }
        }
    }

    // ---- Flag poll (History button + seed flag fallback) ----

    private void FlagPollLoop()
    {
        while (!_cts.IsCancellationRequested)
        {
            try
            {
                if (File.Exists(_flagFilePath))
                {
                    _logger.Information("[PipeServer] History flag detected");
                    try { File.Delete(_flagFilePath); } catch { }
                    PushToClient("{\"type\":\"show_history\"}");
                }
            }
            catch { }
            try { Task.Delay(FlagPollIntervalMs, _cts.Token).Wait(); }
            catch { break; }
        }
    }

    // ---- WPF process management ----

    private void LaunchUiProcess()
    {
        try
        {
            if (_uiProcess != null)
            {
                if (!_uiProcess.HasExited)
                {
                    _logger.Debug("[PipeServer] UI process {Pid} already tracked", _uiProcess.Id);
                    return;
                }
                _uiProcess.Dispose();
                _uiProcess = null;
            }

            var exeName = Path.GetFileNameWithoutExtension(UiExeName);
            var procs = Process.GetProcessesByName(exeName);
            if (procs.Length > 0)
            {
                _uiProcess = procs[0];
                if (_uiProcess.MainWindowHandle == IntPtr.Zero)
                {
                    _logger.Warning("[PipeServer] Zombie process {Pid}, killing", _uiProcess.Id);
                    try { _uiProcess.Kill(); } catch { }
                    _uiProcess = null;
                }
                else
                {
                    _logger.Information("[PipeServer] Reusing existing UI PID={Pid}", _uiProcess.Id);
                    return;
                }
            }

            if (!File.Exists(_uiExePath))
            {
                _logger.Warning("[PipeServer] UI exe missing at {Path}", _uiExePath);
                return;
            }

            _uiProcess = Process.Start(new ProcessStartInfo
            {
                FileName = _uiExePath,
                Arguments = $"--data-dir \"{_userDataDir}\"",
                UseShellExecute = false,
                CreateNoWindow = false
            });
            _logger.Information("[PipeServer] Launched UI PID={Pid}", _uiProcess?.Id ?? 0);
        }
        catch (Exception ex) { _logger.Error(ex, "[PipeServer] Launch failed"); }
    }

    // ---- Request-response pipe (get_run_list, get_run, set_seed) ----

    private void ServerLoop()
    {
        while (!_cts.IsCancellationRequested)
        {
            NamedPipeServerStream? server = null;
            try
            {
                server = new NamedPipeServerStream(PipeName, PipeDirection.InOut, 1,
                    PipeTransmissionMode.Byte, PipeOptions.None);

                server.WaitForConnection();
                _logger.Information("[PipeServer] Client connected");

                var req = ReadLine(server);
                if (req == null) continue;

                var msgType = PipeProtocol.PeekType(req);
                _logger.Information("[PipeServer] Got: {Type}", msgType ?? "?");

                string? response = null;
                switch (msgType)
                {
                    case PipeProtocol.TypeGetRunList:
                        response = BuildRunListJson();
                        break;

                    case PipeProtocol.TypeGetRun:
                        var getRun = PipeProtocol.Deserialize<GetRunMessage>(req);
                        if (getRun != null)
                            response = BuildRunDataJson(getRun.RunId);
                        break;

                    case PipeProtocol.TypeSetSeed:
                        var setSeed = PipeProtocol.Deserialize<SetSeedMessage>(req);
                        if (setSeed != null)
                        {
                            var seedPath = Path.Combine(_store.HistoryDir, "seed_config.json");
                            var seedType = string.IsNullOrEmpty(setSeed.Input) ? "random" : "custom";
                            var seedJson = System.Text.Json.JsonSerializer.Serialize(
                                new { type = seedType, input = setSeed.Input, updated_at = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss") });
                            File.WriteAllText(seedPath, seedJson);
                            _logger.Information("[PipeServer] Seed saved: {Seed}", setSeed.Input);
                            // Push seed state update to WPF
                            PushToClient("{\"type\":\"seed_updated\",\"input\":\"" +
                                setSeed.Input.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"}");
                        }
                        response = PipeProtocol.Serialize(new { status = "ok" });
                        break;

                    case PipeProtocol.TypeClose:
                        break;

                    default:
                        response = PipeProtocol.Serialize(new ErrorMessage
                            { Message = $"Unknown: {msgType}" });
                        break;
                }

                if (response != null)
                {
                    var respBytes = Encoding.UTF8.GetBytes(response + "\n");
                    server.Write(respBytes, 0, respBytes.Length);
                    server.Flush();
                }
            }
            catch (OperationCanceledException) { break; }
            catch (IOException ex)
            {
                _logger.Information("[PipeServer] Connection ended: {Msg}", ex.Message);
            }
            catch (Exception ex)
            {
                _logger.Error(ex, "[PipeServer] Error");
            }
            finally
            {
                try { server?.Dispose(); } catch { }
            }

            try { Task.Delay(100, _cts.Token).Wait(); }
            catch { break; }
        }
        _logger.Information("[PipeServer] Stopped");
    }

    private static string? ReadLine(NamedPipeServerStream stream)
    {
        var buf = new byte[8192];
        var ms = new MemoryStream();
        bool gotLine = false;

        while (!gotLine && stream.IsConnected)
        {
            int n;
            try { n = stream.Read(buf, 0, buf.Length); }
            catch (IOException) { return null; }
            if (n == 0) return null;

            for (int i = 0; i < n; i++)
            {
                if (buf[i] == (byte)'\n')
                {
                    gotLine = true;
                    break;
                }
                ms.WriteByte(buf[i]);
            }
        }

        return gotLine ? Encoding.UTF8.GetString(ms.ToArray()) : null;
    }

    private string BuildRunListJson()
    {
        var manifestEntries = _store.LoadManifestEntries();
        var manifestSet = new HashSet<string>();
        var items = new List<RunListItem>();

        if (manifestEntries != null && manifestEntries.Entries.Count > 0)
        {
            foreach (var e in manifestEntries.Entries)
            {
                manifestSet.Add(e.RunId);
                items.Add(new RunListItem
                {
                    RunId = e.RunId,
                    RunNumber = e.RunNumber,
                    EndedBy = e.EndedBy,
                    Floor = e.Floor,
                    FinalCoins = e.FinalCoins,
                    TotalSpins = e.TotalSpins,
                    StartTime = e.StartTime,
                    TopSymbols = e.TopSymbols
                });
            }
        }

        var allRunIds = _store.GetExistingHistoryIds();
        var newIds = allRunIds.Where(id => !manifestSet.Contains(id)).ToList();
        if (newIds.Count > 0)
        {
            var runsDir = Path.Combine(_store.HistoryDir, "runs");
            foreach (var runId in newIds)
            {
                try
                {
                    var path = Path.Combine(runsDir, $"{runId}.json");
                    var json = File.ReadAllText(path);
                    using var doc = JsonDocument.Parse(json);
                    var root = doc.RootElement;
                    var meta = root.TryGetProperty("meta", out var m) ? m : default;
                    items.Add(new RunListItem
                    {
                        RunId = runId,
                        RunNumber = meta.TryGetProperty("run_number", out var rn) ? rn.GetInt32() : 0,
                        EndedBy = meta.TryGetProperty("ended_by", out var eb) ? eb.GetString() ?? "loss" : "loss",
                        Floor = meta.TryGetProperty("floor", out var fl) && fl.ValueKind != System.Text.Json.JsonValueKind.Null ? fl.GetInt32() : null,
                        FinalCoins = meta.TryGetProperty("final_coins", out var fc) ? fc.GetInt64() : 0,
                        TotalSpins = meta.TryGetProperty("total_spins", out var ts) ? ts.GetInt32() : 0,
                        StartTime = meta.TryGetProperty("start_time", out var st) && st.ValueKind != System.Text.Json.JsonValueKind.Null ? st.GetString() : null,
                        TopSymbols = HistoryStore.ExtractTopSymbols(doc)
                    });
                }
                catch { }
            }
            _logger.Information("[PipeServer] Merged {Count} new runs not in manifest", newIds.Count);
        }

        items.Sort((a, b) => string.CompareOrdinal(b.RunId, a.RunId));
        _logger.Information("[PipeServer] Sending {Count} runs", items.Count);
        return PipeProtocol.Serialize(new RunListMessage { Runs = items });
    }

    private string BuildRunDataJson(string runId)
    {
        var record = _store.Load(runId);
        if (record == null)
            return PipeProtocol.Serialize(new ErrorMessage { Message = $"Not found: {runId}" });

        return PipeProtocol.Serialize(new RunDataMessage { Record = record });
    }

    public void Dispose()
    {
        _cts.Cancel();
        _cts.Dispose();
    }
}


// ============================================================
// PipeProtocol.cs
// ============================================================
using System.Text.Json;
using System.Text.Json.Serialization;
using Piraeus.BetterLandlord.Model;

namespace Piraeus.BetterLandlord.Ipc;

/// <summary>
/// Shared IPC message types and serialization helpers.
/// Used by both GamePipeServer (game side) and UiPipeClient (UI side).
/// </summary>
public static class PipeProtocol
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true,
        WriteIndented = false
    };

    // ---- Message type constants ----

    public const string TypeRunList = "run_list";
    public const string TypeRunData = "run_data";
    public const string TypeError = "error";
    public const string TypeGetRunList = "get_run_list";
    public const string TypeGetRun = "get_run";
    public const string TypeSetSeed = "set_seed";
    public const string TypeClose = "close";

    // ---- Serialization ----

    public static string Serialize<T>(T message) =>
        JsonSerializer.Serialize(message, JsonOptions);

    public static T? Deserialize<T>(string json) =>
        JsonSerializer.Deserialize<T>(json, JsonOptions);

    /// <summary>Peek the "type" field without full deserialization.</summary>
    public static string? PeekType(string json)
    {
        try
        {
            var doc = JsonDocument.Parse(json);
            return doc.RootElement.TryGetProperty("type", out var typeEl) ? typeEl.GetString() : null;
        }
        catch
        {
            return null;
        }
    }
}

// ---- Game 鈫?UI messages ----

public class RunListMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeRunList;

    [JsonPropertyName("runs")]
    public List<RunListItem> Runs { get; set; } = new();
}

public class RunListItem
{
    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";

    [JsonPropertyName("run_number")]
    public int RunNumber { get; set; }

    [JsonPropertyName("ended_by")]
    public string EndedBy { get; set; } = "unknown";

    [JsonPropertyName("floor")]
    public int? Floor { get; set; }

    [JsonPropertyName("final_coins")]
    public long FinalCoins { get; set; }

    [JsonPropertyName("total_spins")]
    public int TotalSpins { get; set; }

    [JsonPropertyName("start_time")]
    public string? StartTime { get; set; }

    [JsonPropertyName("top_symbols")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<string>? TopSymbols { get; set; }
}

public class RunDataMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeRunData;

    [JsonPropertyName("record")]
    public RunRecord? Record { get; set; }
}

public class ErrorMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeError;

    [JsonPropertyName("message")]
    public string Message { get; set; } = "";
}

// ---- UI 鈫?Game messages ----

public class SetSeedMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeSetSeed;

    [JsonPropertyName("input")]
    public string Input { get; set; } = "";
}

public class GetRunListMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeGetRunList;
}

public class GetRunMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeGetRun;

    [JsonPropertyName("run_id")]
    public string RunId { get; set; } = "";
}

public class CloseMessage
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = PipeProtocol.TypeClose;
}


// ============================================================
// Mod.cs
// ============================================================
using SlotWeave;
using Piraeus.BetterLandlord.Ipc;
using Piraeus.BetterLandlord.Patches;
using Piraeus.BetterLandlord.Storage;

namespace Piraeus.BetterLandlord;

public class Mod : IMod
{
    private readonly IModInterface _modInterface;
    private GamePipeServer? _pipeServer;

    public Mod(IModInterface modInterface)
    {
        _modInterface = modInterface;
        _modInterface.Logger.Information("[BetterLandlord] initializing...");

        // ISourceMod: event capture helpers on Main node (Main.tscn::1)
        _modInterface.RegisterSourceMod(new MainScriptSourceMod());

        // ISourceMod: RNG infrastructure (PCGRng class, init_rng) on Main node
        _modInterface.RegisterSourceMod(new RngInfrastructureSourceMod());

        // ISourceMod: Choice RNG replacements in Pop-up
        _modInterface.RegisterSourceMod(new ChoiceRngSourceMod());

        // ReelRNG: inject wrappers only (no full-file Regex 鈥?regex on this
        // heavily-instantiated script triggers GDScript reload crash)
        _modInterface.RegisterSourceMod(new ReelRngRefSourceMod());

        _modInterface.RegisterSourceMod(new SlotIconRngSourceMod());
        _modInterface.RegisterSourceMod(new ItemRngSourceMod());
        _modInterface.RegisterSourceMod(new ReelExtraRngSourceMod());
        _modInterface.RegisterSourceMod(new LandlordRngRefSourceMod());
        _modInterface.RegisterSourceMod(new CosmeticRngSourceMod());
        // _modInterface.RegisterSourceMod(new ItemRngSourceMod());

        // Reel extras 鈥?DISABLED
        // _modInterface.RegisterSourceMod(new ReelExtraRngSourceMod());

        // FinePrintRNG 鈥?DISABLED
        // _modInterface.RegisterSourceMod(new LandlordRngRefSourceMod());

        // CosmeticRNG 鈥?DISABLED
        // _modInterface.RegisterSourceMod(new CosmeticRngSourceMod());

        // ISourceMod: clipboard preservation (TTButton clears clipboard for TTS)
        _modInterface.RegisterSourceMod(new ClipboardPreserveMod());

        // ISourceMod: seed UI on Title node (Main.tscn::6)
        _modInterface.RegisterSourceMod(new TitleSeedSourceMod());

        // ISourceMod: IPC toggle helpers on Title node (Main.tscn::6)
        _modInterface.RegisterSourceMod(new TitleToggleSourceMod());

        // [Patch] classes are auto-discovered by SlotWeave:
        // ReadyPatch, TitlePatch, SpinPatch, WriteLogPatch,
        // ResolveEventPatch, HistoryButtonPatch

        // Run legacy log migration on startup
        RunMigration();

        // Initialize and start the IPC pipe server.
        var userDataDir = GetUserDataDir();
        var modDir = Path.GetDirectoryName(typeof(Mod).Assembly.Location)
                     ?? Path.Combine(_modInterface.GameDir, "SlotWeave", "mods", "Piraeus.BetterLandlord");
        var store = new HistoryStore(userDataDir);

        // Rebuild lightweight manifest (fast 鈥?uses JsonDocument, not full deserialization)
        store.RebuildManifest();

        _pipeServer = new GamePipeServer(store, userDataDir, modDir, _modInterface.Logger);

        // Register GameStateBus reader for seed request signal (GDScript 鈫?C#, ~16ms latency)
        _modInterface.RegisterGameStateReader(_pipeServer.SeedReader);

        _pipeServer.Start();
    }

    private void RunMigration()
    {
        try
        {
            var userDataDir = GetUserDataDir();
            var runner = new MigrationRunner(userDataDir);
            var result = runner.Run();

            _modInterface.Logger.Information(
                "[BetterLandlord] Migration done: {Migrated} complete + {Truncated} truncated + {Partial} partial " +
                "({Skipped} skipped, {Empty} empty, {Corrupted} corrupted, {Failed} failed) 鈥?history db at {Dir}",
                result.Migrated, result.MigratedTruncated, result.MigratedPartial,
                result.Skipped, result.EmptyFiles, result.Corrupted, result.Failed,
                runner.HistoryDir);
        }
        catch (Exception ex)
        {
            _modInterface.Logger.Error("[BetterLandlord] Migration failed: {Error}", ex.Message);
        }
    }

    private static string GetUserDataDir()
    {
        var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        return Path.Combine(appData, "Godot", "app_userdata", "Luck be a Landlord");
    }

    public void Dispose()
    {
        _pipeServer?.Dispose();
        _modInterface.Logger.Information("[BetterLandlord] unloaded.");
    }
}


// ============================================================
// UiPipeClient.cs
// ============================================================
using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Text.Json;

namespace Piraeus.BetterLandlord.UI.Ipc;

/// <summary>
/// Named Pipe client 鈥?request-response + push notifications.
/// </summary>
public class UiPipeClient : IDisposable
{
    private const string PipeName = "Piraeus.BetterLandlord.Pipe";
    private const string PushPipeName = "Piraeus.BetterLandlord.Push";
    private const int ConnectTimeoutMs = 5000;

    private readonly CancellationTokenSource _cts = new();
    private Thread? _pushThread;

    public event Action<string>? OnMessageReceived;
    public event Action<bool>? OnConnectionChanged;
    public event Action<string>? OnError;
    public event Action<string>? OnPushMessage;

    public bool IsConnected { get; private set; }

    public void Start()
    {
        var t = new Thread(RunLoop)
        {
            Name = "BetterLandlord-PipeIO",
            IsBackground = true
        };
        t.Start();

        // Start push listener
        _pushThread = new Thread(PushListenerLoop)
        {
            Name = "BetterLandlord-PushIO",
            IsBackground = true
        };
        _pushThread.Start();
    }

    private void RunLoop()
    {
        while (!_cts.IsCancellationRequested)
        {
            var result = DoRequest(
                JsonSerializer.Serialize(new { type = "get_run_list" }));
            if (result != null)
            {
                OnConnectionChanged?.Invoke(true);
                IsConnected = true;
                OnMessageReceived?.Invoke(result);
                break;
            }
            try { Task.Delay(500, _cts.Token).Wait(); }
            catch { return; }
        }

        while (!_cts.IsCancellationRequested)
        {
            try { Task.Delay(1000, _cts.Token).Wait(); }
            catch { break; }
        }
    }

    /// <summary>Persistent connection to push pipe 鈥?receives server-initiated messages.</summary>
    private void PushListenerLoop()
    {
        while (!_cts.IsCancellationRequested)
        {
            NamedPipeClientStream? client = null;
            try
            {
                client = new NamedPipeClientStream(".", PushPipeName, PipeDirection.In);
                client.Connect(ConnectTimeoutMs);
                if (!client.IsConnected) continue;

                OnPushMessage?.Invoke("{\"type\":\"push_connected\"}");

                // Read loop 鈥?one line per push message
                var buf = new byte[8192];
                var ms = new MemoryStream();
                while (client.IsConnected && !_cts.IsCancellationRequested)
                {
                    int n;
                    try { n = client.Read(buf, 0, buf.Length); }
                    catch (IOException) { break; }
                    if (n == 0) break;

                    for (int i = 0; i < n; i++)
                    {
                        if (buf[i] == (byte)'\n')
                        {
                            var msg = Encoding.UTF8.GetString(ms.ToArray());
                            ms.SetLength(0);
                            if (msg.Length > 0)
                                OnPushMessage?.Invoke(msg);
                        }
                        else
                        {
                            ms.WriteByte(buf[i]);
                        }
                    }
                }
            }
            catch (TimeoutException) { }
            catch (IOException) { }
            catch (Exception ex)
            {
                OnError?.Invoke($"Push pipe error: {ex.Message}");
            }
            finally
            {
                try { client?.Dispose(); } catch { }
            }

            try { Task.Delay(1000, _cts.Token).Wait(); }
            catch { break; }
        }
    }

    private string? DoRequest(string requestJson)
    {
        NamedPipeClientStream? client = null;
        try
        {
            client = new NamedPipeClientStream(".", PipeName, PipeDirection.InOut);
            client.Connect(ConnectTimeoutMs);
            if (!client.IsConnected) return null;

            var reqBytes = Encoding.UTF8.GetBytes(requestJson + "\n");
            client.Write(reqBytes, 0, reqBytes.Length);
            client.Flush();

            var buf = new byte[8192];
            var ms = new MemoryStream();
            bool gotLine = false;

            while (!gotLine && client.IsConnected)
            {
                int n = client.Read(buf, 0, buf.Length);
                if (n == 0) break;

                for (int i = 0; i < n; i++)
                {
                    if (buf[i] == (byte)'\n')
                    {
                        gotLine = true;
                        break;
                    }
                    ms.WriteByte(buf[i]);
                }
            }

            if (!gotLine) return null;

            return Encoding.UTF8.GetString(ms.ToArray());
        }
        catch (TimeoutException) { return null; }
        catch (IOException) { return null; }
        catch (Exception ex)
        {
            OnError?.Invoke($"Pipe error: {ex.Message}");
            return null;
        }
        finally
        {
            try { client?.Dispose(); } catch { }
        }
    }

    private void SendRequest(string requestJson)
    {
        ThreadPool.QueueUserWorkItem(_ =>
        {
            var response = DoRequest(requestJson);
            if (response != null)
                OnMessageReceived?.Invoke(response);
            else
                OnError?.Invoke("No response from game");
        });
    }

    public void SendGetRunList()
        => SendRequest(JsonSerializer.Serialize(new { type = "get_run_list" }));

    public void SendGetRun(string runId)
        => SendRequest(JsonSerializer.Serialize(new { type = "get_run", run_id = runId }));

    public void SendSetSeed(string input)
        => SendRequest(JsonSerializer.Serialize(new { type = "set_seed", input }));

    public void SendClose()
    {
        try { DoRequest(JsonSerializer.Serialize(new { type = "close" })); }
        catch { }
    }

    public void Dispose()
    {
        _cts.Cancel();
        _cts.Dispose();
    }
}


// ============================================================
// MainWindow.xaml.cs
// ============================================================
using System.Windows;
using Piraeus.BetterLandlord.UI.Ipc;
using Piraeus.BetterLandlord.UI.ViewModels;

namespace Piraeus.BetterLandlord.UI;

public partial class MainWindow : Window
{
    private readonly UiPipeClient _pipeClient;
    private readonly HistoryViewModel _viewModel;
    private bool _seedDialogOpen;
    private bool _firstShow = true;

    public MainWindow()
    {
        InitializeComponent();

        _pipeClient = new UiPipeClient();
        _viewModel = new HistoryViewModel(_pipeClient);
        DataContext = _viewModel;

        Loaded += OnWindowLoaded;
        Closed += OnWindowClosed;
        Closing += OnWindowClosing;
    }

    /// <summary>
    /// Connect pipe + push listener without showing the window.
    /// Called once at app startup.
    /// </summary>
    public void ConnectPipe()
    {
        _pipeClient.OnPushMessage += HandlePushMessage;
        _pipeClient.Start();
    }

    private void OnWindowLoaded(object sender, RoutedEventArgs e)
    {
        if (_firstShow)
        {
            _firstShow = false;
            Focusable = true;
            PreviewKeyDown += OnPreviewKeyDown;
        }
    }

    private void HandlePushMessage(string json)
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(() => HandlePushMessage(json));
            return;
        }

        var type = PeekType(json);
        switch (type)
        {
            case "seed_request":
                ShowSeedDialog();
                break;

            case "show_history":
                ShowFromTray();
                break;

            case "seed_updated":
                break;

            case "push_connected":
                break;
        }
    }

    private void ShowFromTray()
    {
        if (Visibility == Visibility.Visible) return;

        Show();
        WindowState = WindowState.Normal;
        Activate();
        // WPF hack: Topmost toggle forces window to front over Godot fullscreen
        Topmost = true;
        Topmost = false;
    }

    private static string PeekType(string json)
    {
        try
        {
            var doc = System.Text.Json.JsonDocument.Parse(json);
            return doc.RootElement.TryGetProperty("type", out var t) ? t.GetString() ?? "" : "";
        }
        catch { return ""; }
    }

    private void OnPreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == System.Windows.Input.Key.Left)
        {
            _viewModel.CycleRankMode(-1);
            e.Handled = true;
        }
        else if (e.Key == System.Windows.Input.Key.Right)
        {
            _viewModel.CycleRankMode(1);
            e.Handled = true;
        }
    }

    private void RankPrev_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.CycleRankMode(-1);
    }

    private void RankNext_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.CycleRankMode(1);
    }

    private bool _reallyClosing;

    private void OnWindowClosing(object? sender, System.ComponentModel.CancelEventArgs e)
    {
        if (!_reallyClosing)
        {
            e.Cancel = true;
            Hide();
        }
    }

    private void OnWindowClosed(object? sender, EventArgs e)
    {
    }

    public void Cleanup()
    {
        _reallyClosing = true;
        _pipeClient.OnPushMessage -= HandlePushMessage;
        _pipeClient.SendClose();
        _pipeClient.Dispose();
        Close();
    }

    private void ShowSeedDialog()
    {
        if (_seedDialogOpen)
            return;

        _seedDialogOpen = true;
        try
        {
            var dialog = new SeedDialog(_pipeClient);
            dialog.ShowDialog();
        }
        finally
        {
            _seedDialogOpen = false;
        }
    }

    private void ToggleSummary_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.ToggleSummary();
    }

    private void CopySeed_Click(object sender, RoutedEventArgs e)
    {
        var seed = _viewModel.MetaSeed;
        if (!string.IsNullOrEmpty(seed))
        {
            var dataObj = new DataObject();
            dataObj.SetData(DataFormats.UnicodeText, seed, false);
            Clipboard.SetDataObject(dataObj, true);
            _viewModel.StatusText = $"Seed copied: {seed}";
        }
    }
}


// ============================================================
// MainWindow.xaml
// ============================================================
<Window x:Class="Piraeus.BetterLandlord.UI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Piraeus.BetterLandlord.UI"
        xmlns:conv="clr-namespace:Piraeus.BetterLandlord.UI.Converters"
        mc:Ignorable="d"
        Title="Better Landlord"
        Height="720" Width="1100"
        MinHeight="480" MinWidth="800"
        Background="#1E1E2E"
        WindowStartupLocation="CenterScreen">

    <Window.Resources>
        <conv:BoolToVisibilityConverter x:Key="BoolToVis" />
        <conv:BoolToVisibilityConverter x:Key="InvertBoolToVis" Invert="True" />
        <conv:ResultToColorConverter x:Key="ResultToColor" />
        <conv:ResultToIconConverter x:Key="ResultToIcon" />
        <conv:IconNameToImageConverter x:Key="IconImage" />
        <conv:NullToVisibilityConverter x:Key="NullToVis" />

        <SolidColorBrush x:Key="TextColor" Color="#CDD6F4" />
        <SolidColorBrush x:Key="MutedColor" Color="#6C7086" />
        <SolidColorBrush x:Key="AccentColor" Color="#89B4FA" />
        <SolidColorBrush x:Key="GreenColor" Color="#A6E3A1" />
        <SolidColorBrush x:Key="RedColor" Color="#F38BA8" />

        <Style x:Key="RunListItemStyle" TargetType="ListBoxItem">
            <Setter Property="Background" Value="Transparent" />
            <Setter Property="Foreground" Value="#CDD6F4" />
            <Setter Property="Padding" Value="12,8" />
            <Setter Property="BorderThickness" Value="0,0,0,1" />
            <Setter Property="BorderBrush" Value="#45475A" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border x:Name="Border"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#363650" />
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#313255" />
                                <Setter Property="Foreground" Value="#89B4FA" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <!-- Title bar -->
        <Border Grid.Row="0" Background="#181825" Padding="16,10">
            <Grid>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="Better Landlord"
                               FontSize="16" FontWeight="SemiBold"
                               Foreground="#CDD6F4" />
                    <TextBlock Text="Created by Piraeus"
                               FontSize="10"
                               Foreground="#6C7086"
                               VerticalAlignment="Center" Margin="10,2,0,0" />
                </StackPanel>
                <TextBlock Text="{Binding StatusText, Mode=OneWay}"
                           FontSize="12"
                           Foreground="#6C7086"
                           HorizontalAlignment="Right"
                           VerticalAlignment="Center" />
            </Grid>
        </Border>

        <!-- Main content -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="280" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
            </Grid.ColumnDefinitions>

            <!-- Left: Run list -->
            <Border Grid.Column="0" Background="#1E1E2E"
                    BorderBrush="#45475A" BorderThickness="0,0,1,0">
                <DockPanel>
                    <Border DockPanel.Dock="Top" Background="#252538"
                            Padding="12,10" BorderBrush="#45475A"
                            BorderThickness="0,0,0,1">
                        <TextBlock Text="Run History"
                                   FontSize="14" FontWeight="SemiBold"
                                   Foreground="#89B4FA" />
                    </Border>

                    <ListBox ItemsSource="{Binding Runs}"
                             SelectedItem="{Binding SelectedRun}"
                             ItemContainerStyle="{StaticResource RunListItemStyle}"
                             Background="Transparent"
                             BorderThickness="0"
                             ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="Auto" />
                                    </Grid.ColumnDefinitions>

                                    <!-- Left: text info -->
                                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                                        <TextBlock FontSize="13" FontWeight="SemiBold"
                                                   Foreground="{StaticResource TextColor}"
                                                   Text="{Binding RunLabel, Mode=OneWay}" />
                                        <StackPanel Orientation="Horizontal" Margin="0,2,0,0">
                                            <TextBlock FontSize="11" Width="55"
                                                       Foreground="{Binding EndedBy, Mode=OneWay, Converter={StaticResource ResultToColor}}"
                                                       Text="{Binding ResultText, Mode=OneWay}"
                                                       VerticalAlignment="Center" />
                                            <Image Source="{Binding Converter={StaticResource IconImage}, ConverterParameter=coin}"
                                                   Width="14" Height="14" Margin="2,0,2,0"
                                                   VerticalAlignment="Center" />
                                            <TextBlock FontSize="11"
                                                       Foreground="#A6E3A1" FontWeight="SemiBold"
                                                       Text="{Binding FinalCoins, Mode=OneWay}"
                                                       VerticalAlignment="Center" />
                                        </StackPanel>
                                    </StackPanel>

                                    <!-- Right: top 3 symbol icons -->
                                    <ItemsControl Grid.Column="1"
                                                  ItemsSource="{Binding TopSymbols, Mode=OneWay}"
                                                  Visibility="{Binding HasTopSymbols, Converter={StaticResource BoolToVis}}"
                                                  VerticalAlignment="Bottom" Margin="6,0,0,2">
                                        <ItemsControl.ItemsPanel>
                                            <ItemsPanelTemplate>
                                                <StackPanel Orientation="Horizontal" />
                                            </ItemsPanelTemplate>
                                        </ItemsControl.ItemsPanel>
                                        <ItemsControl.ItemTemplate>
                                            <DataTemplate>
                                                <Image Source="{Binding Mode=OneWay, Converter={StaticResource IconImage}}"
                                                       Width="22" Height="22" Margin="2,0"
                                                       Stretch="Uniform"
                                                       RenderOptions.BitmapScalingMode="NearestNeighbor" />
                                            </DataTemplate>
                                        </ItemsControl.ItemTemplate>
                                    </ItemsControl>
                                </Grid>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                </DockPanel>
            </Border>

            <GridSplitter Grid.Column="1" Width="3"
                          Background="#45475A"
                          HorizontalAlignment="Center"
                          VerticalAlignment="Stretch" />

            <!-- Right: Timeline + Summary -->
            <ScrollViewer Grid.Column="2" Background="#1E1E2E"
                          VerticalScrollBarVisibility="Auto">
                <StackPanel Margin="24">
                    <!-- Run header -->
                    <TextBlock FontSize="20" FontWeight="Bold" Foreground="#CDD6F4"
                               Text="{Binding RunInfo, Mode=OneWay}"
                               Margin="0,0,0,4" />

                    <!-- Global info bar -->
                    <Border Background="#252538" CornerRadius="4" Padding="10,8" Margin="0,0,0,14"
                            Visibility="{Binding HasData, Converter={StaticResource BoolToVis}}">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock FontSize="12" FontWeight="SemiBold"
                                       Foreground="{Binding CurrentRecord.Meta.EndedBy, Mode=OneWay, Converter={StaticResource ResultToColor}}"
                                       Text="{Binding MetaResult, Mode=OneWay}" />
                            <StackPanel Orientation="Horizontal" Margin="16,0,16,0"
                                        VerticalAlignment="Center">
                                <Image Source="{Binding Converter={StaticResource IconImage}, ConverterParameter=coin}"
                                       Width="14" Height="14" Margin="0,0,3,0" />
                                <TextBlock FontSize="12" Foreground="#A6E3A1" FontWeight="SemiBold"
                                           Text="{Binding MetaCoins, Mode=OneWay}"
                                           VerticalAlignment="Center" />
                            </StackPanel>
                            <TextBlock FontSize="12" Foreground="#6C7086"
                                       Text="{Binding MetaDate, Mode=OneWay}"
                                       VerticalAlignment="Center" />
                            <!-- Seed -->
                            <StackPanel Orientation="Horizontal" Margin="16,0,0,0"
                                        Visibility="{Binding HasSeed, Converter={StaticResource BoolToVis}}"
                                        VerticalAlignment="Center">
                                <TextBlock FontSize="11" Foreground="#6C7086"
                                           VerticalAlignment="Center">
                                    <Run Text="{Binding MetaSeedType, Mode=OneWay}" />
                                    <Run Text=": " />
                                    <Run Text="{Binding MetaSeed, Mode=OneWay}" Foreground="#89B4FA" FontWeight="SemiBold" />
                                </TextBlock>
                                <Button Content="馃搵" Click="CopySeed_Click"
                                        Background="Transparent" BorderThickness="0"
                                        Foreground="#6C7086" FontSize="11"
                                        Cursor="Hand" ToolTip="Copy seed"
                                        Padding="4,0" Margin="2,0,0,0" />
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- 鍌ㄧ墿闂?-->
                    <Border Background="#1E2430" CornerRadius="6"
                            Padding="14,12" Margin="0,0,0,16"
                            Visibility="{Binding HasData, Converter={StaticResource BoolToVis}}">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*" />
                                <ColumnDefinition Width="4" />
                                <ColumnDefinition Width="220" />
                            </Grid.ColumnDefinitions>

                            <!-- Left: 鍌ㄧ墿闂?-->
                            <StackPanel Grid.Column="0">
                                <TextBlock FontSize="14" FontWeight="Bold" Foreground="#FAB387"
                                           Text="鍌ㄧ墿闂? Margin="0,0,0,8" />

                                <!-- Symbols: label above, wrapping grid -->
                            <TextBlock FontSize="11" Foreground="#6C7086"
                                       Text="Symbols:" Margin="0,0,0,4" />
                            <ItemsControl ItemsSource="{Binding Summary.Symbols, Mode=OneWay}" Margin="0,0,0,8">
                                <ItemsControl.ItemsPanel>
                                    <ItemsPanelTemplate><WrapPanel /></ItemsPanelTemplate>
                                </ItemsControl.ItemsPanel>
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,8,2">
                                            <TextBlock FontSize="11" Foreground="#CDD6F4"
                                                       Text="{Binding Count, Mode=OneWay, StringFormat='{}{0}'}"
                                                       VerticalAlignment="Center" Margin="0,0,2,0" />
                                            <Grid>
                                                <Image Source="{Binding Id, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                       Width="18" Height="18" Stretch="Uniform">
                                                    <Image.ToolTip>
                                                        <ToolTip Background="#1E2030" BorderBrush="#45475A"
                                                                 BorderThickness="1" Padding="6,4"
                                                                 HasDropShadow="True">
                                                            <TextBlock FontSize="11" Foreground="#CDD6F4"
                                                                       Text="{Binding DptDisplay, Mode=OneWay}" />
                                                        </ToolTip>
                                                    </Image.ToolTip>
                                                </Image>
                                                <Border Background="#CC3333" CornerRadius="3"
                                                        HorizontalAlignment="Right" VerticalAlignment="Top"
                                                        Margin="0,-3,-3,0"
                                                        Visibility="{Binding HasBadge, Converter={StaticResource BoolToVis}}">
                                                    <TextBlock FontSize="8" Foreground="White"
                                                               Text="{Binding BadgeText, Mode=OneWay}"
                                                               Padding="2,0" />
                                                </Border>
                                            </Grid>
                                        </StackPanel>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>

                            <!-- Items -->
                            <TextBlock FontSize="11" Foreground="#6C7086"
                                       Text="Items:" Margin="0,0,0,4" />
                            <ItemsControl ItemsSource="{Binding Summary.Items, Mode=OneWay}" Margin="0,0,0,8">
                                <ItemsControl.ItemsPanel>
                                    <ItemsPanelTemplate><WrapPanel /></ItemsPanelTemplate>
                                </ItemsControl.ItemsPanel>
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <Grid Margin="0,0,6,2">
                                            <Image Source="{Binding Id, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                   Width="18" Height="18" Stretch="Uniform" />
                                            <Border Background="#CC3333" CornerRadius="3"
                                                    HorizontalAlignment="Right" VerticalAlignment="Top"
                                                    Margin="0,-3,-3,0"
                                                    Visibility="{Binding HasBadge, Converter={StaticResource BoolToVis}}">
                                                <TextBlock FontSize="8" Foreground="White"
                                                           Text="{Binding BadgeText, Mode=OneWay}"
                                                           Padding="2,0" />
                                            </Border>
                                        </Grid>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>

                            <!-- Destroyed Symbols -->
                            <StackPanel Margin="0,0,0,6"
                                        Visibility="{Binding Summary.DestroyedSymbols.Count, Converter={StaticResource BoolToVis}}">
                                <TextBlock FontSize="11" Foreground="#F38BA8"
                                           Text="Destroyed Symbols:" Margin="0,0,0,4" />
                                <ItemsControl ItemsSource="{Binding Summary.DestroyedSymbols, Mode=OneWay}">
                                    <ItemsControl.ItemsPanel>
                                        <ItemsPanelTemplate><WrapPanel /></ItemsPanelTemplate>
                                    </ItemsControl.ItemsPanel>
                                    <ItemsControl.ItemTemplate>
                                        <DataTemplate>
                                            <StackPanel Orientation="Horizontal" Margin="0,0,8,2">
                                                <TextBlock FontSize="11" Foreground="#F38BA8"
                                                           Text="{Binding Count, TargetNullValue='1', Mode=OneWay, StringFormat='{}{0}'}"
                                                           VerticalAlignment="Center" Margin="0,0,2,0" />
                                                <Image Source="{Binding Id, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                       Width="16" Height="16" Stretch="Uniform" />
                                            </StackPanel>
                                        </DataTemplate>
                                    </ItemsControl.ItemTemplate>
                                </ItemsControl>
                            </StackPanel>

                            <!-- Destroyed Items -->
                            <StackPanel Margin="0,0,0,6"
                                        Visibility="{Binding Summary.DestroyedItems.Count, Converter={StaticResource BoolToVis}}">
                                <TextBlock FontSize="11" Foreground="#F38BA8"
                                           Text="Destroyed Items:" Margin="0,0,0,4" />
                                <ItemsControl ItemsSource="{Binding Summary.DestroyedItems, Mode=OneWay}">
                                    <ItemsControl.ItemsPanel>
                                        <ItemsPanelTemplate><WrapPanel /></ItemsPanelTemplate>
                                    </ItemsControl.ItemsPanel>
                                    <ItemsControl.ItemTemplate>
                                        <DataTemplate>
                                            <StackPanel Orientation="Horizontal" Margin="0,0,8,2">
                                                <TextBlock FontSize="11" Foreground="#F38BA8"
                                                           Text="{Binding Count, TargetNullValue='1', Mode=OneWay, StringFormat='{}{0}'}"
                                                           VerticalAlignment="Center" Margin="0,0,2,0" />
                                                <Image Source="{Binding Id, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                       Width="16" Height="16" Stretch="Uniform" />
                                            </StackPanel>
                                        </DataTemplate>
                                    </ItemsControl.ItemTemplate>
                                </ItemsControl>
                            </StackPanel>

                            <!-- Removed Symbols -->
                            <StackPanel Margin="0,0,0,6"
                                        Visibility="{Binding Summary.RemovedSymbols.Count, Converter={StaticResource BoolToVis}}">
                                <TextBlock FontSize="11" Foreground="#CBA6F7"
                                           Text="Removed:" Margin="0,0,0,4" />
                                <ItemsControl ItemsSource="{Binding Summary.RemovedSymbols, Mode=OneWay}">
                                    <ItemsControl.ItemsPanel>
                                        <ItemsPanelTemplate><WrapPanel /></ItemsPanelTemplate>
                                    </ItemsControl.ItemsPanel>
                                    <ItemsControl.ItemTemplate>
                                        <DataTemplate>
                                            <StackPanel Orientation="Horizontal" Margin="0,0,8,2">
                                                <TextBlock FontSize="11" Foreground="#CBA6F7"
                                                           Text="{Binding Count, TargetNullValue='1', Mode=OneWay, StringFormat='{}{0}'}"
                                                           VerticalAlignment="Center" Margin="0,0,2,0" />
                                                <Image Source="{Binding Id, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                       Width="16" Height="16" Stretch="Uniform" />
                                            </StackPanel>
                                        </DataTemplate>
                                    </ItemsControl.ItemTemplate>
                                </ItemsControl>
                            </StackPanel>

                            <!-- Fine Print -->
                            <StackPanel Margin="0,0,0,4"
                                        Visibility="{Binding Summary.LandlordFinePrint.Count, Converter={StaticResource BoolToVis}}">
                                <TextBlock FontSize="11" Foreground="#FAB387"
                                           Text="Fine Print:" Margin="0,0,0,4" />
                                <ItemsControl ItemsSource="{Binding Summary.LandlordFinePrint, Mode=OneWay}">
                                    <ItemsControl.ItemTemplate>
                                        <DataTemplate>
                                            <TextBlock FontSize="11" Foreground="#CDD6F4"
                                                       Text="{Binding Description, Mode=OneWay}"
                                                       TextWrapping="Wrap" Margin="0,0,0,2" />
                                        </DataTemplate>
                                    </ItemsControl.ItemTemplate>
                                </ItemsControl>
                            </StackPanel>

                            <!-- Tokens -->
                            <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
                                <TextBlock FontSize="11" Foreground="#6C7086" Margin="0,0,12,0"
                                           Text="{Binding Summary.StatusBar.RerollTokens, Mode=OneWay, StringFormat='Reroll: {}{0}', TargetNullValue='Reroll: 0'}" />
                                <TextBlock FontSize="11" Foreground="#6C7086" Margin="0,0,12,0"
                                           Text="{Binding Summary.StatusBar.RemovalTokens, Mode=OneWay, StringFormat='Removal: {}{0}', TargetNullValue='Removal: 0'}" />
                                <TextBlock FontSize="11" Foreground="#6C7086"
                                           Text="{Binding Summary.StatusBar.EssenceTokens, Mode=OneWay, StringFormat='Essence: {}{0}', TargetNullValue='Essence: 0'}" />
                            </StackPanel>
                        </StackPanel>

                        <!-- Divider -->
                        <GridSplitter Grid.Column="1" Width="4" Background="#2A2540"
                                      HorizontalAlignment="Stretch" VerticalAlignment="Stretch" />

                        <!-- Right: DPT Ranking -->
                        <StackPanel Grid.Column="2">
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                <TextBlock FontSize="13" FontWeight="Bold" Foreground="#89B4FA"
                                           Text="DPT Rank" />
                                <Button Content="鈼€" Click="RankPrev_Click"
                                        Background="Transparent" BorderThickness="0"
                                        Foreground="#6C7086" FontSize="10"
                                        Cursor="Hand" Padding="3,0"
                                        VerticalAlignment="Center" Margin="8,0,0,0" />
                                <Border Background="#313255" CornerRadius="2"
                                        Padding="6,1" Margin="2,0" VerticalAlignment="Center">
                                    <TextBlock FontSize="11" FontWeight="SemiBold"
                                               Foreground="#89B4FA"
                                               Text="{Binding RankModeLabel, Mode=OneWay}" />
                                </Border>
                                <Button Content="鈻? Click="RankNext_Click"
                                        Background="Transparent" BorderThickness="0"
                                        Foreground="#6C7086" FontSize="10"
                                        Cursor="Hand" Padding="3,0"
                                        VerticalAlignment="Center" />
                                <Button Content="?" Margin="6,0,0,0"
                                        Background="#313255" BorderThickness="0"
                                        Foreground="#89B4FA" FontSize="10" FontWeight="Bold"
                                        Cursor="Help" Padding="5,1"
                                        VerticalAlignment="Center">
                                    <Button.ToolTip>
                                        <ToolTip Background="#1E2030" BorderBrush="#45475A"
                                                 BorderThickness="1" Padding="8,6"
                                                 HasDropShadow="True" MaxWidth="280">
                                            <TextBlock FontSize="11" Foreground="#CDD6F4"
                                                       TextWrapping="Wrap">
                                                <Run FontWeight="Bold" Foreground="#89B4FA">Total Value</Run><LineBreak/>
                                                <Run>璇ョ鍙峰湪鍏ㄥ満浜х敓鐨勬€?coins</Run><LineBreak/><LineBreak/>
                                                <Run FontWeight="Bold" Foreground="#89B4FA">DPT (瀹為檯)</Run><LineBreak/>
                                                <Run>total_value / turns_present</Run><LineBreak/>
                                                <Run Foreground="#6C7086">鍚湭涓婂睆鍥炲悎鐨勬瘡 spin 鍧囧€?/Run><LineBreak/><LineBreak/>
                                                <Run FontWeight="Bold" Foreground="#89B4FA">DPT (鏈夋晥)</Run><LineBreak/>
                                                <Run>total_value / turns_contributing</Run><LineBreak/>
                                                <Run Foreground="#6C7086">浠呬笂灞忓洖鍚堢殑姣?spin 鍧囧€?/Run>
                                            </TextBlock>
                                        </ToolTip>
                                    </Button.ToolTip>
                                </Button>
                            </StackPanel>

                            <ItemsControl ItemsSource="{Binding DptRanking, Mode=OneWay}">
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <Grid Margin="0,0,0,4">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="18" />
                                                <ColumnDefinition Width="18" />
                                                <ColumnDefinition Width="*" />
                                            </Grid.ColumnDefinitions>
                                            <!-- Rank number -->
                                            <TextBlock Grid.Column="0" FontSize="10" Foreground="#6C7086"
                                                       Text="{Binding Rank, Mode=OneWay, StringFormat='#{}{0}'}"
                                                       VerticalAlignment="Center" />
                                            <!-- Icon -->
                                            <Image Grid.Column="1"
                                                   Source="{Binding IconId, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                   Width="14" Height="14" Stretch="Uniform"
                                                   VerticalAlignment="Center" />
                                            <!-- Bar -->
                                            <Grid Grid.Column="2" Margin="4,0,0,0"
                                                  ToolTip="{Binding DetailText, Mode=OneWay}">
                                                <Border Background="#2D2D44" CornerRadius="2"
                                                        Height="16" HorizontalAlignment="Stretch" />
                                                <Border Background="#89B4FA" CornerRadius="2"
                                                        Height="16" HorizontalAlignment="Left"
                                                        Width="{Binding BarWidthPx, Mode=OneWay}"
                                                        Opacity="0.7" />
                                                <StackPanel Orientation="Horizontal" Margin="4,0,0,0"
                                                            VerticalAlignment="Center">
                                                    <TextBlock FontSize="10" Foreground="#CDD6F4"
                                                               Text="{Binding Name, Mode=OneWay}"
                                                               Margin="0,0,4,0" />
                                                    <TextBlock FontSize="10" Foreground="#A6E3A1"
                                                               Text="{Binding ValueDisplay, Mode=OneWay}"
                                                               FontWeight="SemiBold" />
                                                </StackPanel>
                                            </Grid>
                                        </Grid>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>
                        </StackPanel>
                    </Grid>
                </Border>

                        <!-- Timeline rounds -->
                        <ItemsControl ItemsSource="{Binding TimelineRounds}">
                            <ItemsControl.ItemTemplate>
                                <DataTemplate>
                                    <Border Background="#252538" CornerRadius="6"
                                            Padding="14,10" Margin="0,0,0,12">
                                        <StackPanel>
                                            <!-- Round header inline: Round 1 馃獧 150/25 -->
                                            <StackPanel Orientation="Horizontal"
                                                        Margin="0,0,0,6">
                                                <TextBlock FontSize="13" FontWeight="Bold"
                                                           Foreground="#89B4FA"
                                                           Text="{Binding RoundIndex, Mode=OneWay, StringFormat='Round {}{0}'}"
                                                           VerticalAlignment="Center" Margin="0,0,6,0" />
                                                <Image Source="{Binding Converter={StaticResource IconImage}, ConverterParameter=coin}"
                                                       Width="16" Height="16"
                                                       VerticalAlignment="Center" Margin="0,0,2,0" />
                                                <TextBlock FontSize="12" VerticalAlignment="Center"
                                                           Foreground="#A6E3A1" FontWeight="SemiBold"
                                                           Text="{Binding CoinsAtRent, Mode=OneWay}" />
                                                <TextBlock FontSize="12" VerticalAlignment="Center"
                                                           Foreground="#6C7086" Text="/" Margin="1,0,1,0" />
                                                <TextBlock FontSize="12" VerticalAlignment="Center"
                                                           Foreground="#F38BA8" FontWeight="SemiBold"
                                                           Text="{Binding RentRequired, Mode=OneWay}" />
                                            </StackPanel>

                                            <!-- Spin cells -->
                                            <ItemsControl ItemsSource="{Binding Spins}">
                                                <ItemsControl.ItemsPanel>
                                                    <ItemsPanelTemplate>
                                                        <WrapPanel />
                                                    </ItemsPanelTemplate>
                                                </ItemsControl.ItemsPanel>
                                                <ItemsControl.ItemTemplate>
                                                    <DataTemplate>
                                                        <Border Background="#2D2D44" CornerRadius="4"
                                                                Padding="6,4" Margin="0,0,6,6"
                                                                Cursor="Hand">
                                                            <Border.ToolTip>
                                                                <ToolTip Background="#1E2030" BorderBrush="#45475A"
                                                                         BorderThickness="1" Padding="8,6"
                                                                         HasDropShadow="True">
                                                                    <ItemsControl ItemsSource="{Binding TooltipActions, Mode=OneWay}">
                                                                        <ItemsControl.ItemTemplate>
                                                                            <DataTemplate>
                                                                                <StackPanel Orientation="Horizontal"
                                                                                            Margin="0,1">
                                                                                    <Image Source="{Binding Icon, Converter={StaticResource IconImage}}"
                                                                                           Width="16" Height="16" Margin="0,0,4,0"
                                                                                           Visibility="{Binding Icon, Converter={StaticResource NullToVis}}"
                                                                                           Stretch="Uniform" />
                                                                                    <TextBlock FontSize="11" Foreground="#CDD6F4"
                                                                                               Text="{Binding Label, Mode=OneWay}"
                                                                                               VerticalAlignment="Center" />
                                                                                </StackPanel>
                                                                            </DataTemplate>
                                                                        </ItemsControl.ItemTemplate>
                                                                    </ItemsControl>
                                                                </ToolTip>
                                                            </Border.ToolTip>
                                                            <StackPanel>
                                                                <TextBlock FontSize="10" Foreground="#6C7086"
                                                                           TextAlignment="Center"
                                                                           Text="{Binding SpinNum, Mode=OneWay, StringFormat='#{}{0}'}" />
                                                                <TextBlock FontSize="10" FontWeight="SemiBold"
                                                                           TextAlignment="Center" Foreground="#A6E3A1"
                                                                           Text="{Binding CoinChangeText, Mode=OneWay}" />
                                                                <!-- Icon images -->
                                                                <ItemsControl ItemsSource="{Binding IconNames, Mode=OneWay}"
                                                                              Margin="0,3,0,0">
                                                                    <ItemsControl.ItemsPanel>
                                                                        <ItemsPanelTemplate>
                                                                            <WrapPanel HorizontalAlignment="Center" />
                                                                        </ItemsPanelTemplate>
                                                                    </ItemsControl.ItemsPanel>
                                                                    <ItemsControl.ItemTemplate>
                                                                        <DataTemplate>
                                                                            <Image Source="{Binding Mode=OneWay, Converter={StaticResource IconImage}}"
                                                                                   Width="18" Height="18"
                                                                                   Margin="1" Stretch="Uniform" />
                                                                        </DataTemplate>
                                                                    </ItemsControl.ItemTemplate>
                                                                </ItemsControl>
                                                            </StackPanel>
                                                        </Border>
                                                    </DataTemplate>
                                                </ItemsControl.ItemTemplate>
                                            </ItemsControl>

                                            <!-- End actions: items with per-icon choice tooltips -->
                                            <Border Visibility="{Binding HasEndActions, Converter={StaticResource BoolToVis}}"
                                                    Background="#2A2540" CornerRadius="4"
                                                    Padding="6,4" Margin="0,4,0,0">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontSize="11" Foreground="#6C7086"
                                                               Text="Items:" VerticalAlignment="Center" Margin="0,0,6,0" />
                                                    <ItemsControl ItemsSource="{Binding EndActionGroups, Mode=OneWay}">
                                                        <ItemsControl.ItemsPanel>
                                                            <ItemsPanelTemplate>
                                                                <WrapPanel />
                                                            </ItemsPanelTemplate>
                                                        </ItemsControl.ItemsPanel>
                                                        <ItemsControl.ItemTemplate>
                                                            <DataTemplate>
                                                                <Image Source="{Binding TookIcon, Mode=OneWay, Converter={StaticResource IconImage}}"
                                                                       Width="18" Height="18" Margin="1"
                                                                       Stretch="Uniform" Cursor="Hand">
                                                                    <Image.ToolTip>
                                                                        <ToolTip Background="#1E2030" BorderBrush="#45475A"
                                                                                 BorderThickness="1" Padding="8,6"
                                                                                 HasDropShadow="True">
                                                                            <ItemsControl ItemsSource="{Binding TooltipActions, Mode=OneWay}">
                                                                                <ItemsControl.ItemTemplate>
                                                                                    <DataTemplate>
                                                                                        <StackPanel Orientation="Horizontal"
                                                                                                    Margin="0,1">
                                                                                            <Image Source="{Binding Icon, Converter={StaticResource IconImage}}"
                                                                                                   Width="16" Height="16" Margin="0,0,4,0"
                                                                                                   Visibility="{Binding Icon, Converter={StaticResource NullToVis}}"
                                                                                                   Stretch="Uniform" />
                                                                                            <TextBlock FontSize="11" Foreground="#CDD6F4"
                                                                                                       Text="{Binding Label, Mode=OneWay}"
                                                                                                       VerticalAlignment="Center" />
                                                                                        </StackPanel>
                                                                                    </DataTemplate>
                                                                                </ItemsControl.ItemTemplate>
                                                                            </ItemsControl>
                                                                        </ToolTip>
                                                                    </Image.ToolTip>
                                                                </Image>
                                                            </DataTemplate>
                                                        </ItemsControl.ItemTemplate>
                                                    </ItemsControl>
                                                </StackPanel>
                                            </Border>
                                        </StackPanel>
                                    </Border>
                                </DataTemplate>
                            </ItemsControl.ItemTemplate>
                        </ItemsControl>

                        <!-- Empty state -->
                        <Border Padding="40"
                                Visibility="{Binding HasData, Converter={StaticResource InvertBoolToVis}}">
                            <StackPanel HorizontalAlignment="Center">
                                <TextBlock FontSize="18" Foreground="#6C7086"
                                           Text="Select a run from the list"
                                           HorizontalAlignment="Center" />
                                <TextBlock FontSize="12" Foreground="#45475A"
                                           Text="History data will appear here"
                                           HorizontalAlignment="Center" Margin="0,8,0,0" />
                            </StackPanel>
                        </Border>
                    </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- Bottom bar -->
        <Border Grid.Row="2" Background="#181825" Padding="12,8"
                BorderBrush="#45475A" BorderThickness="0,1,0,0">
            <TextBlock Text="{Binding StatusText, Mode=OneWay}"
                       FontSize="11" Foreground="#6C7086"
                       VerticalAlignment="Center" />
        </Border>
    </Grid>
</Window>


// ============================================================
// SeedDialog.xaml
// ============================================================
<Window x:Class="Piraeus.BetterLandlord.UI.SeedDialog"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Custom Seed"
        Height="180" Width="360"
        ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen"
        WindowStyle="ToolWindow"
        Background="#1E1E2E"
        ShowInTaskbar="True"
        Topmost="True">

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>

        <!-- Label -->
        <TextBlock Grid.Row="0" Text="Enter seed:"
                   FontSize="12" Foreground="#CDD6F4"
                   Margin="0,0,0,10" />

        <!-- Input with watermark -->
        <Grid Grid.Row="1">
            <TextBox x:Name="SeedInput"
                     FontSize="14"
                     Background="#252538"
                     Foreground="#CDD6F4"
                     BorderBrush="#45475A"
                     BorderThickness="1"
                     Padding="8,6"
                     CaretBrush="#89B4FA"
                     SelectionBrush="#89B4FA"
                     SelectionOpacity="0.3"
                     TextChanged="SeedInput_TextChanged" />
            <TextBlock x:Name="Watermark"
                       Text="random"
                       FontSize="14"
                       Foreground="#6C7086"
                       IsHitTestVisible="False"
                       VerticalAlignment="Center"
                       Margin="11,0,0,0" />
        </Grid>

        <!-- Buttons -->
        <StackPanel Grid.Row="2"
                    Orientation="Horizontal"
                    HorizontalAlignment="Right"
                    VerticalAlignment="Bottom"
                    Margin="0,12,0,0">
            <Button Content="Cancel"
                    Click="Cancel_Click"
                    Width="80" Height="28"
                    Background="#2D2D44"
                    Foreground="#CDD6F4"
                    BorderBrush="#45475A"
                    BorderThickness="1"
                    Cursor="Hand"
                    Margin="0,0,8,0" />
            <Button Content="Confirm"
                    Click="Confirm_Click"
                    Width="80" Height="28"
                    Background="#313255"
                    Foreground="#89B4FA"
                    BorderBrush="#45475A"
                    BorderThickness="1"
                    FontWeight="SemiBold"
                    Cursor="Hand"
                    IsDefault="True" />
        </StackPanel>
    </Grid>
</Window>


// ============================================================
// SeedDialog.xaml.cs
// ============================================================
using System.Windows;
using System.Windows.Input;
using Piraeus.BetterLandlord.UI.Ipc;

namespace Piraeus.BetterLandlord.UI;

public partial class SeedDialog : Window
{
    private readonly UiPipeClient _pipeClient;
    private readonly bool _ownsPipeClient;

    /// <summary>
    /// Create a seed dialog. If pipeClient is null (standalone mode),
    /// creates its own short-lived pipe connection.
    /// </summary>
    public SeedDialog(UiPipeClient? pipeClient = null)
    {
        InitializeComponent();

        if (pipeClient != null)
        {
            _pipeClient = pipeClient;
            _ownsPipeClient = false;
        }
        else
        {
            _pipeClient = new UiPipeClient();
            _ownsPipeClient = true;
        }

        Loaded += (s, e) =>
        {
            Activate();
            SeedInput.Focus();
            Keyboard.Focus(SeedInput);
            Watermark.Visibility = string.IsNullOrEmpty(SeedInput.Text)
                ? Visibility.Visible : Visibility.Collapsed;
        };
    }

    private void SeedInput_TextChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        Watermark.Visibility = string.IsNullOrEmpty(SeedInput.Text)
            ? Visibility.Visible : Visibility.Collapsed;
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }

    private void Confirm_Click(object sender, RoutedEventArgs e)
    {
        var input = SeedInput.Text;
        // O鈫?, I鈫? canonicalization (same as Godot side)
        input = input.Replace('O', '0').Replace('I', '1');

        _pipeClient.SendSetSeed(input);
        DialogResult = true;
        Close();
    }

    protected override void OnClosed(EventArgs e)
    {
        if (_ownsPipeClient)
            _pipeClient.Dispose();
        base.OnClosed(e);
    }
}


// ============================================================
// App.xaml.cs
// ============================================================
using System.Windows;
using System.Windows.Threading;

namespace Piraeus.BetterLandlord.UI;

public partial class App : Application
{
    public static string? DataDir { get; private set; }

    protected override void OnStartup(StartupEventArgs e)
    {
        bool isSeedMode = false;
        for (int i = 0; i < e.Args.Length; i++)
        {
            if (e.Args[i] == "--data-dir" && i + 1 < e.Args.Length)
                DataDir = e.Args[i + 1];
            if (e.Args[i] == "--seed")
                isSeedMode = true;
        }

        base.OnStartup(e);

        DispatcherUnhandledException += (s, args) =>
        {
            MessageBox.Show($"Unhandled UI error:\n\n{args.Exception.Message}\n\n{args.Exception.StackTrace}",
                "Better Landlord 鈥?Error", MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
        };

        AppDomain.CurrentDomain.UnhandledException += (s, args) =>
        {
            var ex = args.ExceptionObject as Exception;
            MessageBox.Show($"Fatal error:\n\n{ex?.ToString() ?? "Unknown"}",
                "Better Landlord 鈥?Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
        };

        TaskScheduler.UnobservedTaskException += (s, args) =>
        {
            MessageBox.Show($"Task error:\n\n{args.Exception.Message}",
                "Better Landlord 鈥?Task Error", MessageBoxButton.OK, MessageBoxImage.Error);
            args.SetObserved();
        };

        if (isSeedMode)
        {
            var dlg = new SeedDialog();
            dlg.ShowDialog();
            Shutdown();
        }
        else
        {
            // WPF stays resident 鈥?closing window hides it, doesn't exit.
            ShutdownMode = ShutdownMode.OnExplicitShutdown;
            var mainWindow = new MainWindow();
            MainWindow = mainWindow;
            mainWindow.ConnectPipe();  // connect pipe + push listener, no Show()
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (MainWindow is MainWindow mw)
            mw.Cleanup();
        base.OnExit(e);
    }
}


// ============================================================
// App.xaml
// ============================================================
<Application x:Class="Piraeus.BetterLandlord.UI.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:local="clr-namespace:Piraeus.BetterLandlord.UI">
    <Application.Resources>

    </Application.Resources>
</Application>



