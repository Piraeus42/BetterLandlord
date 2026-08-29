
$path = "E:\code\betterLandlord\Piraeus.BetterLandlord.UI\MainWindow.xaml"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# 1. Add SnapsToDevicePixels and UseLayoutRounding to Window
$content = $content -replace "<Window x:Class=", "<Window SnapsToDevicePixels=`"True`" UseLayoutRounding=`"True`" x:Class="

# 2. For self-closing Image tags: <Image ... /> -> <Image ... SnapsToDevicePixels="True" RenderOptions.EdgeMode="Aliased" />
$content = $content -replace "(<Image[^>]*)(\s*/>)", "$1 SnapsToDevicePixels=`"True`" RenderOptions.EdgeMode=`"Aliased`"$2"

# 3. For opening Image tags without self-close: <Image ...> -> <Image ... SnapsToDevicePixels="True" RenderOptions.EdgeMode="Aliased">
$content = $content -replace "(<Image[^>]*)(?>(?!</Image>))", {param($m); if ($m.Value -notmatch "</Image>" -and $m.Value -notmatch "/>") { $m.Value -replace ">", " SnapsToDevicePixels=`"True`" RenderOptions.EdgeMode=`"Aliased`">" } else { $m.Value }},
[System.Text.RegularExpressions.RegexOptions]::Singleline

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Host "Done"

