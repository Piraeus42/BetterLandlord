using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace Piraeus.BetterHistory.UI.Converters;

/// <summary>Converts bool to Visibility.Visible/Collapsed.</summary>
public class BoolToVisibilityConverter : IValueConverter
{
    public bool Invert { get; set; }

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        // Support bool, int (Count > 0), and null/0/false → collapsed
        var b = value is true
             || (value is int i && i > 0)
             || (value is long l && l > 0);
        if (Invert) b = !b;
        return b ? Visibility.Visible : Visibility.Collapsed;
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return value is Visibility v && v == Visibility.Visible ? !Invert : Invert;
    }
}

/// <summary>Converts null to Visibility.Collapsed.</summary>
public class NullToVisibilityConverter : IValueConverter
{
    public bool Invert { get; set; }

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var isNull = value == null;
        if (Invert) isNull = !isNull;
        return isNull ? Visibility.Collapsed : Visibility.Visible;
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>Converts "victory" to a green checkmark, "loss" to red X.</summary>
public class ResultToIconConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return value?.ToString() == "victory" ? "✓" : "✗";
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>Converts result string to a brush color.</summary>
public class ResultToColorConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return value?.ToString() switch
        {
            "victory" => System.Windows.Media.Brushes.LimeGreen,
            "quit"    => System.Windows.Media.Brushes.DodgerBlue,
            _         => System.Windows.Media.Brushes.IndianRed
        };
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
