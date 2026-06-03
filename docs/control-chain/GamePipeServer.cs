using System.Diagnostics;
using System.IO.Pipes;
using System.Text;
using System.Text.Json;
using Piraeus.BetterHistoryMod.Storage;
using ILogger = Serilog.ILogger;

namespace Piraeus.BetterHistoryMod.Ipc;

public class GamePipeServer : IDisposable
{
    private const string PipeName = "Piraeus.BetterHistoryMod.Pipe";
    private const string PushPipeName = "Piraeus.BetterHistoryMod.Push";
    private const string UiExeName = "Piraeus.BetterHistory.UI.exe";
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

        // 2. Push pipe — WPF connects and keeps connection open
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

    // ---- Push pipe (server → WPF, persistent) ----

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
