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

    private readonly HistoryStore _store;
    private readonly string _userDataDir;
    private readonly string _uiExePath;
    private readonly ILogger _logger;
    private readonly CancellationTokenSource _cts = new();
    private Thread? _serverThread;
    private Thread? _pushThread;
    private Process? _uiProcess;
    private IntPtr _jobHandle;
    private SeedSignalReader? _seedReader;

    // ── Convergence state ──
    // Reader (game thread) updates pending via Interlocked.Exchange.
    // PushLoop (single thread) compares with acked, sends if different,
    // advances acked only on successful Write+Flush.
    private long _pendingSeedSeq;
    private long _ackedSeedSeq;
    private long _pendingHistorySeq;
    private long _ackedHistorySeq;
    private readonly AutoResetEvent _pushWake = new(false);

    public SeedSignalReader SeedReader => _seedReader ??= new SeedSignalReader();

    public GamePipeServer(HistoryStore store, string userDataDir, string modDir, ILogger logger)
    {
        _store = store;
        _userDataDir = userDataDir;
        _uiExePath = Path.Combine(modDir, UiExeName);
        _logger = logger.ForContext("SourceContext", "GamePipe");
    }

    public void Start()
    {
        // 1. Request-response pipe
        _serverThread = new Thread(ServerLoop)
        {
            Name = "BH-PipeServer",
            IsBackground = true
        };
        _serverThread.Start();

        // 2. Single-thread push pipe — all Writes here, no concurrency
        _pushThread = new Thread(PushLoop)
        {
            Name = "BH-PushServer",
            IsBackground = true
        };
        _pushThread.Start();

        // 3. Wire reader callbacks — these run on game thread, must be non-blocking
        SeedReader.OnSeedSeq = SignalSeedSeq;
        SeedReader.OnHistorySeq = SignalHistorySeq;

        // 4. Pre-launch WPF so cold-start is hidden behind menu navigation
        LaunchUiProcess();

        _logger.Information("[PipeServer] Started (single-thread push + convergence model)");
    }

    // ---- Reader callbacks (game thread) — zero I/O, zero blocking ----

    private void SignalSeedSeq(long seq)
    {
        Interlocked.Exchange(ref _pendingSeedSeq, seq);
        _pushWake.Set();
    }

    private void SignalHistorySeq(long seq)
    {
        Interlocked.Exchange(ref _pendingHistorySeq, seq);
        _pushWake.Set();
    }

    // ---- Push pipe (single sender thread) — all Writes serialized here ----

    private void PushLoop()
    {
        while (!_cts.IsCancellationRequested)
        {
            NamedPipeServerStream? server = null;
            try
            {
                server = new NamedPipeServerStream(PushPipeName, PipeDirection.Out, 1,
                    PipeTransmissionMode.Byte, PipeOptions.None);

                _logger.Information("[Push] Waiting for WPF...");
                server.WaitForConnection();
                _logger.Information("[Push] WPF connected");

                // Convergence loop: pending != acked → send, advance acked on success.
                // This is a natural re-transmit: if WPF disconnects/reconnects,
                // acked resets to 0 while pending stays → auto-resend.
                while (!_cts.IsCancellationRequested && server.IsConnected)
                {
                    bool sent = false;

                    long ps = Interlocked.Read(ref _pendingSeedSeq);
                    if (ps != _ackedSeedSeq)
                    {
                        if (TryWrite(server, "{\"type\":\"seed_request\"}"))
                        {
                            _ackedSeedSeq = ps;
                            _logger.Information("[Push] seed_request delivered (seq={Seq})", ps);
                            sent = true;
                        }
                        else break; // Write failed → WPF disconnected
                    }

                    long ph = Interlocked.Read(ref _pendingHistorySeq);
                    if (ph != _ackedHistorySeq)
                    {
                        if (TryWrite(server, "{\"type\":\"show_history\"}"))
                        {
                            _ackedHistorySeq = ph;
                            _logger.Information("[Push] show_history delivered (seq={Seq})", ph);
                            sent = true;
                        }
                        else break;
                    }

                    // Wake on new signal, or 250ms timeout (periodic health check)
                    _pushWake.WaitOne(sent ? 100 : 250);
                }
            }
            catch (OperationCanceledException) { break; }
            catch (IOException ex)
            {
                _logger.Information("[Push] Connection ended: {Msg}", ex.Message);
            }
            catch (Exception ex)
            {
                _logger.Error(ex, "[Push] Error");
            }
            finally
            {
                try { server?.Dispose(); } catch { }
            }

            // Brief pause before re-listening (WPF restart grace period)
            if (!_cts.IsCancellationRequested)
            {
                try { _pushWake.WaitOne(200); }
                catch { break; }
            }
        }
    }

    private static bool TryWrite(NamedPipeServerStream s, string msg)
    {
        try
        {
            var b = Encoding.UTF8.GetBytes(msg + "\n");
            s.Write(b, 0, b.Length);
            s.Flush();
            return true;
        }
        catch { return false; }
    }

    // ---- WPF process management ----

    private void LaunchUiProcess()
    {
        try
        {
            // ── Clean up any existing WPF processes ──
            // MainWindowHandle is unreliable in our architecture — the WPF window
            // is hidden most of the time, so Handle==0 is normal, not a zombie signal.
            // Always kill any existing instance to guarantee a clean, fresh start.
            var exeName = Path.GetFileNameWithoutExtension(UiExeName);
            foreach (var p in Process.GetProcessesByName(exeName))
            {
                try { _logger.Information("[PipeServer] Killing previous UI PID={Pid}", p.Id); p.Kill(); p.WaitForExit(3000); }
                catch { }
            }

            // Dispose our own tracked reference if any
            if (_uiProcess != null)
            {
                try { _uiProcess.Dispose(); } catch { }
                _uiProcess = null;
            }

            if (!File.Exists(_uiExePath))
            {
                _logger.Warning("[PipeServer] UI exe missing at {Path}", _uiExePath);
                return;
            }

            // ── Create Job Object for auto-kill on parent exit ──
            if (_jobHandle == IntPtr.Zero)
                _jobHandle = JobObjectHelper.CreateKillOnCloseJob();

            // ── Launch fresh instance ──
            _uiProcess = Process.Start(new ProcessStartInfo
            {
                FileName = _uiExePath,
                Arguments = $"--data-dir \"{_userDataDir}\"",
                UseShellExecute = false,
                CreateNoWindow = false
            });

            if (_uiProcess != null)
            {
                JobObjectHelper.AssignProcess(_jobHandle, _uiProcess);
                _logger.Information("[PipeServer] Launched UI PID={Pid} (job-bound)", _uiProcess.Id);
            }
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
                            var seedJson = JsonSerializer.Serialize(
                                new { type = seedType, input = setSeed.Input,
                                    updated_at = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss") });
                            // Atomic write: write to .tmp then rename.
                            // Prevents GDScript from reading a half-written file (→ flash OFF).
                            var tmp = seedPath + ".tmp";
                            File.WriteAllText(tmp, seedJson, Encoding.UTF8);
                            File.Move(tmp, seedPath, overwrite: true);
                            _logger.Information("[PipeServer] Seed saved: {Seed}", setSeed.Input);
                            // No push — GDScript Timer polls seed_config.json independently.
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
            var runsDir = Path.Combine(_store.HistoryDir, "runs");
            foreach (var e in manifestEntries.Entries)
            {
                manifestSet.Add(e.RunId);
                // Read mutable fields from actual JSON — a run can change after
                // manifest was built (e.g. "quit" → "loss" after Continue).
                var endedBy = e.EndedBy;
                var floor = e.Floor;
                var finalCoins = e.FinalCoins;
                var totalSpins = e.TotalSpins;
                try
                {
                    var path = Path.Combine(runsDir, $"{e.RunId}.json");
                    if (File.Exists(path))
                    {
                        var json = File.ReadAllText(path);
                        using var doc = JsonDocument.Parse(json);
                        var meta = doc.RootElement.TryGetProperty("meta", out var m) ? m : default;
                        if (meta.ValueKind != default)
                        {
                            endedBy = meta.TryGetProperty("ended_by", out var eb) && eb.ValueKind != System.Text.Json.JsonValueKind.Null ? eb.GetString() ?? e.EndedBy : e.EndedBy;
                            if (meta.TryGetProperty("floor", out var fl) && fl.ValueKind != System.Text.Json.JsonValueKind.Null)
                                floor = fl.GetInt32();
                            if (meta.TryGetProperty("final_coins", out var fc))
                                finalCoins = fc.GetInt64();
                            if (meta.TryGetProperty("total_spins", out var ts))
                                totalSpins = ts.GetInt32();
                        }
                    }
                }
                catch { } // stale JSON → keep manifest values
                items.Add(new RunListItem
                {
                    RunId = e.RunId,
                    RunNumber = e.RunNumber,
                    EndedBy = endedBy,
                    Floor = floor,
                    FinalCoins = finalCoins,
                    TotalSpins = totalSpins,
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
        // Unwire reader — prevents ghost triggers during GDScript reload
        if (_seedReader != null)
        {
            _seedReader.OnSeedSeq = null;
            _seedReader.OnHistorySeq = null;
        }
        _cts.Cancel();
        _pushWake.Set();  // Wake push thread so it exits cleanly

        // ── Kill WPF process (graceful-path cleanup) ──
        if (_uiProcess != null && !_uiProcess.HasExited)
        {
            try { _uiProcess.Kill(); _uiProcess.WaitForExit(2000); }
            catch { }
        }
        _uiProcess?.Dispose();

        // ── Close Job Object → OS auto-kills any remaining assigned processes ──
        // This is the safety net: if Kill above didn't work, or Dispose itself
        // wasn't called (crash), the Job handle closing kills everything assigned.
        JobObjectHelper.CloseJob(_jobHandle);

        _cts.Dispose();
    }
}
