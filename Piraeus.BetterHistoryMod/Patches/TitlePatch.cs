using GDWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

/// <summary>
/// Title screen hook — no longer touches events or RNG.
///
/// The decision to flush / start_run belongs at action time:
/// - New Game  → TitleSetFloorPatch flushes old events + _bh_start_run + _bh_apply_seed
/// - Continue  → ContinueGamePatch restores RNG, keeps events
///
/// Flushing here would create race conditions: we don't know yet which path
/// the player will take.
/// </summary>
[Patch("res://Main.tscn::1", "title")]
class TitlePatch
{
    // Intentionally empty — title() is no longer a control point for event lifecycle.
}
