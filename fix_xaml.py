import sys
p=r"E:\code\betterLandlord\Piraeus.BetterLandlord.UI\MainWindow.xaml"
with open(p,"r",encoding="utf-8") as f: lines=f.readlines()
for i,x in enumerate(lines):
    if "Width=\"14\" Height=\"14\" Stretch=\"None\"" in x and "BitmapScalingMode" not in x:
        print("Found at",i+1)
        lines[i]=x.rstrip()+" RenderOptions.BitmapScalingMode=\"NearestNeighbor\" />"
        break
with open(p,"w",encoding="utf-8") as f: f.writelines(lines)
print("Done")
