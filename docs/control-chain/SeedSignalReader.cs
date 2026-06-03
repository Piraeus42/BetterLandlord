using GDWeave.GameState;
using GDWeave.NativeInterop;

namespace Piraeus.BetterHistoryMod.Ipc;

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
