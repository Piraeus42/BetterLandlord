using SlotWeave.Scripting;

namespace Piraeus.BetterHistoryMod.Patches;

[Patch("res://Main.tscn::1", "write_log")]
class WriteLogPatch
{
    [Prefix]
    static string PrefixCode() => GdscriptUtil.TabifyIndent("""
        if $"/root/Main".has_method("_bh_add_event") and typeof(string) != TYPE_NIL:
            if string.begins_with("Destroyed item - "):
                var _name = string.trim_prefix("Destroyed item - ")
                var _comma = _name.find(",")
                if _comma != -1:
                    _name = _name.substr(0, _comma)
                $"/root/Main"._bh_add_event("item_destroyed", {"item": _name})
            elif string.begins_with("Added item: "):
                var _name2 = string.trim_prefix("Added item: ")
                # Skip if _bh_record_choice already emitted this item
                if $"/root/Main"._bh_just_recorded_item == _name2:
                    $"/root/Main"._bh_just_recorded_item = ''
                else:
                    $"/root/Main"._bh_add_event("item_added", {"item": _name2, "source": "shop"})
            elif string.begins_with("Coin total is now "):
                var _coin_str = string.trim_prefix("Coin total is now ")
                _coin_str = _coin_str.trim_suffix(" after spinning")
                var _ct = 0.0
                if _coin_str.is_valid_float():
                    _ct = float(_coin_str)
                elif _coin_str.is_valid_integer():
                    _ct = float(_coin_str)
                $"/root/Main"._bh_add_event("spin_end", {"coin_total": _ct})
            elif string == "VICTORY":
                $"/root/Main"._bh_end_run("victory")
            elif string == "GAME OVER":
                $"/root/Main"._bh_end_run("loss")
        """);
}
