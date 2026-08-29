$content = Get-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Raw
# Remove all duplicate RenderOptions.BitmapScalingMode
$content = $content -replace 'RenderOptions\.BitmapScalingMode="NearestNeighbor"\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"', 'RenderOptions.BitmapScalingMode="NearestNeighbor"'
Set-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Value $content -NoNewline -Encoding UTF8
Write-Host 'Fixed all duplicates'
