using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Hooks Pop-up.update_rent_values() to capture the ACTUAL rent values
/// (including floor-dependent additions and modded floor overrides)
/// into the event stream that _bh_flush() uses to build history.
/// </summary>
[Patch("res://Pop-up.tscn::1", "update_rent_values")]
class RentUpdatePatch
{
    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main".has_method("_bh_add_event"):
            $"/root/Main"._bh_add_event('rent_updated', {
                'rent_0': rent_values[0],
                'rent_1': rent_values[1],
                'times_rent_paid': times_rent_paid,
                'floor': current_floor
            })
        """);
}
