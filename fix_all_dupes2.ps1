$content = Get-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Raw
# Split into lines and fix each one
$lines = $content -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match 'BitmapScalingMode="NearestNeighbor".*BitmapScalingMode="NearestNeighbor"') {
        $line = $line -replace 'BitmapScalingMode="NearestNeighbor"\s+BitmapScalingMode="NearestNeighbor"', 'BitmapScalingMode="NearestNeighbor"'
        $lines[$i] = $line
    }
}
$content = $lines -join "`n"
Set-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Value $content -NoNewline -Encoding UTF8
Write-Host 'Fixed all lines with duplicates'
