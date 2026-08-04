using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

[Patch("res://Pop-up.tscn::1", "resolve_event")]
class ResolveEventPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        var __bh_prof_resolve_event_start_us = -1
        var __bh_prof_resolve_event_type = ''
        var __bh_prof_resolve_event_choice = '' if choice == null else str(choice)
        if emails.size() > 0:
            __bh_prof_resolve_event_type = str(emails[0].type)
        var __bh_prof_event_capture_start_us = -1
        if $"/root/Main".has_method("_bh_profile_record"):
            __bh_prof_resolve_event_start_us = OS.get_ticks_usec()
            var __bh_prof_resolve_event_phase = 'popup'
            if __bh_prof_resolve_event_type == 'add_tile':
                __bh_prof_resolve_event_phase = 'pick_symbol'
            elif __bh_prof_resolve_event_type == 'add_item':
                __bh_prof_resolve_event_phase = 'pick_item'
            $"/root/Main"._bh_profile_begin(__bh_prof_resolve_event_phase, __bh_prof_resolve_event_type, __bh_prof_resolve_event_choice)
            __bh_prof_event_capture_start_us = OS.get_ticks_usec()
        if emails.size() > 0 and $"/root/Main".has_method("_bh_add_event"):
            var _type = emails[0].type
            if _type == "game_over" or _type == "out_of_money":
                $"/root/Main"._bh_end_run("loss")
            elif _type == "win" or _type == "ending":
                $"/root/Main"._bh_end_run("victory")
            if cards.size() > 0:
                var _presented = []
                for _c in cards:
                    if _c.get("data") != null:
                        var _d = _c.data
                        var _entry = {}
                        if _d.has("type"):
                            _entry["type"] = str(_d.type)
                        else:
                            _entry["type"] = "unknown"
                        if _d.has("rarity"):
                            _entry["rarity"] = str(_d.rarity)
                        else:
                            _entry["rarity"] = "unknown"
                        _entry["is_item"] = false
                        if _c.has("item"):
                            _entry["is_item"] = _c.item
                        _presented.append(_entry)
                if _presented.size() > 0:
                    $"/root/Main"._bh_record_cards(_presented, _type)
            if _type == "add_tile" or _type == "add_item":
                if choice != null and choice != "dont":
                    if choice == "skip":
                        $"/root/Main"._bh_record_skip()
                    elif choice == "reroll_pay":
                        pass
                    else:
                        $"/root/Main"._bh_record_choice(choice)
        if __bh_prof_event_capture_start_us >= 0:
            $"/root/Main"._bh_profile_record("mod.resolve_event_capture", __bh_prof_event_capture_start_us, {"cards": cards.size(), "emails": emails.size(), "event_type": __bh_prof_resolve_event_type})
        """);

    [Postfix]
    static string PostfixCode() => GdscriptUtil.TabifyIndent("""
        if __bh_prof_resolve_event_start_us >= 0 and $"/root/Main".has_method("_bh_profile_record"):
            $"/root/Main"._bh_profile_record("popup.resolve_event", __bh_prof_resolve_event_start_us, {"email_type": __bh_prof_resolve_event_type, "choice": __bh_prof_resolve_event_choice})
            $"/root/Main"._bh_profile_schedule_flush()
            $"/root/Main"._bh_profile_end()
        """);
}
