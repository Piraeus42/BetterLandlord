using System.Collections.Concurrent;
using System.Globalization;
using System.Reflection;
using System.Windows.Data;
using System.Windows.Media.Imaging;

namespace Piraeus.BetterLandlord.UI.Converters;

/// <summary>
/// Converts an icon name (e.g. "bee", "coin") to a cached BitmapImage
/// loaded from embedded assembly resources (Assets/Icons/{name}.png).
/// Returns null if not found.
/// </summary>
public class IconNameToImageConverter : IValueConverter
{
    private static readonly ConcurrentDictionary<string, BitmapImage?> Cache = new();
    private static readonly Assembly Assembly;
    private const string ResourcePrefix = "Piraeus.BetterLandlord.UI.Assets.Icons.";

    static IconNameToImageConverter()
    {
        Assembly = typeof(IconNameToImageConverter).Assembly;
    }

    public object? Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var name = (parameter as string) ?? value?.ToString();
        if (string.IsNullOrEmpty(name)) return null;

        return Cache.GetOrAdd(name, LoadIcon);
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();

    private static BitmapImage? LoadIcon(string name)
    {
        // Try exact case first, then lowercase
        var names = new[] { name, name.ToLowerInvariant() };
        foreach (var n in names)
        {
            var resourceName = ResourcePrefix + n + ".png";
            using var stream = Assembly.GetManifestResourceStream(resourceName);
            if (stream == null) continue;

            var img = new BitmapImage();
            img.BeginInit();
            img.CacheOption = BitmapCacheOption.OnLoad;
            img.StreamSource = stream;
            img.EndInit();
            img.Freeze();
            return img;
        }
        return null;
    }
}

/// <summary>
/// Multi-value converter: takes a list of icon names and returns a list of images.
/// </summary>
public class IconNamesToImagesConverter : IValueConverter
{
    private static readonly IconNameToImageConverter Inner = new();

    public object? Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var names = value as IEnumerable<string>;
        if (names == null) return null;

        return names
            .Select(n => Inner.Convert(n, targetType, parameter, culture) as BitmapImage)
            .Where(img => img != null)
            .ToList();
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();
}
