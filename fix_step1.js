const fs = require("fs");
const path = "Piraeus.BetterLandlord.UI/MainWindow.xaml";
let xaml = fs.readFileSync(path, "utf8");

// Add SizeFromIconConverter after IconNameToImageConverter
xaml = xaml.replace(
  '        <conv:IconNameToImageConverter x:Key="IconImage" />\n',
  '        <conv:IconNameToImageConverter x:Key="IconImage" />\n        <conv:SizeFromIconConverter x:Key="IconSize" />\n'
);

// Fix DeckSymbol 17x17 (lines 34-36)
xaml = xaml.replace(
  '                <Image Source="{Binding IconId, Converter={StaticResource IconImage}}"\n' +
  '                       Width="17" Height="17" HorizontalAlignment="Left" VerticalAlignment="Center"\n' +
  '                       Stretch="Uniform" RenderOptions.BitmapScalingMode="NearestNeighbor" />',
  '                <Image Source="{Binding IconId, Converter={StaticResource IconImage}}"\n' +
  '                       Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" HorizontalAlignment="Left" VerticalAlignment="Center"\n' +
  '                       Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />'
);

// Fix ChoiceOption 16x16 (lines 81-83)
xaml = xaml.replace(
  '                                <Image Source="{Binding IconId, Converter={StaticResource IconImage}}"\n' +
  '                                       Width="16" Height="16" Stretch="Uniform"\n' +
  '                                       RenderOptions.BitmapScalingMode="NearestNeighbor" />',
  '                                <Image Source="{Binding IconId, Converter={StaticResource IconImage}}"\n' +
  '                                       Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}" Stretch="None"\n' +
  '                                       RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />'
);

fs.writeFileSync(path, xaml, "utf8");
console.log("Applied first two fixes");
