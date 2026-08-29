const fs = require('fs');
let x = fs.readFileSync('Piraeus.BetterLandlord.UI/MainWindow.xaml', 'utf8');
const target = '                                                       RenderOptions.BitmapScalingMode="NearestNeighbor" />' + '\r\n';
x = x.replace(target, '');
fs.writeFileSync('Piraeus.BetterLandlord.UI/MainWindow.xaml', x, 'utf8');
console.log('Fixed line 270');
