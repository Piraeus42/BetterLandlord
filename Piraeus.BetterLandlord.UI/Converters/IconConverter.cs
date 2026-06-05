using System.Collections.Concurrent;
using System.Globalization;
using System.IO;
using System.Windows.Data;
using System.Windows.Media.Imaging;

namespace Piraeus.BetterLandlord.UI.Converters;

/// <summary>
/// Converts an icon name (e.g. "bee", "coin") to a cached BitmapImage
/// loaded from Assets/Icons/{name}.png. Returns null if not found.
/// </summary>
public class IconNameToImageConverter : IValueConverter
{
    private static readonly ConcurrentDictionary<string, BitmapImage?> Cache = new();
    private static readonly string IconDir;

    static IconNameToImageConverter()
    {
        // Icons are copied to the output directory as Content/PreserveNewest
        var exeDir = AppDomain.CurrentDomain.BaseDirectory;
        IconDir = Path.Combine(exeDir, "Assets", "Icons");
    }

    public object? Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        // Prefer explicit parameter (e.g. ConverterParameter=coin), else use bound value
        var name = (parameter as string) ?? value?.ToString();
        if (string.IsNullOrEmpty(name)) return null;

        return Cache.GetOrAdd(name, LoadIcon);
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();

    private static BitmapImage? LoadIcon(string name)
    {
        try
        {
            // Try exact match first
            var path = Path.Combine(IconDir, $"{name}.png");
            if (File.Exists(path))
                return CreateImage(path);

            // Try lowercase
            path = Path.Combine(IconDir, $"{name.ToLowerInvariant()}.png");
            if (File.Exists(path))
                return CreateImage(path);

            return null;
        }
        catch
        {
            return null;
        }
    }

    private static BitmapImage CreateImage(string path)
    {
        var img = new BitmapImage();
        img.BeginInit();
        img.CacheOption = BitmapCacheOption.OnLoad;
        img.UriSource = new Uri(path);
        img.EndInit();
        img.Freeze(); // make cross-thread safe
        return img;
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
