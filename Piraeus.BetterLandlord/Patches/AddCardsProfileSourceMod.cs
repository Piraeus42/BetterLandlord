using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Adds behavior-neutral, source-level timing spans to the synchronous work
/// performed by Pop-up.add_cards().  The game only presents the next frame
/// after this method returns, so candidate preparation, card construction,
/// persistence, and scene-tree attachment are measured separately.
/// </summary>
public class AddCardsProfileSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Pop-up.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("__bh_prof_add_cards_pool_start_us", StringComparison.Ordinal))
            return source;

        var eol = source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
        const string functionStart = "func add_cards(f_rarities):";
        var start = source.IndexOf(functionStart, StringComparison.Ordinal);
        var end = start < 0
            ? -1
            : source.IndexOf(eol + "func update_card_positions():", start, StringComparison.Ordinal);
        if (start < 0 || end < 0)
            return source;

        // Restrict every replacement to add_cards()/update_card_positions().
        // Several equivalent save/add_child snippets exist in other popup
        // flows, where the local variables below would not be valid.
        var addCards = source.Substring(start, end - start);

        // Attribute patches may have inserted their total timer immediately
        // after the function declaration. Anchor after the original local
        // declaration instead of assuming it is the first statement.
        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\tvar database",
            "\t",
            "\tif not visible and (symbols_to_choose_from != cards.size() or symbols_to_choose_from == 0):"
        }), string.Join(eol, new[]
        {
            "\tvar database",
            "\tvar __bh_prof_add_cards_cards_before = cards.size()",
            "\tvar __bh_prof_add_cards_trigger = \"reroll\" if has_meta('__bh_prof_reroll_start_us') else \"initial_or_normal\"",
            "\tvar __bh_prof_add_cards_reroll_id = int(get_meta('__bh_prof_reroll_id')) if has_meta('__bh_prof_reroll_start_us') and has_meta('__bh_prof_reroll_id') else 0",
            "\tvar __bh_prof_add_cards_pool_start_us = -1",
            "\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t__bh_prof_add_cards_pool_start_us = OS.get_ticks_usec()",
            "\t",
            "\tif not visible and (symbols_to_choose_from != cards.size() or symbols_to_choose_from == 0):"
        })))
            return source;

        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\tfor r in c_tbe.keys():",
            "\t\t\tfor c in c_tbe[r]:",
            "\t\t\t\tcard_pool[r].erase(c)",
            "\t\tif email.type == \"add_tile\":"
        }), string.Join(eol, new[]
        {
            "\t\tfor r in c_tbe.keys():",
            "\t\t\tfor c in c_tbe[r]:",
            "\t\t\t\tcard_pool[r].erase(c)",
            "\t\tif __bh_prof_add_cards_pool_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.pool_prepare\", __bh_prof_add_cards_pool_start_us, {\"email_type\": str(email.type), \"cards_before\": __bh_prof_add_cards_cards_before, \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\tvar __bh_prof_add_cards_offer_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_add_cards_offer_start_us = OS.get_ticks_usec()",
            "\t\tif email.type == \"add_tile\":"
        })))
            return source;

        // Special >3-choice flows redirect to a prompt and do not construct
        // Card scenes here. Record that branch before preserving its return.
        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\t\tdelay_timer = 0",
            "\t\t\tf_rar[\"push_front\"] = true",
            "\t\t\tadd_event(\"add_tile_prompt\", f_rar)",
            "\t\t\treturn"
        }), string.Join(eol, new[]
        {
            "\t\t\tdelay_timer = 0",
            "\t\t\tf_rar[\"push_front\"] = true",
            "\t\t\tadd_event(\"add_tile_prompt\", f_rar)",
            "\t\t\tif __bh_prof_add_cards_offer_start_us >= 0:",
            "\t\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.offer_setup\", __bh_prof_add_cards_offer_start_us, {\"email_type\": str(email.type), \"candidate_count\": symbols_to_choose_from, \"prompt_redirect\": true, \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\t\treturn"
        })))
            return source;

        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\t\tdelay_timer = 0",
            "\t\t\tf_rar[\"push_front\"] = true",
            "\t\t\tadd_event(\"add_item_prompt\", f_rar)",
            "\t\t\treturn"
        }), string.Join(eol, new[]
        {
            "\t\t\tdelay_timer = 0",
            "\t\t\tf_rar[\"push_front\"] = true",
            "\t\t\tadd_event(\"add_item_prompt\", f_rar)",
            "\t\t\tif __bh_prof_add_cards_offer_start_us >= 0:",
            "\t\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.offer_setup\", __bh_prof_add_cards_offer_start_us, {\"email_type\": str(email.type), \"candidate_count\": items_to_choose_from, \"prompt_redirect\": true, \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\t\treturn"
        })))
            return source;

        // ChoiceRngSourceMod can insert its event marker between stcf and the
        // candidate loop. Insert immediately after stcf has its final value,
        // so this remains valid regardless of source-mod execution order.
        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\telse:",
            "\t\t\tstcf = symbols_to_choose_from",
            "\t\t"
        }), string.Join(eol, new[]
        {
            "\t\telse:",
            "\t\t\tstcf = symbols_to_choose_from",
            "\t\tif __bh_prof_add_cards_offer_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.offer_setup\", __bh_prof_add_cards_offer_start_us, {\"email_type\": str(email.type), \"candidate_count\": stcf, \"prompt_redirect\": false, \"saved_card_count\": saved_card_types.size(), \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\tvar __bh_prof_add_cards_candidates_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_add_cards_candidates_start_us = OS.get_ticks_usec()",
            "\t\t"
        })))
            return source;

        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\t\tif stcf <= 3:",
            "\t\t\t\tcard = preload(\"res://Card.tscn\").instance()",
            "\t\t\t\tif email.type == \"add_item\":"
        }), string.Join(eol, new[]
        {
            "\t\t\tif stcf <= 3:",
            "\t\t\t\tvar __bh_prof_add_cards_instance_start_us = -1",
            "\t\t\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t\t\t__bh_prof_add_cards_instance_start_us = OS.get_ticks_usec()",
            "\t\t\t\tcard = preload(\"res://Card.tscn\").instance()",
            "\t\t\t\tif __bh_prof_add_cards_instance_start_us >= 0:",
            "\t\t\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.card_instance\", __bh_prof_add_cards_instance_start_us, {\"email_type\": str(email.type), \"candidate_index\": c, \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\t\t\tif email.type == \"add_item\":"
        })))
            return source;

        if (!Replace(ref addCards, string.Join(eol, new[]
        {
            "\t\tif typeof(email.extra_values) == TYPE_DICTIONARY:",
            "\t\t\temail.extra_values[\"loaded_data\"] = true",
            "\t\t$\"/root/Main\".save_game()",
            "\t\tupdate_card_positions()",
            "\t\tcard_pool.clear()"
        }), string.Join(eol, new[]
        {
            "\t\tif __bh_prof_add_cards_candidates_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.candidate_build\", __bh_prof_add_cards_candidates_start_us, {\"email_type\": str(email.type), \"candidate_count\": stcf, \"cards_after\": cards.size(), \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\tif typeof(email.extra_values) == TYPE_DICTIONARY:",
            "\t\t\temail.extra_values[\"loaded_data\"] = true",
            "\t\tvar __bh_prof_add_cards_save_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_add_cards_save_start_us = OS.get_ticks_usec()",
            "\t\t$\"/root/Main\".save_game()",
            "\t\tif __bh_prof_add_cards_save_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.save_game\", __bh_prof_add_cards_save_start_us, {\"email_type\": str(email.type), \"cards_after\": cards.size(), \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\tvar __bh_prof_add_cards_layout_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_add_cards_layout_start_us = OS.get_ticks_usec()",
            "\t\tupdate_card_positions()",
            "\t\tif __bh_prof_add_cards_layout_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.layout_total\", __bh_prof_add_cards_layout_start_us, {\"email_type\": str(email.type), \"cards_after\": cards.size(), \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\tcard_pool.clear()"
        })))
            return source;

        var modified = source[..start] + addCards + source[end..];
        var positionsStart = modified.IndexOf("func update_card_positions():", StringComparison.Ordinal);
        var positionsEnd = positionsStart < 0
            ? -1
            : modified.IndexOf(eol + "func draw():", positionsStart, StringComparison.Ordinal);
        if (positionsStart < 0 || positionsEnd < 0)
            return source;

        var positions = modified.Substring(positionsStart, positionsEnd - positionsStart);
        if (!Replace(ref positions, string.Join(eol, new[]
        {
            "\tfor c in cards:",
            "\t\tcontainer.add_child(c)",
            "\t\ttotal_card_width += c.border.rect_size.x"
        }), string.Join(eol, new[]
        {
            "\tfor c in cards:",
            "\t\tvar __bh_prof_add_cards_attach_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_add_cards_attach_start_us = OS.get_ticks_usec()",
            "\t\tcontainer.add_child(c)",
            "\t\tif __bh_prof_add_cards_attach_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.card_add_child_and_ready\", __bh_prof_add_cards_attach_start_us, {\"card_type\": str(c.data.type), \"item\": c.item})",
            "\t\ttotal_card_width += c.border.rect_size.x"
        })))
            return source;

        return modified[..positionsStart] + positions + modified[positionsEnd..];
    }

    private static bool Replace(ref string source, string original, string replacement)
    {
        var index = source.IndexOf(original, StringComparison.Ordinal);
        if (index < 0)
            return false;

        source = source[..index] + replacement + source[(index + original.Length)..];
        return true;
    }
}
