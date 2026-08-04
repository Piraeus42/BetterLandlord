using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Fine-grained raw timers for native operations that can grow with board,
/// item, and saved-value state. The Main helper records every invocation.
/// </summary>
[Patch("res://Main.tscn::4", "add_tile")]
class ProfileMainAddTilePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_main_add_tile_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_main_add_tile_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_main_add_tile_start_us >= 0:
            $"/root/Main"._bh_profile_record("reels.add_tile", __bh_prof_main_add_tile_start_us, {"requested_count": t.size()})
        """);
}

[Patch("res://Main.tscn::4", "update_icon_types")]
class ProfileUpdateIconTypesPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_update_icon_types_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_update_icon_types_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_update_icon_types_start_us >= 0:
            $"/root/Main"._bh_profile_record("reels.update_icon_types", __bh_prof_update_icon_types_start_us)
        """);
}

[Patch("res://Main.tscn::4", "check_effects")]
class ProfileCheckEffectsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_check_effects_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_check_effects_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_check_effects_start_us >= 0:
            $"/root/Main"._bh_profile_record("reels.check_effects", __bh_prof_check_effects_start_us)
        """);
}

[Patch("res://Reel.tscn::1", "add_tile")]
class ProfileReelAddTilePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_reel_add_tile_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_reel_add_tile_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_reel_add_tile_start_us >= 0:
            $"/root/Main"._bh_profile_record("reel.add_tile", __bh_prof_reel_add_tile_start_us, {"requested_count": t.size(), "reel": reel_num})
        """);
}

[Patch("res://Slot Icon.tscn::1", "change_type")]
class ProfileSlotIconChangeTypePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_change_type_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_change_type_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_change_type_start_us >= 0:
            $"/root/Main"._bh_profile_record("slot_icon.change_type", __bh_prof_change_type_start_us, {"type": str(p_type), "need_conditional_effects": need_cond_effects, "reel": grid_position.x, "row": grid_position.y})
        """);
}

[Patch("res://Slot Icon.tscn::1", "check_conditional_effects")]
class ProfileSlotIconCheckConditionalEffectsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_slot_check_conditional_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_slot_check_conditional_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_slot_check_conditional_start_us >= 0:
            $"/root/Main"._bh_profile_record("slot_icon.check_conditional_effects", __bh_prof_slot_check_conditional_start_us, {"symbol": str(type), "effects": c_effects.size()})
        """);
}

[Patch("res://Slot Icon.tscn::1", "add_conditional_effects")]
class ProfileSlotIconAddConditionalEffectsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_slot_add_conditional_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_slot_add_conditional_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_slot_add_conditional_start_us >= 0:
            $"/root/Main"._bh_profile_record("slot_icon.add_conditional_effects", __bh_prof_slot_add_conditional_start_us, {"symbol": str(type)})
        """);
}

[Patch("res://Item.tscn::1", "check_conditional_effects")]
class ProfileItemCheckConditionalEffectsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_item_check_conditional_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_item_check_conditional_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_item_check_conditional_start_us >= 0:
            $"/root/Main"._bh_profile_record("item.check_conditional_effects", __bh_prof_item_check_conditional_start_us, {"item": str(type)})
        """);
}

[Patch("res://Item.tscn::1", "add_conditional_effects")]
class ProfileItemAddConditionalEffectsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_item_add_conditional_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_item_add_conditional_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_item_add_conditional_start_us >= 0:
            $"/root/Main"._bh_profile_record("item.add_conditional_effects", __bh_prof_item_add_conditional_start_us, {"item": str(type)})
        """);
}



[Patch("res://Main.tscn::1", "new_game")]
class ProfileNewGamePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_new_game_start_us = -1
        if has_method("_bh_profile_record"):
            _bh_profile_schedule_flush()
            _bh_profile_begin("new_game", "new_game")
            __bh_prof_new_game_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_new_game_start_us >= 0:
            _bh_profile_record("main.new_game", __bh_prof_new_game_start_us)
            _bh_profile_schedule_flush()
            _bh_profile_end()
        """);
}

[Patch("res://Main.tscn::1", "continue_game")]
class ProfileContinueGamePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_continue_game_start_us = -1
        if has_method("_bh_profile_record"):
            _bh_profile_begin("continue_game", "continue_game")
            __bh_prof_continue_game_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_continue_game_start_us >= 0:
            _bh_profile_record("main.continue_game", __bh_prof_continue_game_start_us)
            _bh_profile_schedule_flush()
            _bh_profile_end()
        """);
}

[Patch("res://Main.tscn::1", "load_data")]
class ProfileLoadDataPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_load_data_start_us = -1
        if has_method("_bh_profile_record"):
            __bh_prof_load_data_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_load_data_start_us >= 0:
            _bh_profile_record("main.load_data", __bh_prof_load_data_start_us, {"save_ids": save_ids, "load_saved_ids": load_saved_ids, "past_init": past_init})
        """);
}
