$content = Get-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Raw
$old = 'Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True" RenderOptions.BitmapScalingMode="NearestNeighbor"'
$new = 'Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"'
if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
    Set-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Value $content -NoNewline -Encoding UTF8
    Write-Host 'Fixed duplicates'
} else {
    Write-Host 'Pattern not found'
}
