const fs = require("fs");
const path = "Piraeus.BetterLandlord.UI/MainWindow.xaml";
let xaml = fs.readFileSync(path, "utf8");

// 1. Add SizeFromIconConverter to resources
const iconImgIdx = xaml.indexOf('IconNameToImageConverter x:Key="IconImage" />');
if (iconImgIdx >= 0) {
  xaml = xaml.substring(0, iconImgIdx + 'IconNameToImageConverter x:Key="IconImage" />'.length) + 
         "\n        <conv:SizeFromIconConverter x:Key=\"IconSize\" />" + 
         xaml.substring(iconImgIdx + 'IconNameToImageConverter x:Key="IconImage" />'.length);
  console.log("Added IconSize converter");
}

// 2. Replace fixed sizes with dynamic binding
const replacements = [
  // 17x17 DeckSymbol
  [/Width="17" Height="17" HorizontalAlignment="Left" VerticalAlignment="Center"\s*\n\s*Stretch="Uniform"\s*\n\s*RenderOptions\.BitmapScalingMode="NearestNeighbor"/g, 
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" HorizontalAlignment="Left" VerticalAlignment="Center"\n                       Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'],
  // 16x16 ChoiceOption  
  [/Width="16" Height="16" Stretch="Uniform"\s*\n\s*RenderOptions\.BitmapScalingMode="NearestNeighbor"/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None"\n                                       RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'],
  // 16x16 ActionEvent
  [/Width="16" Height="16" Stretch="Uniform"(?!\s*\n\s*RenderOptions)/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'],
  // 22x22 Summary
  [/Width="22" Height="22" Margin="2,0"\s*\n\s*Stretch="Uniform"/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Margin="2,0"\n                                                       Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'],
  // 18x18 items
  [/Width="18" Height="18" Stretch="Uniform"/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'],
  // 14x14 DPT
  [/Width="14" Height="14" Stretch="Uniform"/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'],
  // 15x15 coin
  [/Width="15" Height="15"/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}"'],
  // 14x14 coins (without Stretch)
  [/Width="14" Height="14"(?!\s+Stretch)/g,
   'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}"'],
];

let count = 0;
for (const [pattern, replacement] of replacements) {
  const newStr = xaml.replace(pattern, replacement);
  if (newStr !== xaml) {
    console.log("Applied:", pattern.toString().slice(0, 50));
    xaml = newStr;
    count++;
  }
}

// Clean up any double-rendering issues
xaml = xaml.replace(/RenderOptions\.BitmapScalingMode="NearestNeighbor"\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"/g, 
                     'RenderOptions.BitmapScalingMode="NearestNeighbor"');
xaml = xaml.replace(/\n\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"\s*\/>/g, "");
xaml = xaml.replace(/\r?\n\s*\r?\n/g, "\n");

fs.writeFileSync(path, xaml, "utf8");
console.log("Done! Applied", count, "changes.");
console.log("Has IconSize:", xaml.includes("IconSize"));
