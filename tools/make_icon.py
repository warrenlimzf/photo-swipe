"""Draws the app icon (three fanned photo prints on black). Run: python3 tools/make_icon.py"""
from PIL import Image, ImageDraw, ImageFilter
import os

S = 1024
NAVY, SOFT = (0, 0, 0), (38, 38, 40)
IVORY, GOLD, WHITE = (184, 184, 188), (115, 115, 120), (255, 255, 255)

bg = Image.new("RGB", (S, S))
px = bg.load()
for y in range(S):
    for x in range(S):
        t = (x + y) / (2 * S)
        px[x, y] = tuple(int(SOFT[k] * (1 - t) + NAVY[k] * t) for k in range(3))
bg = bg.convert("RGBA")

W, H, R = 400, 512, 82

def card(color, scene=False):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0 = (S - W) // 2, (S - H) // 2 + 10
    d.rounded_rectangle([x0, y0, x0 + W, y0 + H], R, fill=color)
    if scene:
        m = 40
        inner = Image.new("RGBA", (W - 2 * m, H - 2 * m), IVORY)
        di = ImageDraw.Draw(inner)
        iw, ih = inner.size
        di.ellipse([iw * 0.58, ih * 0.14, iw * 0.58 + 92, ih * 0.14 + 92], fill=GOLD)
        di.ellipse([-iw * 0.5, ih * 0.52, iw * 0.75, ih * 1.5], fill=(107, 124, 160))
        di.ellipse([iw * 0.15, ih * 0.66, iw * 1.4, ih * 1.6], fill=NAVY)
        mask = Image.new("L", inner.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, iw, ih], 52, fill=255)
        layer.paste(inner, (x0 + m, y0 + m), mask)
    return layer

def place(layer, angle, dx):
    pivot = (S // 2, (S + H) // 2 + 10)
    rotated = layer.rotate(angle, resample=Image.BICUBIC, center=pivot, translate=(dx, 0))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 90), (0, 26), rotated.split()[3])
    bg.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    bg.alpha_composite(rotated)

place(card(GOLD), 16, -124)
place(card(IVORY), -16, 124)
place(card(WHITE), 0, 0)

out = os.path.join(os.path.dirname(__file__), "..", "App", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")
bg.convert("RGB").save(out)
print("wrote", os.path.normpath(out))
