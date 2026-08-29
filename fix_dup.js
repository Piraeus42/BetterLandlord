const fs = require('fs');
let x = fs.readFileSync('Piraeus.BetterLandlord.UI/MainWindow.xaml', 'utf8');
x = x.replace(/Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"\n                                                        RenderOptions.BitmapScalingMode="NearestNeighbor" \/>/g, 'Stretch="None" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" />');
fs.writeFileSync('Piraeus.BetterLandlord.UI/MainWindow.xaml', x, 'utf8');
console.log('Fixed duplicates');
const lines = x.split('\n');
lines.slice(266, 272).forEach((l, i) => console.log((i + 267) + ': ' + l));
