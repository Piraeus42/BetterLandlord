using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Adds a "speed_all" master row to the Options → gameplay page that sets
/// spin/animation/counting/menu speed to the same value in one click
/// (0.5x/0.75x/1x-4x/instant, mirroring the four individual dropdowns).
///
/// Display sync needs no extra state: update_setting() rebuilds the whole
/// page via add_buttons() after every change, so choosing a master value
/// refreshes the four individual rows, and changing any individual row
/// recomputes the master label (common value, or "-" while mixed). The
/// master row itself is derived state — save()/load keep storing only the
/// four real settings.
/// </summary>
public class OptionsMasterSpeedSourceMod : ISourceMod
{
    private const string OptionsPath = "res://Options.tscn::1";

    public bool ShouldRun(string path) => path == OptionsPath;

    public string Modify(string path, string source)
    {
        if (source.Contains("\"speed_all\"", StringComparison.Ordinal))
            return source;

        var eol = GetEol(source);
        var patches = new (string Anchor, string Replacement)[]
        {
            // gameplay page: master row first, above the four speed rows
            (Join(eol, "\t\t\t" + @"option_types = [""spin_speed"", ""animation_speed"", ""counting_speed"", ""menu_speed"", ""input_type"", ""screen_reader"", ""digit_separators"", ""scientific_notation""]"),
             Join(eol, "\t\t\t" + @"option_types = [""speed_all"", ""spin_speed"", ""animation_speed"", ""counting_speed"", ""menu_speed"", ""input_type"", ""screen_reader"", ""digit_separators"", ""scientific_notation""]")),

            // add_button(): current-value label derived from the four speeds
            (Join(eol,
                "\t\t" + @"""spin_speed"":",
                "\t\t\t" + @"if spin_speed != 0:",
                "\t\t\t\t" + @"button.button_text = str(spin_speed) + ""x""",
                "\t\t\t" + @"else:",
                "\t\t\t\t" + @"button.button_text = tr(""instant"")",
                "\t\t\t" + @"button.call = ""add_dropdown""",
                "\t\t\t" + @"button.args = [s]"),
             Join(eol,
                "\t\t" + @"""speed_all"":",
                "\t\t\t" + @"if spin_speed == animation_speed and animation_speed == counting_speed and counting_speed == menu_speed:",
                "\t\t\t\t" + @"if spin_speed != 0:",
                "\t\t\t\t\t" + @"button.button_text = str(spin_speed) + ""x""",
                "\t\t\t\t" + @"else:",
                "\t\t\t\t\t" + @"button.button_text = tr(""instant"")",
                "\t\t\t" + @"else:",
                "\t\t\t\t" + @"button.button_text = ""-""",
                "\t\t\t" + @"button.call = ""add_dropdown""",
                "\t\t\t" + @"button.args = [s]",
                "\t\t" + @"""spin_speed"":",
                "\t\t\t" + @"if spin_speed != 0:",
                "\t\t\t\t" + @"button.button_text = str(spin_speed) + ""x""",
                "\t\t\t" + @"else:",
                "\t\t\t\t" + @"button.button_text = tr(""instant"")",
                "\t\t\t" + @"button.call = ""add_dropdown""",
                "\t\t\t" + @"button.args = [s]")),

            // add_dropdown(): master dropdown offers the same 7 choices
            (Join(eol,
                "\t\t" + @"""spin_speed"":",
                "\t\t\t" + @"for i in range(7):",
                "\t\t\t\t" + @"add_dropdown_button(""spin_speed"", 160 + i * button_offset, i)"),
             Join(eol,
                "\t\t" + @"""speed_all"":",
                "\t\t\t" + @"for i in range(7):",
                "\t\t\t\t" + @"add_dropdown_button(""speed_all"", 160 + i * button_offset, i)",
                "\t\t" + @"""spin_speed"":",
                "\t\t\t" + @"for i in range(7):",
                "\t\t\t\t" + @"add_dropdown_button(""spin_speed"", 160 + i * button_offset, i)")),

            // add_dropdown_button(): reuse the shared speed choice builder
            (Join(eol,
                "\t\t" + @"""spin_speed"", ""animation_speed"", ""counting_speed"", ""menu_speed"":",
                "\t\t\t" + @"button.call = ""update_setting"""),
             Join(eol,
                "\t\t" + @"""spin_speed"", ""animation_speed"", ""counting_speed"", ""menu_speed"", ""speed_all"":",
                "\t\t\t" + @"button.call = ""update_setting""")),

            // update_setting(): master choice fans out to the four real settings
            (Join(eol,
                "\t\t" + @"""spin_speed"", ""animation_speed"", ""counting_speed"", ""menu_speed"":",
                "\t\t\t" + @"self[setting] = choice"),
             Join(eol,
                "\t\t" + @"""spin_speed"", ""animation_speed"", ""counting_speed"", ""menu_speed"":",
                "\t\t\t" + @"self[setting] = choice",
                "\t\t" + @"""speed_all"":",
                "\t\t\t" + @"spin_speed = choice",
                "\t\t\t" + @"animation_speed = choice",
                "\t\t\t" + @"counting_speed = choice",
                "\t\t\t" + @"menu_speed = choice")),

            // row label: localized, intercepting the tr() fallback
            (Join(eol,
                "\t\t\t" + @"_:",
                "\t\t\t\t" + @"if track_names.has(option_types[b]):"),
             Join(eol,
                "\t\t\t" + @"""speed_all"":",
                "\t\t\t\t" + @"if TranslationServer.get_locale().begins_with(""zh""):",
                "\t\t\t\t\t" + @"add_option_text(""动画速度总控"")",
                "\t\t\t\t" + @"else:",
                "\t\t\t\t\t" + @"add_option_text(""master animation speed"")",
                "\t\t\t" + @"_:",
                "\t\t\t\t" + @"if track_names.has(option_types[b]):")),
        };

        foreach (var (anchor, replacement) in patches)
        {
            if (source.Contains(anchor, StringComparison.Ordinal))
                source = source.Replace(anchor, replacement, StringComparison.Ordinal);
        }
        return source;
    }

    private static string Join(string eol, params string[] lines) => string.Join(eol, lines);

    private static string GetEol(string source) => source.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
}
