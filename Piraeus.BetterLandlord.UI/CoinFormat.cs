using System.Globalization;

namespace Piraeus.BetterLandlord.UI;

/// <summary>
/// Display formatting for coin values. Values at or above 1e15 (well below
/// the 2^53 exact-integer limit of float64) are shown in scientific notation
/// so overflow-scale history data stays readable.
/// </summary>
public static class CoinFormat
{
    public const double ScientificThreshold = 1e15;

    public static string Format(double value)
    {
        if (double.IsNaN(value)) return "NaN";
        if (double.IsPositiveInfinity(value)) return "+∞";
        if (double.IsNegativeInfinity(value)) return "-∞";
        if (Math.Abs(value) >= ScientificThreshold)
            return value.ToString("0.00e0", CultureInfo.InvariantCulture);
        return value.ToString(CultureInfo.InvariantCulture);
    }

    /// <summary>
    /// Per-spin averages keep one decimal below the threshold, matching the
    /// legacy F1 formatting; only overflow-scale values switch to scientific.
    /// </summary>
    public static string FormatF1(double value)
        => double.IsFinite(value) && Math.Abs(value) < ScientificThreshold
            ? value.ToString("F1", CultureInfo.InvariantCulture)
            : Format(value);

    public static string Signed(double value)
        => value >= 0 ? $"+{Format(value)}" : Format(value);

    /// <summary>
    /// Reformat a stored numeric string (e.g. symbol stack values) only when
    /// it parses as an overflow-scale number; everything else passes through.
    /// </summary>
    public static string? FromStoredText(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return text;
        return double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var value)
            && Math.Abs(value) >= ScientificThreshold
            ? Format(value)
            : text;
    }
}
