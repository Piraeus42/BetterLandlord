using System.Collections.Concurrent;
using System.Globalization;
using System.Reflection;
using System.Windows.Data;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace Piraeus.BetterLandlord.UI.Converters;

/// <summary>
/// Converts an icon name (e.g. "bee", "coin") to a cached frozen BitmapSource
/// loaded from embedded assembly resources (Assets/Icons/{name}.png).
/// A pure integer ConverterParameter is treated as the target display size in
/// DIPs; when the source is square and divides it evenly, the bitmap is
/// pre-expanded with nearest-neighbor pixel replication so WPF never has to
/// scale it at render time. Returns null if not found.
/// </summary>
public class IconNameToImageConverter : IValueConverter
{
    private static readonly ConcurrentDictionary<(string Name, int TargetSize), BitmapSource?> Cache = new();
    private static readonly Assembly Assembly;
    private const string ResourcePrefix = "Piraeus.BetterLandlord.UI.Assets.Icons.";

    static IconNameToImageConverter()
    {
        Assembly = typeof(IconNameToImageConverter).Assembly;
    }

    public object? Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        // "ConverterParameter=24" asks for a display size; other string
        // parameters (e.g. "coin") still select the icon directly.
        if (parameter is string sizeText
            && int.TryParse(sizeText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var targetSize))
        {
            var boundName = value?.ToString();
            if (string.IsNullOrEmpty(boundName)) return null;

            boundName = NormalizeName(boundName);
            return Cache.GetOrAdd((boundName, targetSize), static key => LoadIcon(key.Name, key.TargetSize));
        }

        var name = (parameter as string) ?? value?.ToString();
        if (string.IsNullOrEmpty(name)) return null;

        // Custom Steam Workshop symbols are persisted with a suffix such as
        // "_STEAM_ID_123". Avalonia's IconCache strips it before lookup; keep
        // the WPF renderer compatible with the same history records.
        name = NormalizeName(name);
        return Cache.GetOrAdd((name, 0), static key => LoadIcon(key.Name, 0));
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();

    private static string NormalizeName(string name)
    {
        const string steamIdSuffix = "_STEAM_ID_";
        var suffixIndex = name.IndexOf(steamIdSuffix, StringComparison.Ordinal);
        return suffixIndex > 0 ? name[..suffixIndex] : name;
    }

    private static BitmapSource? LoadIcon(string name, int targetSize)
    {
        var source = LoadOriginal(name);
        if (source == null || targetSize <= 0) return source;

        // Only pre-scale when the result is an exact integer expansion;
        // anything else is better left to the caller's own scaling mode.
        if (source.PixelWidth != source.PixelHeight) return source;
        if (targetSize % source.PixelWidth != 0) return source;

        var scale = targetSize / source.PixelWidth;
        return scale <= 1 ? source : ScaleNearestNeighbor(source, scale);
    }

    private static BitmapImage? LoadOriginal(string name)
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

    private static BitmapSource ScaleNearestNeighbor(BitmapSource source, int scale)
    {
        // Normalize to BGRA so the byte layout is known regardless of the
        // source PNG's native format.
        var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0);

        int srcWidth = converted.PixelWidth;
        int srcHeight = converted.PixelHeight;
        int srcStride = srcWidth * 4;
        var srcPixels = new byte[srcStride * srcHeight];
        converted.CopyPixels(srcPixels, srcStride, 0);

        int destWidth = srcWidth * scale;
        int destStride = destWidth * 4;
        var destPixels = new byte[destStride * srcHeight * scale];

        for (int y = 0; y < srcHeight; y++)
        {
            for (int x = 0; x < srcWidth; x++)
            {
                int srcIndex = y * srcStride + x * 4;
                for (int dy = 0; dy < scale; dy++)
                {
                    int destRow = (y * scale + dy) * destStride;
                    for (int dx = 0; dx < scale; dx++)
                    {
                        int destIndex = destRow + (x * scale + dx) * 4;
                        destPixels[destIndex] = srcPixels[srcIndex];
                        destPixels[destIndex + 1] = srcPixels[srcIndex + 1];
                        destPixels[destIndex + 2] = srcPixels[srcIndex + 2];
                        destPixels[destIndex + 3] = srcPixels[srcIndex + 3];
                    }
                }
            }
        }

        var result = BitmapSource.Create(
            destWidth, srcHeight * scale, 96, 96,
            PixelFormats.Bgra32, null, destPixels, destStride);
        result.Freeze();
        return result;
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
            .Select(n => Inner.Convert(n, targetType, parameter, culture) as BitmapSource)
            .Where(img => img != null)
            .ToList();
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();
}
