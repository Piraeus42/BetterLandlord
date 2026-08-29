import re
with open(r'E:\code\betterLandlord\Piraeus.BetterLandlord.UI\MainWindow.xaml', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if '<Image' in line and 'Width=' in line:
        w = re.search(r'Width="(\d+)"', line)
        h = re.search(r'Height="(\d+)"', line)
        nn = 'NN' if 'NearestNeighbor' in line else 'HQ'
        print(f'L{i+1}: {(w.group(1) if w else "?")+"x"+(h.group(1) if h else "?"):6s} {nn}')
