using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Profiles the parts of a popup resolution that remain outside the reel and
/// icon hooks. These samples share the active popup.resolve_event context.
/// </summary>
[Patch("res://Pop-up.tscn::1", "add_event")]
class ProfilePopupAddEventPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_add_event_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_add_event_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_add_event_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.event_queue", __bh_prof_popup_add_event_start_us, {"key": str(key), "emails_after": emails.size()})
        """);
}

[Patch("res://Pop-up.tscn::1", "check_spend_triggers")]
class ProfilePopupSpendTriggersPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_spend_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_spend_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_spend_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.check_spend_triggers", __bh_prof_popup_spend_start_us, {"effect_type": str(effect_type)})
        """);
}

[Patch("res://Pop-up.tscn::1", "remove")]
class ProfilePopupRemovePatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_remove_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_remove_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_remove_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.remove", __bh_prof_popup_remove_start_us, {"emails_after": emails.size()})
        """);
}

[Patch("res://Pop-up.tscn::1", "display")]
class ProfilePopupDisplayPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_display_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_display_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_display_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.display", __bh_prof_popup_display_start_us, {"emails_after": emails.size()})
        """);
}


[Patch("res://Pop-up.tscn::1", "add_buttons")]
class ProfilePopupAddButtonsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_add_buttons_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_add_buttons_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_add_buttons_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.display.add_buttons", __bh_prof_popup_add_buttons_start_us, {"email_type": str(emails[0].type), "buttons_after": buttons.size()})
        """);
}

[Patch("res://Pop-up.tscn::1", "add_cards")]
class ProfilePopupAddCardsPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_add_cards_start_us = -1
        var __bh_prof_popup_add_cards_before = cards.size()
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_add_cards_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_add_cards_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.display.add_cards", __bh_prof_popup_add_cards_start_us, {"email_type": str(emails[0].type), "cards_before": __bh_prof_popup_add_cards_before, "cards_after": cards.size(), "symbols_to_choose_from": symbols_to_choose_from, "items_to_choose_from": items_to_choose_from})
        """);
}

[Patch("res://Pop-up.tscn::1", "draw")]
class ProfilePopupDrawPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_popup_draw_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_popup_draw_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_popup_draw_start_us >= 0:
            $"/root/Main"._bh_profile_record("popup.display.draw", __bh_prof_popup_draw_start_us, {"email_type": str(emails[0].type), "card_count": cards.size(), "button_count": buttons.size(), "prompt": emails[0].prompt})
        """);
}

[Patch("res://Items.tscn::1", "add_item")]
class ProfileItemsAddItemPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_items_add_item_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_items_add_item_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_items_add_item_start_us >= 0:
            $"/root/Main"._bh_profile_record("items.add_item", __bh_prof_items_add_item_start_us, {"item": str(p_type), "items_after": items.size()})
        """);
}

[Patch("res://Main.tscn::1", "save_log")]
class ProfileMainSaveLogPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_save_log_start_us = -1
        if has_method("_bh_profile_record"):
            __bh_prof_save_log_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_save_log_start_us >= 0:
            _bh_profile_record("main.save_log", __bh_prof_save_log_start_us)
        """);
}

[Patch("res://Main.tscn::1", "change_current_menu_path")]
class ProfileMainChangeMenuPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_change_menu_start_us = -1
        if has_method("_bh_profile_record"):
            __bh_prof_change_menu_start_us = OS.get_ticks_usec()
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_change_menu_start_us >= 0:
            _bh_profile_record("main.change_current_menu_path", __bh_prof_change_menu_start_us, {"path": str(path)})
        """);
}
