using SlotWeave.Modding;

namespace Piraeus.BetterLandlord.Patches;

/// <summary>
/// Gives <c>sandbox_consistent</c> a debugging-oriented meaning: when true,
/// the first accepted Sandbox spin resolves the configured board in place.
/// The setting is then switched off in-memory so every later spin follows the
/// native random shuffle path.
///
/// Native consistent spins also use a different reel-animation end offset.
/// A short-lived active flag retains that offset for the first spin after the
/// setting has been consumed; otherwise the animation itself would rotate the
/// visible symbols even when shuffle_tiles() was skipped.
/// </summary>
public sealed class SandboxFirstSpinLayoutSourceMod : ISourceMod
{
    private const string MainPath = "res://Main.tscn::1";
    private const string ReelsControllerPath = "res://Main.tscn::4";
    private const string ReelPath = "res://Reel.tscn::1";
    private const string MainMarker = "# BetterLandlord: Sandbox first-spin layout state";
    private const string ReelsMarker = "# BetterLandlord: Sandbox first-spin layout handling";

    public bool ShouldRun(string path) => path == MainPath || path == ReelsControllerPath || path == ReelPath;

    public string Modify(string path, string source) => path switch
    {
        MainPath => ModifyMain(source),
        ReelsControllerPath => ModifyReelsController(source),
        ReelPath => ModifyReel(source),
        _ => source,
    };

    private static string ModifyMain(string source)
    {
        if (source.Contains(MainMarker, StringComparison.Ordinal))
            return source;

        // This variable is deliberately runtime-only.  load_sandbox() reloads
        // sandbox_consistent from LBAL-Sandbox-Data.save for the next run.
        return source + "\n" + GdscriptUtil.Tabify(MainState) + "\n";
    }

    private static string ModifyReelsController(string source)
    {
        if (source.Contains(ReelsMarker, StringComparison.Ordinal))
            return source;

        var originalSource = source;
        const string acceptedSpinAnchor =
            "\tfor r in reels:\n" +
            "\t\tif r.spinning:\n" +
            "\t\t\treturn\n" +
            "\t\n" +
            "\tadd_tba_symbols()";
        const string acceptedSpinReplacement =
            "\tfor r in reels:\n" +
            "\t\tif r.spinning:\n" +
            "\t\t\treturn\n" +
            "\t\n" +
            "\t# BetterLandlord: Sandbox first-spin layout handling\n" +
            "\t# Consume sandbox_consistent only after spin() has passed its native guards.\n" +
            "\tif $\"/root/Main\".sandbox_mode and $\"/root/Main\".sandbox_consistent:\n" +
            "\t\t$\"/root/Main\".sandbox_consistent = false\n" +
            "\t\t$\"/root/Main\"._bl_sandbox_first_spin_layout_active = true\n" +
            "\telse:\n" +
            "\t\t$\"/root/Main\"._bl_sandbox_first_spin_layout_active = false\n" +
            "\t\n" +
            "\tadd_tba_symbols()";

        const string shuffleAnchor = "func shuffle_tiles():\n\tif (";
        const string shuffleReplacement =
            "func shuffle_tiles():\n" +
            "\t# BetterLandlord: first consistent Sandbox spin resolves its preset board.\n" +
            "\tif $\"/root/Main\".sandbox_mode and $\"/root/Main\"._bl_sandbox_first_spin_layout_active:\n" +
            "\t\treturn\n" +
            "\tif (";

        if (!ReplaceOnce(ref source, acceptedSpinAnchor, acceptedSpinReplacement) ||
            !ReplaceOnce(ref source, shuffleAnchor, shuffleReplacement))
        {
            return originalSource;
        }

        return source;
    }

    private static string ModifyReel(string source)
    {
        if (source.Contains(ReelsMarker, StringComparison.Ordinal))
            return source;

        var originalSource = source;
        const string finishAnchor =
            "\t\t\t\t\tparent.spinning = false\n" +
            "\t\t\t\t\tparent.update_icon_types()";
        const string finishReplacement =
            "\t\t\t\t\tparent.spinning = false\n" +
            "\t\t\t\t\t# BetterLandlord: Sandbox first-spin layout handling\n" +
            "\t\t\t\t\tif not mini_spin and $\"/root/Main\"._bl_sandbox_first_spin_layout_active:\n" +
            "\t\t\t\t\t\t$\"/root/Main\"._bl_sandbox_first_spin_layout_active = false\n" +
            "\t\t\t\t\tparent.update_icon_types()";

        if (!ReplaceOnce(ref source, finishAnchor, finishReplacement))
            return originalSource;

        // The native check becomes false as soon as sandbox_consistent is
        // consumed.  Keep its special animation offset for this one spin.
        const string nativeConsistentCheck =
            "($\"/root/Main\".sandbox_mode and $\"/root/Main\".sandbox_consistent)";
        const string activeConsistentCheck =
            "($\"/root/Main\".sandbox_mode and ($\"/root/Main\".sandbox_consistent or $\"/root/Main\"._bl_sandbox_first_spin_layout_active))";
        if (CountOccurrences(source, nativeConsistentCheck) != 2)
            return originalSource;

        return source.Replace(nativeConsistentCheck, activeConsistentCheck, StringComparison.Ordinal);
    }

    private static bool ReplaceOnce(ref string source, string original, string replacement)
    {
        var index = source.IndexOf(original, StringComparison.Ordinal);
        if (index >= 0)
        {
            source = source[..index] + replacement + source[(index + original.Length)..];
            return true;
        }

        var crlfOriginal = original.Replace("\n", "\r\n", StringComparison.Ordinal);
        index = source.IndexOf(crlfOriginal, StringComparison.Ordinal);
        if (index < 0)
            return false;

        var crlfReplacement = replacement.Replace("\n", "\r\n", StringComparison.Ordinal);
        source = source[..index] + crlfReplacement + source[(index + crlfOriginal.Length)..];
        return true;
    }

    private static int CountOccurrences(string source, string value)
    {
        var count = 0;
        var start = 0;
        while (true)
        {
            var index = source.IndexOf(value, start, StringComparison.Ordinal);
            if (index < 0)
                return count;
            count++;
            start = index + value.Length;
        }
    }

    private const string MainState = """

# BetterLandlord: Sandbox first-spin layout state
# This is transient. sandbox_consistent is the user-facing setting and is
# reloaded from LBAL-Sandbox-Data.save when a new Sandbox run is started.
var _bl_sandbox_first_spin_layout_active = false
""";
}
