using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Warms one fully initialized Card for every currently loaded symbol and item
/// (including essences) while the title screen is active. Cached cards remain under
/// an invisible Popup-owned in-tree cache host between offers. Parked subtrees are
/// removed from user scheduling groups, preserving SceneTree/root-path semantics
/// without contributing hidden per-frame UI work.
/// </summary>
public sealed class ChoiceCardReuseSourceMod : ISourceMod
{
    private const string PopupPath = "res://Pop-up.tscn::1";
    private const string MainPath = "res://Main.tscn::1";
    private const string CardPath = "res://Card.tscn::1";
    private const string EffectTextPath = "res://Effect Text.tscn::1";

    public bool ShouldRun(string path) => path is PopupPath or MainPath or CardPath or EffectTextPath;

    public string Modify(string path, string source) => path switch
    {
        PopupPath => ModifyPopup(source),
        MainPath => ModifyMain(source),
        CardPath => ModifyCard(source),
        EffectTextPath => ModifyEffectText(source),
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
            "\t\t_bh_profile_record(\"popup.choice_card_cache.preload\", __bl_choice_preload_start_us, {\"symbols\": tile_database.size(), \"items_including_essences\": item_database.size(), \"storage\": \"in_tree_hidden\"})"
        })))
            return originalSource;

        source = source[..titleStart] + title + source[titleEnd..];

        // Do not invoke Popup cleanup from Main._exit_tree(): by then Main and Popup
        // are already outside the active SceneTree, while Card code still resolves
        // absolute /root/Main paths. Window-close cleanup runs earlier through the
        // notification hook; ordinary scene teardown frees the in-tree cache naturally.

        return source;
    }

    private static string ModifyEffectText(string source)
    {
        const string nativeRemoval = "\tremove_from_group(\"Pause Update\")";
        const string guardedRemoval = "\tif is_in_group(\"Pause Update\"):\n\t\tremove_from_group(\"Pause Update\")";
        if (source.Contains(guardedRemoval, StringComparison.Ordinal))
            return source;

        // Title-time card warming instantiates Effect Text labels that are never
        // enrolled in Pause Update. Godot 3 logs an engine error when the native
        // unconditional removal is applied to those labels. Guarding the removal
        // preserves the behavior for real enrolled labels and keeps cache preload
        // log-clean without suppressing lifecycle errors elsewhere.
        return source.Replace(nativeRemoval, guardedRemoval, StringComparison.Ordinal);
    }
    private static string ModifyCard(string source)
    {
        if (source.Contains("func _bl_refresh_choice_card_presentation():", StringComparison.Ordinal))
            return source;

        var eol = GetEol(source);
        var readyStart = source.IndexOf("func _ready():", StringComparison.Ordinal);
        var readyEnd = readyStart < 0
            ? -1
            : source.IndexOf(eol + "func set_icon_size():", readyStart, StringComparison.Ordinal);
        if (readyStart < 0 || readyEnd < 0)
            return source;

        var refreshedReady = string.Join(eol, new[]
        {
            "func _ready():",
            "\t_bl_refresh_choice_card_presentation()",
            "",
            "# This is intentionally safe to call again when a title-warmed Card is",
            "# rebound to the current offer data. It contains the native display-only",
            "# initialization from _ready(), without re-running node lifecycle hooks.",
            "func _bl_refresh_choice_card_presentation():",
            "\tset_icon_size()",
            "\tif item:",
            "\t\tbackground.color = $\"/root/Main/Options Sprite/Options\".colors3[\"item_background\"]",
            "\telse:",
            "\t\tbackground.color = $\"/root/Main/Options Sprite/Options\".colors3[\"symbol_background\"]",
            "\tset_card_size()",
            "\tbackground.get_node(\"Title\").force_update = true",
            "\tbackground.get_node(\"Title\").update()",
            "\tset_icon_size()",
            "\tset_card_size()",
            ""
        });
        return source[..readyStart] + refreshedReady + source[readyEnd..];
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
            "# Cached Cards stay under an invisible Popup-owned Node, never detached from the",
            "# active SceneTree. This preserves Card/Tooltip root-path and orphan semantics.",
            "var _bl_choice_card_cache = {}",
            "var _bl_choice_card_cache_host = null",
            "# A title() call happens after every run. The card database is static for the",
            "# process lifetime, so retain a complete in-tree cache instead of rebuilding it.",
            "var _bl_choice_card_cache_ready = false",
            "# Set once at shutdown; all cleanup entry points are intentionally idempotent.",
            "var _bl_choice_card_cache_shutdown_done = false"
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
            "\t\tcontainer.add_child(c)",
            "\t\t_bl_activate_choice_card(c)"
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
        // queue_free loop and cards.clear(). Replace only the loop so this stays
        // composable; its later cards.clear() is harmless after release.
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
            "\tif _bl_choice_card_cache_host != null and is_instance_valid(_bl_choice_card_cache_host):",
            "\t\treturn _bl_choice_card_cache_host",
            "\t_bl_choice_card_cache_host = Node.new()",
            "\t_bl_choice_card_cache_host.name = \"BetterLandlord Choice Card Cache\"",
            "\tadd_child(_bl_choice_card_cache_host)",
            "\treturn _bl_choice_card_cache_host",
            "",
            "func _bl_suspend_choice_card_subtree(node):",
            "\t# A hidden in-tree node is still returned by Main's global group scans. Preserve",
            "\t# its exact runtime scheduler state, then remove every user group so a parked",
            "\t# Card behaves like the old detached cache without losing SceneTree semantics.",
            "\tfor child in node.get_children():",
            "\t\t_bl_suspend_choice_card_subtree(child)",
            "\tif node.has_meta(\"__bl_choice_card_suspend_state\"):",
            "\t\treturn",
            "\tvar groups = []",
            "\tfor group_name in node.get_groups():",
            "\t\t# Leading-underscore groups are Godot engine internals, not game scheduling.",
            "\t\tif not str(group_name).begins_with(\"_\"): ",
            "\t\t\tgroups.push_back(group_name)",
            "\tvar state = {\"groups\": groups, \"process\": node.is_processing(), \"physics_process\": node.is_physics_processing(), \"input\": node.is_processing_input(), \"unhandled_input\": node.is_processing_unhandled_input(), \"unhandled_key_input\": node.is_processing_unhandled_key_input()}",
            "\tnode.set_meta(\"__bl_choice_card_suspend_state\", state)",
            "\tfor group_name in groups:",
            "\t\tnode.remove_from_group(group_name)",
            "\tnode.set_process(false)",
            "\tnode.set_physics_process(false)",
            "\tnode.set_process_input(false)",
            "\tnode.set_process_unhandled_input(false)",
            "\tnode.set_process_unhandled_key_input(false)",
            "",
            "func _bl_resume_choice_card_subtree(node):",
            "\tif node.has_meta(\"__bl_choice_card_suspend_state\"):",
            "\t\tvar state = node.get_meta(\"__bl_choice_card_suspend_state\")",
            "\t\tfor group_name in state[\"groups\"]:",
            "\t\t\tnode.add_to_group(group_name)",
            "\t\tnode.set_process(state[\"process\"])",
            "\t\tnode.set_physics_process(state[\"physics_process\"])",
            "\t\tnode.set_process_input(state[\"input\"])",
            "\t\tnode.set_process_unhandled_input(state[\"unhandled_input\"])",
            "\t\tnode.set_process_unhandled_key_input(state[\"unhandled_key_input\"])",
            "\t\tnode.remove_meta(\"__bl_choice_card_suspend_state\")",
            "\tfor child in node.get_children():",
            "\t\t_bl_resume_choice_card_subtree(child)",
            "",
            "func _bl_park_choice_card(card):",
            "\tcard.active = false",
            "\tcard.hovering = false",
            "\tcard.selectable = false",
            "\tcard.off_screen = false",
            "\tcard.held = false",
            "\tcard.delay = 0",
            "\tcard.r_x_mod = 0",
            "\tcard.extra_height = 0",
            "\tcard.cant_go_dirs.clear()",
            "\tcard.selector_alignment = \"card\"",
            "\tcard.rect_position = Vector2(0, 0)",
            "\tcard.visible = false",
            "\tif $\"/root/Main\".selected_node == card:",
            "\t\t$\"/root/Main\".selected_node = null",
            "\t_bl_suspend_choice_card_subtree(card)",
            "",
            "func _bl_move_choice_card_to_cache_host(card):",
            "\t# Suspend before reparenting so the cache host never contributes a frame of",
            "\t# global group work. The Card remains inside the active SceneTree throughout.",
            "\t_bl_park_choice_card(card)",
            "\tvar cache_host = _bl_get_choice_card_cache_host()",
            "\tvar parent = card.get_parent()",
            "\tif parent != cache_host:",
            "\t\tif parent != null:",
            "\t\t\tparent.remove_child(card)",
            "\t\tcache_host.add_child(card)",
            "",
            "func _bl_activate_choice_card(card):",
            "\t# Activation happens only after update_card_positions() reparents this Card to",
            "\t# Popup's native Container. Native fallback cards have no suspend snapshot.",
            "\tif not card.has_meta(\"__bl_choice_card_suspend_state\"):",
            "\t\treturn card",
            "\t_bl_resume_choice_card_subtree(card)",
            "\tcard.visible = true",
            "\treturn card",
            "",
            "func _bl_bind_warmed_choice_card(cached_card, source_card):",
            "\t# The native candidate contains this offer's current runtime data. Type is only",
            "\t# a pool lookup key: it is not a complete presentation identity.",
            "\tcached_card.item = source_card.item",
            "\tcached_card.data = source_card.data",
            "\tcached_card._bl_refresh_choice_card_presentation()",
            "\t# Keep the rebound Card quiescent until it has been reparented to Container.",
            "\t# This also suspends any future presentation child created during refresh.",
            "\t_bl_suspend_choice_card_subtree(cached_card)",
            "\treturn cached_card",
            "",
            "func _bl_create_warmed_choice_card(is_item, card_data):",
            "\tvar card = preload(\"res://Card.tscn\").instance()",
            "\tcard.item = is_item",
            "\tcard.data = card_data",
            "\tcard.set_meta(\"__bl_choice_card_poolable\", true)",
            "\tcard.set_meta(\"__bl_choice_card_cache_key\", _bl_choice_card_key(is_item, card_data.type))",
            "\t# Nested Card scenes infer setup from this exact native parent path. Run the",
            "\t# one-time lifecycle setup there, then keep the completed subtree in-tree.",
            "\tcontainer.add_child(card)",
            "\t_bl_move_choice_card_to_cache_host(card)",
            "\treturn card",
            "",
            "func _bl_store_choice_card(card):",
            "\tvar cache_key = str(card.get_meta(\"__bl_choice_card_cache_key\"))",
            "\tif not _bl_choice_card_cache.has(cache_key):",
            "\t\t_bl_choice_card_cache[cache_key] = []",
            "\t_bl_choice_card_cache[cache_key].push_back(card)",
            "",
            "func _bl_destroy_cached_choice_card(card):",
            "\tif is_instance_valid(card):",
            "\t\t# The card is still inside the active tree; free it directly without creating",
            "\t\t# an orphan interval or bypassing its normal group/lifecycle bookkeeping.",
            "\t\tcard.free()",
            "",
            "func _bl_clear_choice_card_cache():",
            "\tfor cache_key in _bl_choice_card_cache.keys():",
            "\t\tfor card in _bl_choice_card_cache[cache_key]:",
            "\t\t\t_bl_destroy_cached_choice_card(card)",
            "\t_bl_choice_card_cache.clear()",
            "\tif _bl_choice_card_cache_host != null and is_instance_valid(_bl_choice_card_cache_host):",
            "\t\t_bl_choice_card_cache_host.free()",
            "\t_bl_choice_card_cache_host = null",
            "",
            "func _bl_choice_card_cache_shutdown():",
            "\tif _bl_choice_card_cache_shutdown_done:",
            "\t\treturn",
            "\t_bl_choice_card_cache_shutdown_done = true",
            "\t_bl_release_choice_cards()",
            "\t_bl_clear_choice_card_cache()",
            "",
            "func _bl_preload_choice_cards():",
            "\tif _bl_choice_card_cache_shutdown_done:",
            "\t\treturn",
            "\t# A completed cache survives title() transitions. Only active offer cards need",
            "\t# returning to it here; rebuilding fully initialized Cards would block title().",
            "\t_bl_release_choice_cards()",
            "\tif _bl_choice_card_cache_ready:",
            "\t\treturn",
            "\t_bl_get_choice_card_cache_host()",
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
            "\t_bl_choice_card_cache_ready = true",
            "",
            "func _bl_take_or_mark_choice_card(card):",
            "\tif card == null or not card.data.has(\"type\"):",
            "\t\treturn card",
            "\tvar cache_key = _bl_choice_card_key(card.item, card.data.type)",
            "\tif _bl_choice_card_cache.has(cache_key) and _bl_choice_card_cache[cache_key].size() > 0:",
            "\t\tvar cached_card = _bl_choice_card_cache[cache_key].pop_back()",
            "\t\tvar rebound_card = _bl_bind_warmed_choice_card(cached_card, card)",
            "\t\tcard.queue_free()",
            "\t\treturn rebound_card",
            "\t# A duplicate offer type can consume the one warmed instance. The native fallback",
            "\t# initializes normally, then is retained in the in-tree cache after its offer closes.",
            "\tcard.set_meta(\"__bl_choice_card_poolable\", true)",
            "\tcard.set_meta(\"__bl_choice_card_cache_key\", cache_key)",
            "\treturn card",
            "",
            "func _bl_release_choice_cards():",
            "\tfor card in cards:",
            "\t\tif card.has_meta(\"__bl_choice_card_poolable\") and bool(card.get_meta(\"__bl_choice_card_poolable\")):",
            "\t\t\t_bl_move_choice_card_to_cache_host(card)",
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
