from PIL import Image
import os, sys

icon_dir = r"E:\code\betterLandlord\Piraeus.BetterLandlord.UI\Assets\Icons"
out_dir  = r"E:\code\betterLandlord\artifacts\icon_comparison"
os.makedirs(out_dir, exist_ok=True)

samples = [
    ("a1.png",       "16x16 symbol"),
    ("coin.png",     "12x12 commodity"),
    ("wildcard.png", "22x22 special"),
    ("tt.png",       "12x12 tiny"),
    ("a1-L.png",     "16x16 light"),
]
display_sizes = [16, 17, 22]

for name, desc in samples:
    src = os.path.join(icon_dir, name)
    if not os.path.exists(src):
        print(f"SKIP {name}")
        continue
    img = Image.open(src).convert("RGBA")
    w0, h0 = img.size
    print(f"{name}: {w0}x{h0}")

    for disp in display_sizes:
        orig   = img.resize((disp, disp), Image.Resampling.NEAREST)
        big2x  = img.resize((w0*2, h0*2), Image.Resampling.LANCZOS).resize((disp, disp), Image.Resampling.LANCZOS)
        big3x  = img.resize((w0*3, h0*3), Image.Resampling.LANCZOS).resize((disp, disp), Image.Resampling.LANCZOS)

        cell_w = disp + 6
        grid   = Image.new("RGBA", (cell_w*3, disp + 14), (30, 30, 46, 255))
        for i, cell in enumerate([orig, big2x, big3x]):
            grid.paste(cell, (i * cell_w, 0))
        out = os.path.join(out_dir, f"{name.replace('.png','')}_disp{disp}.png")
        grid.convert("RGB").save(out, "PNG")
        print(f"  saved {out}")

print("\nDone")
