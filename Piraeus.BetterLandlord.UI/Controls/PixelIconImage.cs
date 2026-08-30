using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Piraeus.BetterLandlord.UI.Services;

namespace Piraeus.BetterLandlord.UI.Controls;

/// <summary>
/// Displays an icon at an explicit square size. The bitmap handed over by
/// <see cref="IconProvider"/> already matches the requested size exactly
/// (nearest-neighbor replication for integer multiples, CPU resampling
/// otherwise), so the image is always drawn 1:1 and WPF never scales it.
/// </summary>
public class PixelIconImage : Image
{
    public static readonly DependencyProperty IconNameProperty = DependencyProperty.Register(
        nameof(IconName), typeof(string), typeof(PixelIconImage),
        new PropertyMetadata(null, OnIconChanged));

    public static readonly DependencyProperty DisplaySizeProperty = DependencyProperty.Register(
        nameof(DisplaySize), typeof(double), typeof(PixelIconImage),
        new PropertyMetadata(0d, OnIconChanged));

    static PixelIconImage()
    {
        StretchProperty.OverrideMetadata(typeof(PixelIconImage), new FrameworkPropertyMetadata(System.Windows.Media.Stretch.None));
        SnapsToDevicePixelsProperty.OverrideMetadata(typeof(PixelIconImage), new FrameworkPropertyMetadata(true));
        UseLayoutRoundingProperty.OverrideMetadata(typeof(PixelIconImage), new FrameworkPropertyMetadata(true));
    }

    public PixelIconImage()
    {
        Loaded += (_, _) => Refresh();
        DpiChanged += (_, _) => Refresh();
    }

    public string? IconName
    {
        get => (string?)GetValue(IconNameProperty);
        set => SetValue(IconNameProperty, value);
    }

    public double DisplaySize
    {
        get => (double)GetValue(DisplaySizeProperty);
        set => SetValue(DisplaySizeProperty, value);
    }

    private static void OnIconChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        => ((PixelIconImage)d).Refresh();

    private void Refresh()
    {
        var logicalSize = (int)Math.Round(DisplaySize);
        if (logicalSize <= 0)
        {
            Source = null;
            return;
        }

        var dpiScale = IsLoaded ? VisualTreeHelper.GetDpi(this).PixelsPerDip : 1.0;
        var physicalSize = Math.Max(1, (int)Math.Round(logicalSize * dpiScale));
        Source = IconProvider.GetIcon(IconName, physicalSize, dpiScale);

        // The bitmap's DPI metadata encodes the monitor scale, so its natural
        // DIP size can differ from the XAML DisplaySize by a fraction of a
        // pixel. Keeping these values derived avoids a final WPF transform.
        Width = physicalSize / dpiScale;
        Height = physicalSize / dpiScale;
    }
}
