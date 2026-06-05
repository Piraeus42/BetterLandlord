using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Text.Json;

namespace Piraeus.BetterLandlord.UI.Ipc;

/// <summary>
/// Named Pipe client — request-response + push notifications.
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

    /// <summary>Persistent connection to push pipe — receives server-initiated messages.</summary>
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

                // Read loop — one line per push message
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
