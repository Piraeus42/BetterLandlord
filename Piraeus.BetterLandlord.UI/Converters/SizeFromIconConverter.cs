using System;
using System.Collections.Concurrent;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Windows.Data;
using System.Windows.Media.Imaging;

namespace Piraeus.BetterLandlord.UI.Converters;

/// <summary>
/// Converts an icon name to its display size in pixels.
/// Loads the source image to determine its natural size,
/// then returns the largest integer multiple that fits within IconSizes.CellSize.
/// </summary>
public class SizeFromIconConverter : IValueConverter
{
    private static readonly ConcurrentDictionary<string, double> Cache = new();
    private static readonly Assembly Assembly;
    private const string ResourcePrefix = "Piraeus.BetterLandlord.UI.Assets.Icons.";

    static SizeFromIconConverter()
    {
        Assembly = typeof(IconNameToImageConverter).Assembly;
    }

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        // Support both direct value and ConverterParameter
        var name = value?.ToString() ?? (parameter as string);
        if (string.IsNullOrEmpty(name)) return IconSizes.CellSize;

        return Cache.GetOrAdd(name, ComputeSize);
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => throw new NotImplementedException();

    private static double ComputeSize(string name)
    {
        // Try exact case first, then lowercase
        var names = new[] { name, name.ToLowerInvariant() };
        foreach (var n in names)
        {
            var resourceName = ResourcePrefix + n + ".png";
            using var stream = Assembly.GetManifestResourceStream(resourceName);
            if (stream == null) continue;

            try
            {
                stream.Seek(0, SeekOrigin.Begin);
                var frame = BitmapFrame.Create(stream, BitmapCreateOptions.None, BitmapCacheOption.OnLoad);
                var sourceSize = Math.Max(frame.PixelWidth, frame.PixelHeight);
                return sourceSize > 0 ? IconSizes.ComputeDisplaySize(sourceSize) : IconSizes.CellSize;
            }
            catch
            {
                return IconSizes.CellSize;
            }
        }

        return IconSizes.CellSize;
    }
}
