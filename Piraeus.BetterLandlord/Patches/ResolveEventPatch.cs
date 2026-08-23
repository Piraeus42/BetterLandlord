using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

[Patch("res://Pop-up.tscn::1", "resolve_event")]
class ResolveEventPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
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
        """);
}
