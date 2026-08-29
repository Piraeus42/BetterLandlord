='E:\\code\\betterLandlord\\Piraeus.BetterLandlord.UI\\MainWindow.xaml'
=Get-Content  -Raw
=-replace 'Width=\ 14\ Height=\14\ Stretch=\Uniform\','Width=\14\ Height=\14\ Stretch=\None\ RenderOptions.BitmapScalingMode=\NearestNeighbor\'
Set-Content  -Value  -NoNewline
