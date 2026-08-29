p = r'E:\code\betterLandlord\Piraeus.BetterLandlord.UI\MainWindow.xaml'
text = open(p, encoding='utf-8-sig').read()
old = '''                </ItemsControl>
            </StackPanel>
        </DataTemplate>

        <DataTemplate DataType="{x:Type vm:ActionEventViewModel}">
'''
new = '''                </ItemsControl>
                <Border Background="#332B40" BorderBrush="#89B4FA" BorderThickness="1"
                        CornerRadius="2" Padding="3,1" Margin="3,0,0,0"
                        Visibility="{Binding IsRerolled, Converter={StaticResource BoolToVis}}">
                    <TextBlock Text="已重抽" FontSize="8" Foreground="#89B4FA" />
                </Border>
            </StackPanel>
        </DataTemplate>

        <DataTemplate DataType="{x:Type vm:ActionEventViewModel}">
'''
if old not in text:
    raise SystemExit('target block not found')
text = text.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(text)
print('OK')
