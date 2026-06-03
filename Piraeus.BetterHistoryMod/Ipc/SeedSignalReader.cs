using GDWeave.GameState;
using GDWeave.NativeInterop;

namespace Piraeus.BetterHistoryMod.Ipc;

/// <summary>
/// GameStateBus reader: reads monotonic counters from Title node every frame.
/// Fires OnSeedSeq / OnHistorySeq when value changes to non-zero.
///
/// The counters are NOT advanced here — GamePipeServer.PushLoop advances
/// the acked side only after successful delivery.  This gives us convergence:
/// GDScript increments → reader fires → push thread sends → acked.
/// If push fails, pending != acked next loop and it retries automatically.
/// </summary>
public class SeedSignalReader : IGameStateReader
{
    private long _prevSeedSeq;
    private long _prevHistorySeq;

    // Fired on game main thread — subscribers must be non-blocking (just Interlocked.Exchange + Set).
    public Action<long>? OnSeedSeq;
    public Action<long>? OnHistorySeq;

    public void Read(EngineObjectReader reader, IntPtr sceneTree, GameStateSnapshot snap)
    {
        var node = reader.FindNode("Main/Title");
        if (node == IntPtr.Zero) return;

        long seedSeq = ReadLongProp(node, "_bh_seed_request_seq");
        long histSeq = ReadLongProp(node, "_bh_history_request_seq");

        // Only fire on change; ignore 0 to survive GDScript reload (variables reset to 0).
        if (seedSeq != _prevSeedSeq)
        {
            _prevSeedSeq = seedSeq;
            if (seedSeq > 0) OnSeedSeq?.Invoke(seedSeq);
        }

        if (histSeq != _prevHistorySeq)
        {
            _prevHistorySeq = histSeq;
            if (histSeq > 0) OnHistorySeq?.Invoke(histSeq);
        }
    }

    private static long ReadLongProp(IntPtr node, string name)
    {
        var v = EngineObjectReader.ReadScriptProp(node, name);
        return v switch
        {
            long l => l,
            int i => i,
            _ => 0
        };
    }
}
