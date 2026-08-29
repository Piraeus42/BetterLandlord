const fs = require("fs");
const path = "Piraeus.BetterLandlord.UI/MainWindow.xaml";
let xaml = fs.readFileSync(path, "utf8");

// Fix ActionEvent 16x16 (line ~118-119)
xaml = xaml.replace(
  '                    <Image Source="{Binding IconId, Converter={StaticResource IconImage}}"\n' +
  '                           Width="16" Height="16" Stretch="Uniform"',
  '                    <Image Source="{Binding IconId, Converter={StaticResource IconImage}}"\n' +
  '                           Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'
);

// Fix Summary symbol 22x22 (line ~266-268)
xaml = xaml.replace(
  '                                                <Image Source="{Binding Mode=OneWay, Converter={StaticResource IconImage}}"\n' +
  '                                                       Width="22" Height="22" Margin="2,0"\n' +
  '                                                       Stretch="Uniform"',
  '                                                <Image Source="{Binding Mode=OneWay, Converter={StaticResource IconImage}}"\n' +
  '                                                       Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Margin="2,0"\n' +
  '                                                       Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'
);

// Fix tooltip icons 18x18
xaml = xaml.replace(/Width="18" Height="18" Stretch="Uniform"/g, 'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"');

// Fix DPT ranking 14x14
xaml = xaml.replace(/Width="14" Height="14" Stretch="Uniform"/g, 'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"');

// Fix coin icon 14x14 (no Stretch)
xaml = xaml.replace(/Width="14" Height="14"(?!\s+Stretch)/g, 'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}"');

// Fix coin icon 15x15
xaml = xaml.replace(/Width="15" Height="15"/g, 'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}"');

fs.writeFileSync(path, xaml, "utf8");
console.log("Applied all remaining fixes");
