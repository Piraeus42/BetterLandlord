using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Instruments the synchronous stages inside Pop-up.display(). The function is
/// the UI work that runs before Godot can present the next frame after a choice,
/// so its internal spans must remain source-level and behavior-neutral.
/// </summary>
public class PopupDisplayProfileSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Pop-up.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("__bh_prof_popup_display_text_start_us", StringComparison.Ordinal))
            return source;

        var eol = source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
        const string functionStart = "func display():";
        var start = source.IndexOf(functionStart, StringComparison.Ordinal);
        var end = start < 0
            ? -1
            : source.IndexOf(eol + "func add_buttons():", start, StringComparison.Ordinal);
        if (start < 0 || end < 0)
            return source;

        // Only rewrite the display() body. The same statements also occur in
        // draw_deck()/undraw_deck(), where its local variables and semantics
        // differ; a whole-file replacement would be unsafe.
        var display = source.Substring(start, end - start);

        if (!Replace(ref display, string.Join(eol, new[]
        {
            "\tif emails.size() > 0 and not visible:",
            "\t\tif $\"/root/Main/Options Sprite/Options\".CJK_lang:"
        }), string.Join(eol, new[]
        {
            "\tif emails.size() > 0 and not visible:",
            "\t\tvar __bh_prof_popup_display_text_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_popup_display_text_start_us = OS.get_ticks_usec()",
            "\t\tif $\"/root/Main/Options Sprite/Options\".CJK_lang:"
        })))
            return source;

        if (!Replace(ref display, string.Join(eol, new[]
        {
            "\t\tlabel_text.force_update = true",
            "\t\tlabel_text.change_set_size(label_text.base_scale)",
            "\t\tfor x in range(reels.reel_width):"
        }), string.Join(eol, new[]
        {
            "\t\tlabel_text.force_update = true",
            "\t\tlabel_text.change_set_size(label_text.base_scale)",
            "\t\tif __bh_prof_popup_display_text_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.text_setup\", __bh_prof_popup_display_text_start_us, {\"email_type\": str(emails[0].type)})",
            "\t\tvar __bh_prof_popup_display_reel_stop_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_popup_display_reel_stop_start_us = OS.get_ticks_usec()",
            "\t\tfor x in range(reels.reel_width):"
        })))
            return source;

        if (!Replace(ref display, string.Join(eol, new[]
        {
            "\t\t\t\t\treels.displayed_icons[y][x].sfx_player.stop()",
            "\t\tvar email = emails[0]"
        }), string.Join(eol, new[]
        {
            "\t\t\t\t\treels.displayed_icons[y][x].sfx_player.stop()",
            "\t\tif __bh_prof_popup_display_reel_stop_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.stop_reel_animations\", __bh_prof_popup_display_reel_stop_start_us, {\"reel_width\": reels.reel_width, \"reel_height\": reels.reel_height})",
            "\t\tvar __bh_prof_popup_display_layout_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_popup_display_layout_start_us = OS.get_ticks_usec()",
            "\t\tvar email = emails[0]"
        })))
            return source;

        if (!Replace(ref display, string.Join(eol, new[]
        {
            "\t\tadd_buttons()",
            "\t\t",
            "\t\tvar total_button_height = 0"
        }), string.Join(eol, new[]
        {
            "\t\tif __bh_prof_popup_display_layout_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.base_layout\", __bh_prof_popup_display_layout_start_us, {\"email_type\": str(email.type), \"prompt\": email.prompt})",
            "\t\tadd_buttons()",
            "\t\t",
            "\t\tvar total_button_height = 0"
        })))
            return source;

        if (!Replace(ref display, "\t\tvar header_text = sender_container.get_child(0)", string.Join(eol, new[]
        {
            "\t\tvar __bh_prof_popup_display_content_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_popup_display_content_start_us = OS.get_ticks_usec()",
            "\t\tvar header_text = sender_container.get_child(0)"
        })))
            return source;

        if (!Replace(ref display, string.Join(eol, new[]
        {
            "\t\tif not visible:",
            "\t\t\tdraw()"
        }), string.Join(eol, new[]
        {
            "\t\tif __bh_prof_popup_display_content_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.email_content\", __bh_prof_popup_display_content_start_us, {\"email_type\": str(email.type), \"card_count\": cards.size(), \"button_count\": buttons.size()})",
            "\t\tif not visible:",
            "\t\t\tdraw()",
            "\t\tvar __bh_prof_popup_display_final_layout_start_us = -1",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_popup_display_final_layout_start_us = OS.get_ticks_usec()"
        })))
            return source;

        if (!Replace(ref display, "\t\tscroll_bar.rect_position.y = scroll_bar.top", string.Join(eol, new[]
        {
            "\t\tscroll_bar.rect_position.y = scroll_bar.top",
            "\t\tif __bh_prof_popup_display_final_layout_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.display.final_layout\", __bh_prof_popup_display_final_layout_start_us, {\"email_type\": str(email.type), \"scroll_visible\": scroll_bar.visible})"
        })))
            return source;

        return source[..start] + display + source[end..];
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
