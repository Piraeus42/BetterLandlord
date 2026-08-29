$content = Get-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Raw
# Remove line that only contains duplicate RenderOptions
$content = $content -replace '`n\s+RenderOptions\.BitmapScalingMode="NearestNeighbor"\s*/>', ''
Set-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Value $content -NoNewline -Encoding UTF8
Write-Host 'Fixed trailing duplicate'
