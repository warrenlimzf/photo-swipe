"""Draws the app icon: three white photo prints fanned on the tangerine brand gradient, the front
one holding a little drawn landscape and a green keep tick. Same drawing as `PrintStack` in the app.
Run: python3 tools/make_icon.py  (writes the 1024 icon and the README copy)"""
from PIL import Image, ImageDraw, ImageFilter
import os

K = 2                      # draw at 2x, scale down at the end for clean edges
S = 1024 * K

def lerp(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))

DEEP, BRIGHT = (226, 82, 15), (255, 138, 31)      # Theme.b700 -> Theme.b500
GLOW = (255, 201, 142)                            # Theme.b300
KEEP_TOP, KEEP = (43, 194, 123), (22, 163, 99)

# Background: diagonal gradient plus a soft glow top right, like HeroShape.
bg = Image.new("RGB", (S, S))
px = bg.load()
for y in range(S):
    for x in range(S):
        px[x, y] = lerp(DEEP, BRIGHT, (x + y) / (2 * S))
bg = bg.convert("RGBA")
glow = Image.new("RGBA", (S, S), GLOW + (0,))   # transparent glow-coloured, so the blur never pulls in black
ImageDraw.Draw(glow).ellipse([S * 0.45, -S * 0.35, S * 1.35, S * 0.55], fill=GLOW + (150,))
bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(140 * K)))

W, H, R = 400 * K, 508 * K, 52 * K

def print_card(sky_top, sky_bottom, hill_back, hill_front):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0 = (S - W) // 2, (S - H) // 2 + 40 * K
    d.rounded_rectangle([x0, y0, x0 + W, y0 + H], R, fill=(255, 255, 255, 255))
    m = 30 * K
    iw, ih = W - 2 * m, H - 2 * m - 90 * K
    inner = Image.new("RGBA", (iw, ih))
    ip = inner.load()
    for yy in range(ih):
        c = lerp(sky_top, sky_bottom, yy / ih)
        for xx in range(iw):
            ip[xx, yy] = c + (255,)
    di = ImageDraw.Draw(inner)
    di.ellipse([iw * 0.6, ih * 0.14, iw * 0.6 + 86 * K, ih * 0.14 + 86 * K], fill=(255, 201, 77))
    di.ellipse([-iw * 0.55, ih * 0.58, iw * 0.8, ih * 1.5], fill=hill_back)
    di.ellipse([iw * 0.05, ih * 0.7, iw * 1.5, ih * 1.6], fill=hill_front)
    mask = Image.new("L", (iw, ih), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, iw, ih], 26 * K, fill=255)
    layer.paste(inner, (x0 + m, y0 + m), mask)
    return layer, (x0, y0)

def place(layer, angle, dx, dy=0):
    pivot = (S // 2, (S + H) // 2 + 40 * K)
    rotated = layer.rotate(angle, resample=Image.BICUBIC, center=pivot, translate=(dx, dy))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.paste((70, 20, 0, 110), (0, 30 * K), rotated.split()[3])
    bg.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(30 * K)))
    bg.alpha_composite(rotated)

back_left, _ = print_card((255, 215, 168), (255, 241, 222), (127, 191, 142), (62, 141, 91))
back_right, _ = print_card((191, 230, 255), (234, 247, 255), (127, 191, 142), (62, 141, 91))
front, (fx, fy) = print_card((255, 201, 142), (255, 240, 226), (255, 165, 90), (226, 82, 15))

place(back_left, 14, -150 * K, 10 * K)
place(back_right, -12, 150 * K, 6 * K)
place(front, -4, 18 * K, -14 * K)

# The keep tick, popping off the front print's top-left corner.
badge = Image.new("RGBA", (S, S), (0, 0, 0, 0))
bd = ImageDraw.Draw(badge)
cx, cy, r = fx + 40 * K, fy - 4 * K, 92 * K
for i in range(r, 0, -1):
    bd.ellipse([cx - i, cy - i, cx + i, cy + i], fill=lerp(KEEP, KEEP_TOP, i / r) + (255,))
bd.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255, 255), width=14 * K)
bd.line([(cx - 40 * K, cy + 2 * K), (cx - 10 * K, cy + 32 * K), (cx + 44 * K, cy - 30 * K)],
        fill=(255, 255, 255, 255), width=24 * K, joint="curve")
for (px_, py_) in [(cx - 40 * K, cy + 2 * K), (cx + 44 * K, cy - 30 * K)]:
    bd.ellipse([px_ - 12 * K, py_ - 12 * K, px_ + 12 * K, py_ + 12 * K], fill=(255, 255, 255, 255))
badge = badge.rotate(-4, resample=Image.BICUBIC, center=(S // 2, (S + H) // 2 + 40 * K), translate=(18 * K, -14 * K))
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
shadow.paste((0, 60, 30, 120), (0, 16 * K), badge.split()[3])
bg.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(18 * K)))
bg.alpha_composite(badge)

icon = bg.convert("RGB").resize((1024, 1024), Image.LANCZOS)
here = os.path.dirname(__file__)
out = os.path.join(here, "..", "App", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")
icon.save(out)
icon.resize((256, 256), Image.LANCZOS).save(os.path.join(here, "..", "docs", "screenshots", "icon.png"))
print("wrote", os.path.normpath(out))
