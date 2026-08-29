const fs = require('fs');
const path = 'Piraeus.BetterLandlord.UI/MainWindow.xaml';
let xaml = fs.readFileSync(path, 'utf8');

// Remove duplicate RenderOptions.BitmapScalingMode
xaml = xaml.replace(/RenderOptions\.BitmapScalingMode="NearestNeighbor"\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"/g, 'RenderOptions.BitmapScalingMode="NearestNeighbor"');

fs.writeFileSync(path, xaml, 'utf8');
console.log('Fixed duplicates');

// Verify build
const { execSync } = require('child_process');
try {
  execSync('dotnet build Piraeus.BetterLandlord.UI/Piraeus.BetterLandlord.UI.csproj', { encoding: 'utf8', stdio: 'pipe' });
  console.log('Build successful!');
} catch(e) {
  console.log('Build error:', e.message);
}
