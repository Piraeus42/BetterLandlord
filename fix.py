import sys
path = r\ E:\\code\\betterLandlord\\Piraeus.BetterLandlord.UI\\MainWindow.xaml\
with open(path, \ r\, encoding=\utf-8\) as f:
    content = f.read()
content = content.replace(\ Stretch=\\\Uniform\\\\, \Stretch=\\\None\\\\)
    f.write(content)
with open(path, \ w\, encoding=\utf-8\) as f:
print(\ Fixed\)
