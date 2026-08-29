const fs = require('fs');
let x = fs.readFileSync('Piraeus.BetterLandlord.UI/MainWindow.xaml', 'utf8');
// Remove the duplicate RenderOptions.BitmapScalingMode line
x = x.replace(/                                                        RenderOptions\.BitmapScalingMode="NearestNeighbor" \/>\n/g, '');
fs.writeFileSync('Piraeus.BetterLandlord.UI/MainWindow.xaml', x, 'utf8');
console.log('Removed duplicate line');
const lines = x.split('\n');
console.log('Line 269:', JSON.stringify(lines[268]));
console.log('Line 270:', JSON.stringify(lines[269]));
