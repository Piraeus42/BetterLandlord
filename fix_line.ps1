$content = Get-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Raw
# Direct string replacement
$old = 'RenderOptions.BitmapScalingMode="NearestNeighbor" />'
$new = 'RenderOptions.BitmapScalingMode="NearestNeighbor" />'
# Actually find and remove the duplicate line
$lines = $content -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq 'RenderOptions.BitmapScalingMode="NearestNeighbor" />') {
        $lines[$i] = ''
        Write-Host "Removed line $($i+1)"
    }
}
$content = $lines -join "`n"
Set-Content Piraeus.BetterLandlord.UI/MainWindow.xaml -Value $content -NoNewline -Encoding UTF8
Write-Host 'Done'
