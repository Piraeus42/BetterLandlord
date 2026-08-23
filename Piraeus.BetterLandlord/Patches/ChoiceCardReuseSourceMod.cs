using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Warms one fully initialized Card for every currently loaded symbol and item
/// (including essences) while the title screen is active. Each card briefly enters
/// Popup's native choice container for its one-time _ready() initialization, then
/// is removed from the SceneTree and retained only by the cache dictionary. Cards
/// whose presentation depends on live game state are explicitly blacklisted and
/// continue to use the native creation path.
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
            "\t$\"Pop-up Sprite/Pop-up\"._bl_preload_choice_cards()",
        })))
            return originalSource;

        source = source[..titleStart] + title + source[titleEnd..];

        // The cache is intentionally detached from the SceneTree, so it is not
        // covered by normal child teardown. Keep a Main-side fallback in case
        // the process exits without first delivering WM_QUIT_REQUEST.
        if (!source.Contains("func _exit_tree():", StringComparison.Ordinal))
        {
            source += eol + string.Join(eol, new[]
            {
                "",
                "func _exit_tree():",
                "\tvar __bl_choice_popup = get_node_or_null(\"Pop-up Sprite/Pop-up\")",
                "\tif __bl_choice_popup != null and __bl_choice_popup.has_method(\"_bl_choice_card_cache_shutdown\"):",
                "\t\t__bl_choice_popup._bl_choice_card_cache_shutdown()"
            }) + eol;
        }

        return source;
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
            "# Detached Card references only. Cached cards have no parent between offers,",
            "# so their Card/Outline Label subtrees are absent from every SceneTree group.",
            "var _bl_choice_card_cache = {}",
            "# These types render state that can change after title-time preload (offer history",
            "# or item-driven rarity). They must always use a freshly native-created Card.",
            "var _bl_choice_card_cache_blacklist = {",
            "\"symbol_bomb_quantum\": true,",
            "\"rain\": true,",
            "\"comedian\": true,",
            "\"chemical_seven\": true,",
            "\"clubs\": true,",
            "\"diamonds\": true,",
            "\"hearts\": true,",
            "\"spades\": true,",
            "\"void_creature\": true,",
            "\"void_stone\": true,",
            "\"void_fruit\": true",
            "}",
            "# A title() call happens after every run.  The card database is static for the",
            "# process lifetime, so retain a complete detached cache instead of rebuilding it.",
            "var _bl_choice_card_cache_ready = false",
            "# Set once at shutdown; all cleanup entry points are intentionally idempotent.",
            "var _bl_choice_card_cache_shutdown_done = false"
        })))
            return originalSource;

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

        // Keep the saved-card path explicitly scoped inside its native else block.
        // The previous broad trailing-push replacement escaped this else and doubled
        // a three-choice offer into six cards.
        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\t\telse:",
            "\t\t\t\tif database.has(saved_card_types[c]):",
            "\t\t\t\t\tcard.data = database[saved_card_types[c]]",
            "\t\t\t\telif email.type == \"add_tile\":",
            "\t\t\t\t\tcard.data = $\"/root/Main/\".tile_database[\"missing\"]",
            "\t\t\t\telif email.type == \"add_item\":",
            "\t\t\t\t\tcard.data = $\"/root/Main/\".item_database[\"item_missing\"]",
            "\t\t\t\tcards.push_back(card)"
        }), string.Join(eol, new[]
        {
            "\t\t\telse:",
            "\t\t\t\tif database.has(saved_card_types[c]):",
            "\t\t\t\t\tcard.data = database[saved_card_types[c]]",
            "\t\t\t\telif email.type == \"add_tile\":",
            "\t\t\t\t\tcard.data = $\"/root/Main/\".tile_database[\"missing\"]",
            "\t\t\t\telif email.type == \"add_item\":",
            "\t\t\t\t\tcard.data = $\"/root/Main/\".item_database[\"item_missing\"]",
            "\t\t\t\tcard = _bl_take_or_mark_choice_card(card)",
            "\t\t\t\tcards.push_back(card)"
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

        // Replace only the native loop so the cache release stays composable with
        // the surrounding popup lifecycle.
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
            "\tcard.set_process_input(false)",
            "\tif $\"/root/Main\".selected_node == card:",
            "\t\t$\"/root/Main\".selected_node = null",
            "",
            "func _bl_disconnect_choice_card_orphan_cleanup(node):",
            "\t# Card.tscn and several nested UI scenes subscribe to Utils.freeing_orphans.",
            "\t# A cached choice card is intentionally detached, so unregister the entire",
            "\t# subtree before detaching it; explicit cache eviction still queue_frees it.",
            "\tif node.has_method(\"_free_if_orphaned\") and Utils.is_connected(\"freeing_orphans\", node, \"_free_if_orphaned\"):",
            "\t\tUtils.disconnect(\"freeing_orphans\", node, \"_free_if_orphaned\")",
            "\tfor child in node.get_children():",
            "\t\t_bl_disconnect_choice_card_orphan_cleanup(child)",
            "",
            "func _bl_activate_choice_card(card):",
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
            "\t# Nested Card scenes infer setup from this exact native parent path.",
            "\t# Run _ready() in the real choice container once, then detach the finished subtree.",
            "\tcontainer.add_child(card)",
            "\t_bl_disconnect_choice_card_orphan_cleanup(card)",
            "\tcontainer.remove_child(card)",
            "\t_bl_park_choice_card(card)",
            "\treturn card",
            "",
            "func _bl_store_choice_card(card):",
            "\tvar cache_key = str(card.get_meta(\"__bl_choice_card_cache_key\"))",
            "\tif not _bl_choice_card_cache.has(cache_key):",
            "\t\t_bl_choice_card_cache[cache_key] = []",
            "\t_bl_choice_card_cache[cache_key].push_back(card)",
            "",
            "func _bl_destroy_cached_choice_card(card):",
            "\tif not is_instance_valid(card):",
            "\t\treturn",
            "\t# Cached cards intentionally bypass freeing_orphans; disconnect that",
            "\t# callback before destroying the complete detached subtree.",
            "\t_bl_disconnect_choice_card_orphan_cleanup(card)",
            "\tvar parent = card.get_parent()",
            "\tif parent != null:",
            "\t\tparent.remove_child(card)",
            "\t# This is used only for cache eviction/shutdown. Synchronous free is",
            "\t# required because a detached node may never reach a SceneTree frame.",
            "\tcard.free()",
            "",
            "func _bl_clear_choice_card_cache():",
            "\tfor cache_key in _bl_choice_card_cache.keys():",
            "\t\tfor card in _bl_choice_card_cache[cache_key]:",
            "\t\t\t_bl_destroy_cached_choice_card(card)",
            "\t_bl_choice_card_cache.clear()",
            "",
            "func _bl_choice_card_cache_shutdown():",
            "\tif _bl_choice_card_cache_shutdown_done:",
            "\t\treturn",
            "\t_bl_choice_card_cache_shutdown_done = true",
            "\t# Move any currently displayed poolable cards into the same explicit",
            "\t# destruction path; non-poolable cards retain native queue_free behavior.",
            "\t_bl_release_choice_cards()",
            "\t_bl_clear_choice_card_cache()",
            "",
            "func _bl_preload_choice_cards():",
            "\tif _bl_choice_card_cache_shutdown_done:",
            "\t\treturn",
            "\t# A completed cache survives title() transitions.  Only active offer cards need",
            "\t# returning to it here; rebuilding 395 fully initialized Cards would block the",
            "\t# Return to Main Menu click for seconds.",
            "\t_bl_release_choice_cards()",
            "\tif _bl_choice_card_cache_ready:",
            "\t\treturn",
            "\t# Cards must be initialized under Container: nested Icon scenes inspect that path.",
            "\t# They are removed again before the title screen becomes interactive.",
            "\t_bl_clear_choice_card_cache()",
            "\tfor card_type in $\"/root/Main\".tile_database.keys():",
            "\t\tvar card_data = $\"/root/Main\".tile_database[card_type]",
            "\t\tif typeof(card_data) == TYPE_DICTIONARY and card_data.has(\"type\") and not _bl_is_choice_card_cache_blacklisted(card_data):",
            "\t\t\tvar cache_key = _bl_choice_card_key(false, card_data.type)",
            "\t\t\t_bl_choice_card_cache[cache_key] = [_bl_create_warmed_choice_card(false, card_data)]",
            "\tfor card_type in $\"/root/Main\".item_database.keys():",
            "\t\tvar card_data = $\"/root/Main\".item_database[card_type]",
            "\t\tif typeof(card_data) == TYPE_DICTIONARY and card_data.has(\"type\") and not _bl_is_choice_card_cache_blacklisted(card_data):",
            "\t\t\tvar cache_key = _bl_choice_card_key(true, card_data.type)",
            "\t\t\t_bl_choice_card_cache[cache_key] = [_bl_create_warmed_choice_card(true, card_data)]",
            "\t_bl_choice_card_cache_ready = true",

            "",
            "func _bl_is_choice_card_cache_blacklisted(card_data):",
            "\treturn typeof(card_data) != TYPE_DICTIONARY or not card_data.has(\"type\") or _bl_choice_card_cache_blacklist.has(str(card_data.type))",
            "",
            "func _bl_take_or_mark_choice_card(card):",
            "\tif card == null or _bl_is_choice_card_cache_blacklisted(card.data):",
            "\t\treturn card",
            "\tvar cache_key = _bl_choice_card_key(card.item, card.data.type)",
            "\tif _bl_choice_card_cache.has(cache_key) and _bl_choice_card_cache[cache_key].size() > 0:",
            "\t\tvar cached_card = _bl_choice_card_cache[cache_key].pop_back()",
            "\t\tcard.queue_free()",
            "\t\treturn _bl_activate_choice_card(cached_card)",
            "\t# A duplicate offer type can consume the one warmed instance. The native fallback",
            "\t# will initialize normally, then becomes a detached spare after its offer closes.",
            "\tcard.set_meta(\"__bl_choice_card_poolable\", true)",
            "\tcard.set_meta(\"__bl_choice_card_cache_key\", cache_key)",
            "\treturn card",
            "",
            "func _bl_release_choice_cards():",
            "\tfor card in cards:",
            "\t\tif card.has_meta(\"__bl_choice_card_poolable\") and bool(card.get_meta(\"__bl_choice_card_poolable\")):",
            "\t\t\t_bl_disconnect_choice_card_orphan_cleanup(card)",
            "\t\t\tvar parent = card.get_parent()",
            "\t\t\tif parent != null:",
            "\t\t\t\tparent.remove_child(card)",
            "\t\t\t_bl_park_choice_card(card)",
            "\t\t\t_bl_store_choice_card(card)",
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
