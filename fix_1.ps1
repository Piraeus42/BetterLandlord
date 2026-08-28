# Fix MainWindow.xaml:
# 1. Restore HasTimelineData on ToggleButton (regressed to HasData)
# 2. Restore inline-right snapshot layout with WrapPanel

$path = "Piraeus.BetterLandlord.UI/MainWindow.xaml"
$text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Fix ToggleButton visibility
$text = $text -replace 'Visibility="{Binding HasData, Converter={StaticResource BoolToVis}}"`, `Visible', 'Visibility="{Binding HasTimelineData, Converter={StaticResource BoolToVis}}"'

# Save intermediate to check
[System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
Write-Host "MainWindow.xaml phase 1 done"
