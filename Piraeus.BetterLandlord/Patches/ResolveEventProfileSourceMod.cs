using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Adds one scoped timer around the immediate card free/clear loop in
/// Pop-up.resolve_event. This is a narrowly targeted source injection because
/// queue_free() is a base-node operation and cannot be patched per card.
/// </summary>
public class ResolveEventProfileSourceMod : ISourceMod
{
    public bool ShouldRun(string path) => path == "res://Pop-up.tscn::1";

    public string Modify(string path, string source)
    {
        if (source.Contains("__bh_prof_popup_cards_start_us")) return source;

        var eol = source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
        var original = string.Join(eol, new[]
        {
            "\t\tfor c in cards:",
            "\t\t\tc.queue_free()",
            "\t\tcards.clear()"
        });
        if (!source.Contains(original, StringComparison.Ordinal)) return source;

        var instrumented = string.Join(eol, new[]
        {
            "\t\tvar __bh_prof_popup_cards_start_us = -1",
            "\t\tvar __bh_prof_popup_cards_count = cards.size()",
            "\t\tif $\"/root/Main\".has_method(\"_bh_profile_record\"): ",
            "\t\t\t__bh_prof_popup_cards_start_us = OS.get_ticks_usec()",
            "\t\tfor c in cards:",
            "\t\t\tc.queue_free()",
            "\t\tcards.clear()",
            "\t\tif __bh_prof_popup_cards_start_us >= 0:",
            "\t\t\t$\"/root/Main\"._bh_profile_record(\"popup.cards_cleanup\", __bh_prof_popup_cards_start_us, {\"card_count\": __bh_prof_popup_cards_count})"
        });

        return source.Replace(original, instrumented, StringComparison.Ordinal);
    }
}
