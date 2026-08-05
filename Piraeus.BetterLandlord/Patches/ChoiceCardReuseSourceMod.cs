using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Warms one fully initialized Card for every currently loaded symbol and item
/// (including essences) while the title screen is active. Ordinary three-card
/// symbol/item offers then reparent those finished controls instead of running
/// Card._ready(), text construction, and layout on the reroll input path.
/// </summary>
public sealed class ChoiceCardReuseSourceMod : ISourceMod
{
    private const string PopupPath = "res://Pop-up.tscn::1";
    private const string MainPath = "res://Main.tscn::1";

    public bool ShouldRun(string path) => path is PopupPath or MainPath;

    public string Modify(string path, string source) => path switch
    {
        PopupPath => ModifyPopup(source),
        MainPath => ModifyMain(source),
        _ => source
    };

    private static string ModifyMain(string source)
    {
        if (source.Contains("_bl_preload_choice_cards()", StringComparison.Ordinal))
            return source;

        var originalSource = source;
        var eol = GetEol(source);
        var titleStart = source.IndexOf("func title():", StringComparison.Ordinal);
        var titleEnd = titleStart < 0
            ? -1
            : source.IndexOf(eol + "func reset_values():", titleStart, StringComparison.Ordinal);
        if (titleStart < 0 || titleEnd < 0)
            return originalSource;

        var title = source.Substring(titleStart, titleEnd - titleStart);
        if (!Replace(ref title, "\tload_data(true, false, true)", string.Join(eol, new[]
        {
            "\tload_data(true, false, true)",
            "\t# Database loading is complete here. Warm the complete current mod/base card set",
            "\t# before the title frame becomes interactive, never during a choice or reroll.",
            "\tvar __bl_choice_preload_start_us = -1",
            "\tif has_method(\"_bh_profile_record\"): ",
            "\t\t__bl_choice_preload_start_us = OS.get_ticks_usec()",
            "\t$\"Pop-up Sprite/Pop-up\"._bl_preload_choice_cards()",
            "\tif __bl_choice_preload_start_us >= 0:",
            "\t\t_bh_profile_record(\"popup.choice_card_cache.preload\", __bl_choice_preload_start_us, {\"symbols\": tile_database.size(), \"items_including_essences\": item_database.size()})"
        })))
            return originalSource;

        return source[..titleStart] + title + source[titleEnd..];
    }

    private static string ModifyPopup(string source)
    {
        if (source.Contains("func _bl_preload_choice_cards():", StringComparison.Ordinal))
            return source;

        var originalSource = source;
        var eol = GetEol(source);

        if (!Replace(ref source, "var cards = []", string.Join(eol, new[]
        {
            "var cards = []",
            "# All cached controls remain under this Popup, so Card._free_if_orphaned",
            "# never treats a card between offers as an orphan.",
            "var _bl_choice_card_cache = {}",
            "var _bl_choice_card_cache_host = null"
        })))
            return originalSource;

        // AddCardsProfileSourceMod runs before this source mod.  It retains the
        // native lightweight instance timing while this patch swaps the completed
        // candidate for a title-warmed Card before update_card_positions().
        var addCardsStart = source.IndexOf("func add_cards(f_rarities):", StringComparison.Ordinal);
        var addCardsEnd = addCardsStart < 0
            ? -1
            : source.IndexOf(eol + "func update_card_positions():", addCardsStart, StringComparison.Ordinal);
        if (addCardsStart < 0 || addCardsEnd < 0)
            return originalSource;

        var addCards = source.Substring(addCardsStart, addCardsEnd - addCardsStart);
        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\t\t\tif stcf <= 3:",
            "\t\t\t\t\tif rarity != null and card_pool.has(rarity):",
            "\t\t\t\t\t\tcard_pool[rarity].erase(card.data.type)",
            "\t\t\t\t\tsaved_card_types.push_back(card.data.type)",
            "\t\t\t\t\tcards.push_back(card)"
        }), string.Join(eol, new[]
        {
            "\t\t\t\tif stcf <= 3:",
            "\t\t\t\t\tcard = _bl_take_or_mark_choice_card(card)",
            "\t\t\t\t\tif rarity != null and card_pool.has(rarity):",
            "\t\t\t\t\t\tcard_pool[rarity].erase(card.data.type)",
            "\t\t\t\t\tsaved_card_types.push_back(card.data.type)",
            "\t\t\t\t\tcards.push_back(card)"
        })))
            return originalSource;

        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\t\t\telif email.type == \"add_item\":",
            "\t\t\t\t\tcard.data = $\"/root/Main/\".item_database[\"item_missing\"]",
            "\t\t\t\tcards.push_back(card)"
        }), string.Join(eol, new[]
        {
            "\t\t\t\telif email.type == \"add_item\":",
            "\t\t\t\t\tcard.data = $\"/root/Main/\".item_database[\"item_missing\"]",
            "\t\t\tif stcf <= 3:",
            "\t\t\t\tcard = _bl_take_or_mark_choice_card(card)",
            "\t\t\tcards.push_back(card)"
        })))
            return originalSource;

        source = source[..addCardsStart] + addCards + source[addCardsEnd..];

        var positionsStart = source.IndexOf("func update_card_positions():", StringComparison.Ordinal);
        var positionsEnd = positionsStart < 0
            ? -1
            : source.IndexOf(eol + "func draw():", positionsStart, StringComparison.Ordinal);
        if (positionsStart < 0 || positionsEnd < 0)
            return originalSource;

        var positions = source.Substring(positionsStart, positionsEnd - positionsStart);
        if (!Replace(ref positions, "\t\tcontainer.add_child(c)", string.Join(eol, new[]
        {
            "\t\tif c.get_parent() != null:",
            "\t\t\tc.get_parent().remove_child(c)",
            "\t\tcontainer.add_child(c)"
        })))
            return originalSource;
        source = source[..positionsStart] + positions + source[positionsEnd..];

        if (!Replace(ref source, string.Join(eol, new[]
        {
            "\tfor c in cards:",
            "\t\tc.queue_free()",
            "\t\tcontainer.remove_child(c)",
            "\tcards.clear()"
        }), "\t_bl_release_choice_cards()"))
            return originalSource;

        // ResolveEventProfileSourceMod inserts its own span between the native
        // queue_free loop and cards.clear().  Replace only the loop so this
        // stays composable; its later cards.clear() is harmless after release.
        var resolveStart = source.IndexOf("func resolve_event(", StringComparison.Ordinal);
        if (resolveStart < 0)
            return originalSource;
        var resolve = source[resolveStart..];
        if (!Replace(ref resolve, string.Join(eol, new[]
        {
            "\t\tfor c in cards:",
            "\t\t\tc.queue_free()"
        }), "\t\t_bl_release_choice_cards()"))
            return originalSource;
        source = source[..resolveStart] + resolve;

        var functions = string.Join(eol, new[]
        {
            "",
            "func _bl_choice_card_key(is_item, card_type):",
            "\treturn (\"item:\" if is_item else \"symbol:\") + str(card_type)",
            "",
            "func _bl_get_choice_card_cache_host():",
            "\tif _bl_choice_card_cache_host == null:",
            "\t\t_bl_choice_card_cache_host = Node.new()",
            "\t\t_bl_choice_card_cache_host.name = \"BL Choice Card Cache\"",
            "\t\tadd_child(_bl_choice_card_cache_host)",
            "\treturn _bl_choice_card_cache_host",
            "",
            "func _bl_park_choice_card(card):",
            "\tcard.active = false",
            "\tcard.hovering = false",
            "\tcard.selectable = false",
            "\tcard.off_screen = false",
            "\tcard.held = false",
            "\tcard.delay = 0",
            "\tcard.r_x_mod = 0",
            "\tcard.rect_position = Vector2(0, 0)",
            "\tcard.visible = false",
            "\t# Invisible controls still receive Main's Update-group dispatch and _input.",
            "\t# Parked cards must be completely detached from both paths.",
            "\tcard.set_process_input(false)",
            "\tcard.remove_from_group(\"Selectable\")",
            "\tcard.remove_from_group(\"Update\")",
            "\tif $\"/root/Main\".selected_node == card:",
            "\t\t$\"/root/Main\".selected_node = null",
            "",
            "func _bl_activate_choice_card(card):",
            "\tif not card.is_in_group(\"Selectable\"):",
            "\t\tcard.add_to_group(\"Selectable\")",
            "\tif not card.is_in_group(\"Update\"):",
            "\t\tcard.add_to_group(\"Update\")",
            "\tcard.set_process_input(true)",
            "\tcard.visible = true",
            "\treturn card",
            "",
            "func _bl_create_warmed_choice_card(is_item, card_data):",
            "\tvar card = preload(\"res://Card.tscn\").instance()",
            "\tcard.item = is_item",
            "\tcard.data = card_data",
            "\tcard.set_meta(\"__bl_choice_card_poolable\", true)",
            "\tcard.set_meta(\"__bl_choice_card_cache_key\", _bl_choice_card_key(is_item, card_data.type))",
            "\t# _ready() executes once while data/item are already bound, then the card is parked.",
            "\t_bl_get_choice_card_cache_host().add_child(card)",
            "\t_bl_park_choice_card(card)",
            "\treturn card",
            "",
            "func _bl_clear_choice_card_cache():",
            "\tfor cache_key in _bl_choice_card_cache.keys():",
            "\t\tfor card in _bl_choice_card_cache[cache_key]:",
            "\t\t\tif is_instance_valid(card):",
            "\t\t\t\tcard.queue_free()",
            "\t_bl_choice_card_cache.clear()",
            "",
            "func _bl_preload_choice_cards():",
            "\t# title() calls this after load_data(), so this includes enabled mod cards as",
            "\t# well as all base symbols, regular items, and every Essence in item_database.",
            "\t_bl_release_choice_cards()",
            "\t_bl_clear_choice_card_cache()",
            "\tfor card_type in $\"/root/Main\".tile_database.keys():",
            "\t\tvar card_data = $\"/root/Main\".tile_database[card_type]",
            "\t\tif typeof(card_data) == TYPE_DICTIONARY and card_data.has(\"type\"):",
            "\t\t\tvar cache_key = _bl_choice_card_key(false, card_data.type)",
            "\t\t\t_bl_choice_card_cache[cache_key] = [_bl_create_warmed_choice_card(false, card_data)]",
            "\tfor card_type in $\"/root/Main\".item_database.keys():",
            "\t\tvar card_data = $\"/root/Main\".item_database[card_type]",
            "\t\tif typeof(card_data) == TYPE_DICTIONARY and card_data.has(\"type\"):",
            "\t\t\tvar cache_key = _bl_choice_card_key(true, card_data.type)",
            "\t\t\t_bl_choice_card_cache[cache_key] = [_bl_create_warmed_choice_card(true, card_data)]",
            "",
            "func _bl_take_or_mark_choice_card(card):",
            "\tif card == null or not card.data.has(\"type\"):",
            "\t\treturn card",
            "\tvar cache_key = _bl_choice_card_key(card.item, card.data.type)",
            "\tif _bl_choice_card_cache.has(cache_key) and _bl_choice_card_cache[cache_key].size() > 0:",
            "\t\tvar cached_card = _bl_choice_card_cache[cache_key].pop_back()",
            "\t\tcard.queue_free()",
            "\t\treturn _bl_activate_choice_card(cached_card)",
            "\t# A duplicate offer type can consume the one prewarmed instance. The native",
            "\t# fallback is initialized once, then retained as a spare for future offers.",
            "\tcard.set_meta(\"__bl_choice_card_poolable\", true)",
            "\tcard.set_meta(\"__bl_choice_card_cache_key\", cache_key)",
            "\treturn card",
            "",
            "func _bl_release_choice_cards():",
            "\tfor card in cards:",
            "\t\tif card.has_meta(\"__bl_choice_card_poolable\") and bool(card.get_meta(\"__bl_choice_card_poolable\")):",
            "\t\t\t_bl_park_choice_card(card)",
            "\t\t\tvar parent = card.get_parent()",
            "\t\t\tif parent != null:",
            "\t\t\t\tparent.remove_child(card)",
            "\t\t\t_bl_get_choice_card_cache_host().add_child(card)",
            "\t\t\tvar cache_key = str(card.get_meta(\"__bl_choice_card_cache_key\"))",
            "\t\t\tif not _bl_choice_card_cache.has(cache_key):",
            "\t\t\t\t_bl_choice_card_cache[cache_key] = []",
            "\t\t\t_bl_choice_card_cache[cache_key].push_back(card)",
            "\t\telse:",
            "\t\t\tcard.queue_free()",
            "\tcards.clear()"
        });

        return source + eol + functions + eol;
    }

    private static bool Replace(ref string source, string original, string replacement)
    {
        var index = source.IndexOf(original, StringComparison.Ordinal);
        if (index < 0)
            return false;

        source = source[..index] + replacement + source[(index + original.Length)..];
        return true;
    }

    private static string GetEol(string source) => source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
}
