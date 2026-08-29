const fs = require('fs');
const path = 'Piraeus.BetterLandlord.UI/MainWindow.xaml';
let xaml = fs.readFileSync(path, 'utf8');

// Add SizeFromIconConverter to resources (after IconNameToImageConverter)
const lines = xaml.split('\n');
const insertIdx = lines.findIndex(l => l.includes('IconNameToImageConverter') && l.includes('Key="IconImage"'));
if (insertIdx >= 0) {
  lines.splice(insertIdx + 1, 0, '        <conv:SizeFromIconConverter x:Key="IconSize" />');
  xaml = lines.join('\n');
  console.log('Added IconSize converter at line', insertIdx + 2);
}

// Fix each Image element by replacing Width/Height with converter binding
// and adding pixel-snapping attributes
const imagePattern = /(<Image [^>]*Width="(\d+)" Height="\2"[^>]*Stretch="Uniform"[^>]*)>/g;
let match;
let count = 0;
while ((match = imagePattern.exec(xaml)) !== null) {
  const fullMatch = match[1];
  const size = match[2];
  
  // Skip coin icons (they use ConverterParameter=coin, not icon name binding)
  if (fullMatch.includes('ConverterParameter=coin')) continue;
  
  // Replace fixed size with dynamic binding
  let newAttrs = fullMatch
    .replace('Width="' + size + '" Height="' + size + '"', 'Width="{Binding Converter={StaticResource IconSize}}" Height="{Binding Converter={StaticResource IconSize}}"')
    .replace('Stretch="Uniform"', 'Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"');
  
  xaml = xaml.replace(fullMatch + '>', newAttrs + '>');
  count++;
  console.log('Fixed', size + 'x' + size + ' image');
}

// Also fix images with different sizes like 14x14 coins - keep fixed but add pixel snapping
const coinPattern = /(<Image [^>]*Width="14" Height="14"[^>]*)(?!(?:.*Stretch="Uniform"))/g;
while ((match = coinPattern.exec(xaml)) !== null) {
  const fullMatch = match[1];
  if (fullMatch.includes('ConverterParameter=coin')) {
    // Add pixel snapping to coin icons too
    if (!fullMatch.includes('SnapsToDevicePixels')) {
      let newAttrs = fullMatch + ' RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"';
      xaml = xaml.replace(fullMatch + '>', newAttrs + '>');
      console.log('Added pixel snapping to 14x14 coin');
    }
  }
}

fs.writeFileSync(path, xaml, 'utf8');
console.log('Done! Applied', count, 'icon size fixes.');
console.log('Has IconSize:', xaml.includes('IconSize'));
