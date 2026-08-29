const fs = require("fs");
const path = "Piraeus.BetterLandlord.UI/MainWindow.xaml";
let xaml = fs.readFileSync(path, "utf8");

// 1. Add SizeFromIconConverter to resources
xaml = xaml.replace(
  '<conv:IconNameToImageConverter x:Key="IconImage" />',
  '<conv:IconNameToImageConverter x:Key="IconImage" />\n        <conv:SizeFromIconConverter x:Key="IconSize" />'
);

// 2. Replace each Image element with proper dynamic sizing
// We need to handle multi-line Image elements carefully

// Pattern: find Image tags with fixed sizes and replace them
const imageRegex = /(<Image\s+Source="[^"]+"[^>]*?)Width="(\d+)" Height="\2"(?:\s+[^>]*)?>([^<]*)/g;

// Actually, let me just do targeted replacements for each known pattern

// DeckSymbol: 17x17
xaml = xaml.replace(
  /Source="{Binding IconId, Converter=\{StaticResource IconImage\}"\s*\n\s+Width="17" Height="17" HorizontalAlignment="Left" VerticalAlignment="Center"\s*\n\s+Stretch="Uniform"\s*\n\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"\s*>/g,
  'Source="{Binding IconId, Converter={StaticResource IconImage}}"\n                       Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" HorizontalAlignment="Left" VerticalAlignment="Center"\n                       Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />'
);

// ChoiceOption: 16x16
xaml = xaml.replace(
  /Source="{Binding IconId, Converter=\{StaticResource IconImage\}"\s*\n\s+Width="16" Height="16" Stretch="Uniform"\s*\n\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"\s*>/g,
  'Source="{Binding IconId, Converter={StaticResource IconImage}}"\n                                       Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None"\n                                       RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />'
);

// ActionEvent: 16x16
xaml = xaml.replace(
  /Source="{Binding IconId, Converter=\{StaticResource IconImage\}"\s*\n\s+Width="16" Height="16" Stretch="Uniform"\s*>/g,
  'Source="{Binding IconId, Converter={StaticResource IconImage}}"\n                           Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />'
);

// Summary symbol: 22x22
xaml = xaml.replace(
  /Source="{Binding Mode=OneWay, Converter=\{StaticResource IconImage\}"\s*\n\s+Width="22" Height="22" Margin="2,0"\s*\n\s+Stretch="Uniform"\s*\n\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"\s*>/g,
  'Source="{Binding Mode=OneWay, Converter={StaticResource IconImage}}"\n                                                       Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Margin="2,0"\n                                                       Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />'
);

// Items 18x18 (multiple occurrences)
xaml = xaml.replace(
  /Width="18" Height="18" Stretch="Uniform"/g,
  'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'
);

// DPT ranking: 14x14
xaml = xaml.replace(
  /Width="14" Height="14" Stretch="Uniform"/g,
  'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'
);

// Fix any leftover RenderOptions.BitmapScalingMode duplicates
xaml = xaml.replace(/RenderOptions\.BitmapScalingMode="NearestNeighbor"\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"/g, 'RenderOptions.BitmapScalingMode="NearestNeighbor"');

// Remove any orphaned lines with just RenderOptions
xaml = xaml.replace(/\n\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"\s*\/>/g, '');

fs.writeFileSync(path, xaml, "utf8");
console.log("Done! Applied all changes.");
console.log("Has IconSize:", xaml.includes("IconSize"));
console.log("Has EdgeMode:", xaml.includes("EdgeMode"));
