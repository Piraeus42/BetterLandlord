import re

with open('Piraeus.BetterLandlord.UI/MainWindow.xaml', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add SizeFromIconConverter registration after IconImage
if 'SizeFromIconConverter' not in content:
    content = content.replace(
        '<conv:IconNameToImageConverter x:Key="IconImage" />',
        '<conv:IconNameToImageConverter x:Key="IconImage" />\n        <conv:SizeFromIconConverter x:Key="IconSize" />'
    )
    print('Added SizeFromIconConverter registration')

# 2. Add optimization attributes to Image elements using IconSize
lines = content.split('\n')
new_lines = []
for i, line in enumerate(lines):
    new_lines.append(line)
    # Check if this line has IconSize but no Stretch
    if 'IconSize' in line and 'Stretch' not in line:
        # Check if next line also has IconSize (multi-line Image)
        if i + 1 < len(lines) and 'IconSize' in lines[i+1] and 'Stretch' not in lines[i+1]:
            indent = len(line) - len(line.lstrip())
            new_lines.append(' ' * indent + 'Stretch="None" RenderOptions.BitmapScalingMode="NearestNeighbor" RenderOptions.EdgeMode="Aliased" SnapsToDevicePixels="True"')

content = '\n'.join(new_lines)

with open('Piraeus.BetterLandlord.UI/MainWindow.xaml', 'w', encoding='utf-8') as f:
    f.write(content)

print('File updated successfully')
