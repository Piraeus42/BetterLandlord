using System.Globalization;
using System.Windows.Data;
using Piraeus.BetterLandlord.Model;

namespace Piraeus.BetterLandlord.UI.Converters;

/// <summary>
/// Formats the storage-room symbol tooltip without touching the model's
/// JSON-facing types: mirrors SymbolInSummary.DptDisplay with large-number
/// scientific notation applied.
/// </summary>
public class DptDisplayConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        => value switch
        {
            SymbolInSummary s => FormatDpt(s.TotalValue, s.DptActual, s.DptEffective),
            DptEntry d => FormatDpt(d.TotalValue, d.DptActual, d.DptEffective),
            _ => ""
        };

    private static string FormatDpt(double totalValue, double dptActual, double dptEffective)
        => totalValue > 0
            ? $"{CoinFormat.Format(totalValue)} coins · {CoinFormat.FormatF1(dptActual)}/spin · {CoinFormat.FormatF1(dptEffective)}/有效"
            : "";

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => Binding.DoNothing;
}
