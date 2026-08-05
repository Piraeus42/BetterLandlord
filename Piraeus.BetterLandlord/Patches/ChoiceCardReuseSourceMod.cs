using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Reuses the three ordinary choice-card controls shown by add_tile/add_item.
/// Only the normal three-choice path participates: prompt, inventory, tooltip,
/// and other Card consumers retain their native lifetime and initialization.
/// </summary>
public sealed class ChoiceCardReuseSourceMod : ISourceMod
{
    private const string PopupPath = "res://Pop-up.tscn::1";
    private const string CardPath = "res://Card.tscn::1";

    public bool ShouldRun(string path) => path is PopupPath or CardPath;

    public string Modify(string path, string source) => path switch
    {
        PopupPath => ModifyPopup(source),
        CardPath => ModifyCard(source),
        _ => source
    };

    private static string ModifyCard(string source)
    {
        if (source.Contains("func _bl_refresh_choice_card():", StringComparison.Ordinal))
            return source;

        var originalSource = source;
        var eol = GetEol(source);
        if (!Replace(ref source, "var data = {}", string.Join(eol, new[]
        {
            "var data = {}",
            "var _bl_choice_poolable = false",
            "var _bl_choice_reused = false"
        })))
            return originalSource;

        // Choice cards are completely configured before their first add_child().
        // Avoid the native duplicate size/icon pass only for this explicitly
        // marked path; all other Card users retain their original _ready().
        if (!Replace(ref source, string.Join(eol, new[]
        {
            "func _ready():",
            "\tset_icon_size()"
        }), string.Join(eol, new[]
        {
            "func _ready():",
            "\tif _bl_choice_poolable:",
            "\t\t_bl_refresh_choice_card()",
            "\t\treturn",
            "\tset_icon_size()"
        })))
            return originalSource;

        var functions = string.Join(eol, new[]
        {
            "",
            "# Rebind a cached ordinary choice Card. This deliberately resets every",
            "# state that may survive a previous offer before applying the next data.",
            "func _bl_refresh_choice_card():",
            "\tactive = false",
            "\thovering = false",
            "\tselectable = false",
            "\toff_screen = false",
            "\theld = false",
            "\tdelay = 0",
            "\tr_x_mod = 0",
            "\textra_height = 0",
            "\tselector_alignment = \"card\"",
            "\tvisible = true",
            "\tbackground = $\"Background\"",
            "\tborder = $\"Border\"",
            "\tvar title = $\"Background/Title\"",
            "\tvar rarity = $\"Background/Rarity\"",
            "\tvar value = $\"Background/Value\"",
            "\tvar description = $\"Background/Description\"",
            "\ttitle.raw_string = \"\"",
            "\ttitle.values = []",
            "\ttitle.tooltip_desc = false",
            "\ttitle.v_spaced = false",
            "\ttitle.custom_icon_offset = Vector2(0, 0)",
            "\trarity.raw_string = \"\"",
            "\trarity.values = []",
            "\trarity.tooltip_desc = false",
            "\trarity.v_spaced = false",
            "\trarity.custom_icon_offset = Vector2(0, 0)",
            "\tvalue.raw_string = \"\"",
            "\tvalue.values = []",
            "\tvalue.tooltip_desc = false",
            "\tvalue.v_spaced = false",
            "\tvalue.custom_icon_offset = Vector2(0, 0)",
            "\tdescription.raw_string = \"\"",
            "\tdescription.values = []",
            "\tdescription.tooltip_desc = false",
            "\tdescription.v_spaced = false",
            "\tdescription.custom_icon_offset = Vector2(0, 0)",
            "\t$\"Separator\".clear_points()",
            "\tset_icon_size()",
            "\tif item:",
            "\t\tbackground.color = $\"/root/Main/Options Sprite/Options\".colors3[\"item_background\"]",
            "\telse:",
            "\t\tbackground.color = $\"/root/Main/Options Sprite/Options\".colors3[\"symbol_background\"]",
            "\tset_card_size()"
        });

        return source + eol + functions + eol;
    }

    private static string ModifyPopup(string source)
    {
        if (source.Contains("func _bl_take_choice_card(", StringComparison.Ordinal))
            return source;

        var originalSource = source;
        var eol = GetEol(source);
        if (!Replace(ref source, "var cards = []", string.Join(eol, new[]
        {
            "var cards = []",
            "var _bl_symbol_choice_card_cache = []",
            "var _bl_item_choice_card_cache = []",
            "var _bl_choice_card_cache_host = null"
        })))
            return originalSource;

        // AddCardsProfileSourceMod has already wrapped this block. Keep its
        // timing span, but make it measure cache acquisition on a hit and
        // scene instantiation only on a miss.
        if (!Replace(ref source, string.Join(eol, new[]
        {
            "\t\t\tif stcf <= 3:",
            "\t\t\t\tvar __bh_prof_add_cards_instance_start_us = -1",
            "\t\t\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t\t\t__bh_prof_add_cards_instance_start_us = OS.get_ticks_usec()",
            "\t\t\t\tcard = preload(\"res://Card.tscn\").instance()",
            "\t\t\t\tif __bh_prof_add_cards_instance_start_us >= 0:",
            "\t\t\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.card_instance\", __bh_prof_add_cards_instance_start_us, {\"email_type\": str(email.type), \"candidate_index\": c})",
            "\t\t\t\tif email.type == \"add_item\":",
            "\t\t\t\t\tcard.item = true"
        }), string.Join(eol, new[]
        {
            "\t\t\tif stcf <= 3:",
            "\t\t\t\tvar __bh_prof_add_cards_instance_start_us = -1",
            "\t\t\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t\t\t__bh_prof_add_cards_instance_start_us = OS.get_ticks_usec()",
            "\t\t\t\tcard = _bl_take_choice_card(email.type == \"add_item\")",
            "\t\t\t\tif card == null:",
            "\t\t\t\t\tcard = preload(\"res://Card.tscn\").instance()",
            "\t\t\t\t\tcard._bl_choice_reused = false",
            "\t\t\t\tcard._bl_choice_poolable = true",
            "\t\t\t\tcard.item = email.type == \"add_item\"",
            "\t\t\t\tif __bh_prof_add_cards_instance_start_us >= 0:",
            "\t\t\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.card_instance\", __bh_prof_add_cards_instance_start_us, {\"email_type\": str(email.type), \"candidate_index\": c, \"reused\": card._bl_choice_reused, \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})"
        })))
            return originalSource;

        if (!Replace(ref source, string.Join(eol, new[]
        {
            "\t\t\t\tif stcf <= 3:",
            "\t\t\t\t\tif rarity != null and card_pool.has(rarity):",
            "\t\t\t\t\t\tcard_pool[rarity].erase(card.data.type)",
            "\t\t\t\t\tsaved_card_types.push_back(card.data.type)",
            "\t\t\t\t\tcards.push_back(card)"
        }), string.Join(eol, new[]
        {
            "\t\t\t\tif stcf <= 3:",
            "\t\t\t\t\tif rarity != null and card_pool.has(rarity):",
            "\t\t\t\t\t\tcard_pool[rarity].erase(card.data.type)",
            "\t\t\t\t\tif card._bl_choice_reused:",
            "\t\t\t\t\t\tvar __bl_choice_card_rebind_start_us = -1",
            "\t\t\t\t\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t\t\t\t\t__bl_choice_card_rebind_start_us = OS.get_ticks_usec()",
            "\t\t\t\t\t\tcard._bl_refresh_choice_card()",
            "\t\t\t\t\t\tif __bl_choice_card_rebind_start_us >= 0:",
            "\t\t\t\t\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.add_cards.card_rebind\", __bl_choice_card_rebind_start_us, {\"card_type\": str(card.data.type), \"item\": card.item, \"trigger\": __bh_prof_add_cards_trigger, \"reroll_id\": __bh_prof_add_cards_reroll_id})",
            "\t\t\t\t\tsaved_card_types.push_back(card.data.type)",
            "\t\t\t\t\tcards.push_back(card)"
        })))
            return originalSource;

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

        if (!Replace(ref source, string.Join(eol, new[]
        {
            "\t\tfor c in cards:",
            "\t\t\tc.queue_free()",
            "\t\tcards.clear()"
        }), "\t\t_bl_release_choice_cards()"))
            return originalSource;

        var functions = string.Join(eol, new[]
        {
            "",
            "# Cached Cards remain parented under this Popup so Card._free_if_orphaned",
            "# never releases them between offers.",
            "func _bl_get_choice_card_cache_host():",
            "\tif _bl_choice_card_cache_host == null:",
            "\t\t_bl_choice_card_cache_host = Node.new()",
            "\t\t_bl_choice_card_cache_host.name = \"BL Choice Card Cache\"",
            "\t\tadd_child(_bl_choice_card_cache_host)",
            "\treturn _bl_choice_card_cache_host",
            "",
            "func _bl_take_choice_card(is_item):",
            "\tvar cache = _bl_item_choice_card_cache if is_item else _bl_symbol_choice_card_cache",
            "\tif cache.size() == 0:",
            "\t\treturn null",
            "\tvar card = cache.pop_back()",
            "\tcard._bl_choice_reused = true",
            "\tcard.item = is_item",
            "\tcard.visible = true",
            "\treturn card",
            "",
            "func _bl_release_choice_cards():",
            "\tfor card in cards:",
            "\t\tvar parent = card.get_parent()",
            "\t\tif card._bl_choice_poolable:",
            "\t\t\tvar cache = _bl_item_choice_card_cache if card.item else _bl_symbol_choice_card_cache",
            "\t\t\tif cache.size() < 3:",
            "\t\t\t\tcard.active = false",
            "\t\t\t\tcard.hovering = false",
            "\t\t\t\tcard.selectable = false",
            "\t\t\t\tcard.held = false",
            "\t\t\t\tcard.visible = false",
            "\t\t\t\tcard.data = {}",
            "\t\t\t\tif parent != null:",
            "\t\t\t\t\tparent.remove_child(card)",
            "\t\t\t\t_bl_get_choice_card_cache_host().add_child(card)",
            "\t\t\t\tcache.push_back(card)",
            "\t\t\t\tcontinue",
            "\t\tif parent != null:",
            "\t\t\tparent.remove_child(card)",
            "\t\tcard.queue_free()",
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
