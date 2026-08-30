using System.Collections.Concurrent;
using System.Reflection;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace Piraeus.BetterLandlord.UI.Services;

/// <summary>
/// Single source for icon bitmaps. Loads embedded PNGs, strips workshop name
/// suffixes, and returns a bitmap sized for the monitor's physical pixels:
/// integer multiples use nearest-neighbor replication and everything else is
/// resampled on the CPU. DPI metadata makes the result map 1:1 on the target
/// monitor, so WPF is never asked to interpolate pixel art.
/// </summary>
public static class IconProvider
{
    private const string ResourcePrefix = "Piraeus.BetterLandlord.UI.Assets.Icons.";
    private static readonly Assembly Assembly = typeof(IconProvider).Assembly;
    private static readonly ConcurrentDictionary<(string Name, int TargetSize, double DpiScale), BitmapSource?> Cache = new();

    public static BitmapSource? GetIcon(string? name, int targetPhysicalSize = 0, double dpiScale = 1.0)
    {
        if (string.IsNullOrEmpty(name)) return null;

        var normalized = NormalizeName(name);
        dpiScale = Math.Clamp(dpiScale, 0.1, 10.0);
        return Cache.GetOrAdd((normalized, targetPhysicalSize, Math.Round(dpiScale, 4)), static key =>
            Load(key.Name, key.TargetSize, key.DpiScale));
    }

    private static string NormalizeName(string name)
    {
        const string steamIdSuffix = "_STEAM_ID_";
        var suffixIndex = name.IndexOf(steamIdSuffix, StringComparison.Ordinal);
        return suffixIndex > 0 ? name[..suffixIndex] : name;
    }

    private static BitmapSource? Load(string name, int targetPhysicalSize, double dpiScale)
    {
        var source = LoadOriginal(name);
        if (source == null || targetPhysicalSize <= 0) return source;
        if (targetPhysicalSize == source.PixelWidth && targetPhysicalSize == source.PixelHeight)
            return WithDpi(source, dpiScale);

        if (source.PixelWidth == source.PixelHeight && targetPhysicalSize % source.PixelWidth == 0)
            return ScaleNearestNeighbor(source, targetPhysicalSize / source.PixelWidth, dpiScale);

        return ResampleSmooth(source, targetPhysicalSize, targetPhysicalSize, dpiScale);
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

    private static BitmapSource ScaleNearestNeighbor(BitmapSource source, int scale, double dpiScale)
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
            destWidth, srcHeight * scale,
            96 * dpiScale, 96 * dpiScale,
            PixelFormats.Bgra32, null, destPixels, destStride);
        result.Freeze();
        return result;
    }

    private static BitmapSource ResampleSmooth(BitmapSource source, int targetWidth, int targetHeight, double dpiScale)
    {
        var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0);

        int srcWidth = converted.PixelWidth;
        int srcHeight = converted.PixelHeight;
        int srcStride = srcWidth * 4;
        var srcPixels = new byte[srcStride * srcHeight];
        converted.CopyPixels(srcPixels, srcStride, 0);

        var destPixels = new byte[targetWidth * targetHeight * 4];
        float scaleX = (float)srcWidth / targetWidth;
        float scaleY = (float)srcHeight / targetHeight;

        for (int dy = 0; dy < targetHeight; dy++)
        {
            float srcY0 = dy * scaleY;
            float srcY1 = (dy + 1) * scaleY;
            int yStart = Math.Min((int)srcY0, srcHeight - 1);
            int yEnd = Math.Min((int)MathF.Ceiling(srcY1), srcHeight);

            for (int dx = 0; dx < targetWidth; dx++)
            {
                float srcX0 = dx * scaleX;
                float srcX1 = (dx + 1) * scaleX;
                int xStart = Math.Min((int)srcX0, srcWidth - 1);
                int xEnd = Math.Min((int)MathF.Ceiling(srcX1), srcWidth);

                // Average in premultiplied alpha so fully transparent pixels
                // contribute color instead of darkening edges.
                float accB = 0, accG = 0, accR = 0, accA = 0, accWeight = 0;
                for (int y = yStart; y < yEnd; y++)
                {
                    float weightY = Math.Min(srcY1, y + 1) - Math.Max(srcY0, y);
                    if (weightY <= 0) continue;

                    for (int x = xStart; x < xEnd; x++)
                    {
                        float weightX = Math.Min(srcX1, x + 1) - Math.Max(srcX0, x);
                        if (weightX <= 0) continue;

                        float weight = weightX * weightY;
                        int offset = (y * srcWidth + x) * 4;
                        float alpha = srcPixels[offset + 3] / 255f;

                        accB += srcPixels[offset] * alpha * weight;
                        accG += srcPixels[offset + 1] * alpha * weight;
                        accR += srcPixels[offset + 2] * alpha * weight;
                        accA += srcPixels[offset + 3] * weight;
                        accWeight += weight;
                    }
                }

                if (accWeight <= 0 || accA <= 0) continue;

                int destIndex = (dy * targetWidth + dx) * 4;
                destPixels[destIndex] = (byte)Math.Clamp((int)MathF.Round(accB * 255f / accA), 0, 255);
                destPixels[destIndex + 1] = (byte)Math.Clamp((int)MathF.Round(accG * 255f / accA), 0, 255);
                destPixels[destIndex + 2] = (byte)Math.Clamp((int)MathF.Round(accR * 255f / accA), 0, 255);
                destPixels[destIndex + 3] = (byte)Math.Clamp((int)MathF.Round(accA / accWeight), 0, 255);
            }
        }

        var result = BitmapSource.Create(
            targetWidth, targetHeight, 96 * dpiScale, 96 * dpiScale,
            PixelFormats.Bgra32, null, destPixels, targetWidth * 4);
        result.Freeze();
        return result;
    }

    private static BitmapSource WithDpi(BitmapSource source, double dpiScale)
    {
        if (Math.Abs(source.DpiX - 96 * dpiScale) < 0.01
            && Math.Abs(source.DpiY - 96 * dpiScale) < 0.01)
            return source;

        var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0);
        var result = BitmapSource.Create(
            converted.PixelWidth, converted.PixelHeight,
            96 * dpiScale, 96 * dpiScale,
            PixelFormats.Bgra32, null, GetPixels(converted), converted.PixelWidth * 4);
        result.Freeze();
        return result;
    }

    private static byte[] GetPixels(BitmapSource source)
    {
        var stride = source.PixelWidth * 4;
        var pixels = new byte[stride * source.PixelHeight];
        source.CopyPixels(pixels, stride, 0);
        return pixels;
    }
}
