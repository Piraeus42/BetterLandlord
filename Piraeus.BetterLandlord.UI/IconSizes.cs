using System;
using System.Windows;

namespace Piraeus.BetterLandlord.UI
{
    /// <summary>
    /// Global icon cell size. All icons are displayed at their native resolution
    /// within a cell of this size using Stretch="None".
    /// </summary>
    public static class IconSizes
    {
        /// <summary>Cell size in pixels</summary>
        public const double CellSize = 24;

        /// <summary>
        /// Computes the display size for an icon of the given source size.
        /// Returns the largest integer multiple of sourceSize that fits within CellSize.
        /// </summary>
        public static double ComputeDisplaySize(double sourceSize)
        {
            if (sourceSize <= 0) return CellSize;
            var multiple = Math.Max(1, Math.Floor(CellSize / sourceSize));
            return multiple * sourceSize;
        }

        /// <summary>
        /// Gets the display size for a known icon source size.
        /// </summary>
        public static double GetSizeForSource(int sourceSize)
        {
            return ComputeDisplaySize(sourceSize);
        }
    }
}
