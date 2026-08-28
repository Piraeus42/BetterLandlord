using SlotWeave.Scripting;

namespace Piraeus.BetterLandlord.Patches;

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
                # A destruction line is the reliable signal that a one-shot
                # item/essence was actually consumed. Passive effects are not
                # recorded as usage events.
                if _name.ends_with("_essence"):
                    $"/root/Main"._bh_add_event("essence_triggered", {"item": _name, "source": "consumed"})
                else:
                    $"/root/Main"._bh_add_event("item_used", {"item": _name, "source": "consumed"})
            elif string.find("item_to_destroy:") != -1:
                # Essence consumption caused by a symbol effect is logged as an
                # Effect line rather than as "Destroyed item - ...". Extract
                # the field so essence activations are not silently lost.
                var _marker = "item_to_destroy:"
                var _start = string.find(_marker) + _marker.length()
                var _name3 = string.substr(_start).strip_edges()
                var _comma3 = _name3.find(",")
                var _brace3 = _name3.find("}")
                if _brace3 != -1 and (_comma3 == -1 or _brace3 < _comma3):
                    _comma3 = _brace3
                if _comma3 != -1:
                    _name3 = _name3.substr(0, _comma3)
                _name3 = _name3.strip_edges()
                if _name3 != "" and _name3 != "null":
                    $"/root/Main"._bh_add_event("item_destroyed", {"item": _name3, "source": "effect"})
                    $"/root/Main"._bh_add_event("essence_triggered", {"item": _name3, "source": "effect"})
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
