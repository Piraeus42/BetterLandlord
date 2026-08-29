p = r"E:\code\betterLandlord\Piraeus.BetterLandlord.UI\MainWindow.xaml"
text = open(p, encoding="utf-8-sig").read()

# Remove the "已重抽" badge from ChoiceGroupViewModel template
old = '''                </ItemsControl>
                <Border Background="#332B40" BorderBrush="#89B4FA" BorderThickness="1"
                        CornerRadius="2" Padding="3,1" Margin="3,0,0,0"
                        Visibility="{Binding IsRerolled, Converter={StaticResource BoolToVis}}">
                    <TextBlock Text="已重抽" FontSize="8" Foreground="#89B4FA" />
                </Border>
            </StackPanel>
        </DataTemplate>

        <DataTemplate DataType="{x:Type vm:ActionEventViewModel}">'''
new = '''                </ItemsControl>
            </StackPanel>
        </DataTemplate>

        <DataTemplate DataType="{x:Type vm:ActionEventViewModel}">'''
if old not in text:
    raise SystemExit("ChoiceGroup badge not found")
text = text.replace(old, new, 1)

# Change "重掷" badge color from blue to green
old2 = 'BorderBrush="#89B4FA"'
new2 = 'BorderBrush="#A6E3A1"'
# Only replace the first occurrence (the reroll badge)
text = text.replace(old2, new2, 1)

old3 = 'Foreground="#89B4FA" />'
new3 = 'Foreground="#A6E3A1" />'
# Only replace the first occurrence (the reroll badge textblock)
text = text.replace(old3, new3, 1)

open(p, "w", encoding="utf-8", newline="\r\n").write(text)
print("OK")
