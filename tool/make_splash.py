"""Regenerate the launch mark from the brand lockup.

    python tool/make_splash.py

Run it whenever the lockup changes, or when a higher-resolution original
arrives -- see "Resolution" below.

Why this exists
---------------
launch_logo.png used to be an app-icon style asset: a rounded square filled
with solid #08543C, the wordmark running right to its edges. On the dark
splash it read as a lighter green tile floating on the background, and the
tile's own rounded corners cut the ends off "EHSAN PATHWAYS". On the light
splash it was a green block on cream.

So the mark is lifted off its ground instead of being pasted as a square:

1.  Luminance key. The lockup is bright -- gold emblem, white wordmark --
    on a dark ground, so luminance separates them. A smoothstep ramp
    between LO and HI keeps the cut edge from aliasing.

2.  Content mask. The artwork carries bokeh that is bright enough in places
    to clear the ramp; a glow in the top-right survived the key as a
    visible rectangular patch. Probing the gold-and-white pixels puts the
    whole lockup inside x 0.25-0.75 and y 0.30-0.80, so everything outside
    that box, generously feathered, is background by definition.

3.  Trim and square, so each density scales identically and nothing is
    distorted.

The splash colour is the same dark in both appearances (see
values/colors.xml and the iOS LaunchBackground colorset). A splash is a
half-second brand moment rather than a themed surface, and the lockup is
drawn on dark.

Resolution
----------
The supplied lockup is 500x500, of which the artwork itself occupies about
393px. The xxxhdpi asset is therefore upscaled, and will look slightly soft
on a 4x screen. An SVG or a PNG of 1500px or more would fix that with no
change to this script.
"""

import os

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "brand", "ehsanpathways-lockup.webp")
ANDROID = os.path.join(ROOT, "android", "app", "src", "main", "res")
IOS = os.path.join(
    ROOT, "ios", "Runner", "Assets.xcassets", "LaunchImage.imageset")

#: The mark's size in dp. It carries a wordmark and a tagline, so it needs
#: to be larger than a bare icon would.
DP = 180

DENSITIES = {
    "drawable-mdpi": 1.0,
    "drawable-hdpi": 1.5,
    "drawable-xhdpi": 2.0,
    "drawable-xxhdpi": 3.0,
    "drawable-xxxhdpi": 4.0,
}

#: Luminance ramp, read off the artwork: its ground runs 25-55, the green
#: ring around the emblem sits near 70-90, and the gold is 140 and above.
LO = 46.0
HI = 104.0

#: The box the lockup lives in, as fractions of the canvas, plus the
#: feather applied to it.
CONTENT_BOX = (0.17, 0.25, 0.83, 0.85)
FEATHER = 0.035


def lift(img):
    """Return the lockup with its ground made transparent."""
    rgb = img.convert("RGB")
    w, h = rgb.size

    # Blur the matte, not the colours: it softens the cut edge only.
    luma = rgb.convert("L").filter(ImageFilter.GaussianBlur(0.6))

    alpha = Image.new("L", (w, h), 0)
    src_px = luma.load()
    dst_px = alpha.load()
    span = HI - LO

    for y in range(h):
        for x in range(w):
            v = src_px[x, y]
            if v <= LO:
                continue
            if v >= HI:
                dst_px[x, y] = 255
                continue
            t = (v - LO) / span
            dst_px[x, y] = int(255 * (t * t * (3 - 2 * t)))

    content = Image.new("L", (w, h), 0)
    box = (
        int(CONTENT_BOX[0] * w), int(CONTENT_BOX[1] * h),
        int(CONTENT_BOX[2] * w), int(CONTENT_BOX[3] * h),
    )
    content.paste(255, box)
    content = content.filter(ImageFilter.GaussianBlur(w * FEATHER))

    alpha = Image.frombytes("L", (w, h), bytes(
        (a * c) // 255 for a, c in zip(alpha.tobytes(), content.tobytes())
    ))

    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def squared(mark):
    """Trim the empty border, then pad back to a square."""
    bbox = mark.getbbox()
    if bbox:
        mark = mark.crop(bbox)

    side = max(mark.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(
        mark,
        ((side - mark.size[0]) // 2, (side - mark.size[1]) // 2),
        mark,
    )
    return canvas


def main():
    if not os.path.isfile(SRC):
        raise SystemExit("no lockup at " + SRC)

    mark = squared(lift(Image.open(SRC)))
    print("lockup content: %dx%d" % mark.size)

    for folder, scale in DENSITIES.items():
        size = int(round(DP * scale))
        target = os.path.join(ANDROID, folder, "launch_logo.png")
        os.makedirs(os.path.dirname(target), exist_ok=True)
        mark.resize((size, size), Image.LANCZOS).save(target, "PNG")
        print("  %-18s %dx%d" % (folder, size, size))

    for suffix, scale in [("", 1), ("@2x", 2), ("@3x", 3)]:
        size = DP * scale
        target = os.path.join(IOS, "LaunchImage%s.png" % suffix)
        mark.resize((size, size), Image.LANCZOS).save(target, "PNG")
        print("  %-18s %dx%d" % ("LaunchImage" + suffix, size, size))

    if mark.size[0] < DP * 4:
        print()
        print("note: the source is smaller than the 4x asset (%d < %d), so"
              % (mark.size[0], DP * 4))
        print("      xxxhdpi is upscaled. A larger original would fix it.")


if __name__ == "__main__":
    main()
