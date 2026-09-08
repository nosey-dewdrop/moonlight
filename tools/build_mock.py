#!/opt/homebrew/bin/python3
"""Moonlight mock builder.
Classifies MJ files by the prompt words baked into their filenames, cleans
their paper/colour backgrounds, and writes a single-phone atmospheric mock
(mock.html) on the chosen sky."""
import os, glob, itertools
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

RAW = os.path.expanduser("~/moonlight/assets_raw")
OUT = os.path.join(RAW, "processed")
os.makedirs(OUT, exist_ok=True)

def classify(name):
    n = name.lower()
    if "night_s" in n or "mj.run" in n:   return "bg"
    if "full_moon" in n:                  return "moon"
    if "glowi" in n:                      return "nebula"   # purple galaxy squares, NOT sparkles
    if "sparkle" in n:                    return "sparkle"
    if "stars_and" in n or "_star" in n:  return "star"
    if "cloud" in n:                      return "cloud"
    return "other"

def cut_paper(im, thresh=42):
    """Flood-fill the white paper from the 4 corners -> transparent, keeping
    pale tones inside the artwork. For clouds / moon (white paper margins)."""
    rgb = im.convert("RGB"); w, h = rgb.size
    mark = rgb.copy(); S = (255, 0, 255)
    for xy in [(1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2)]:
        ImageDraw.floodfill(mark, xy, S, thresh=thresh)
    m = np.asarray(mark)
    bg = (m[:, :, 0] == 255) & (m[:, :, 1] == 0) & (m[:, :, 2] == 255)
    alpha = np.where(bg, 0, 255).astype(np.uint8)
    alpha = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(1.2))
    img = Image.merge("RGBA", (*rgb.split(), alpha))
    b = img.getbbox()
    return img.crop(b) if b else img

def cut_warm(im, lo=22, hi=70):
    """Keep only warm/gold strokes; drop both white paper AND blue smudge.
    warmth = R - B: gold is strongly positive, blue negative, white ~0."""
    rgb = im.convert("RGB")
    a = np.asarray(rgb).astype(np.float32)
    warm = a[:, :, 0] - a[:, :, 2]                    # R - B
    alpha = np.clip((warm - lo) / (hi - lo), 0, 1) * 255
    alpha = Image.fromarray(alpha.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(0.8))
    img = Image.merge("RGBA", (*rgb.split(), alpha))
    b = img.getbbox()
    return img.crop(b) if b else img

def crop_paper_margin(im, thresh=28, inset=0.045):
    """Crop the white paper margin around a background wash to its content bbox,
    then inset a few % to drop the rounded-corner white fringe."""
    rgb = im.convert("RGB")
    a = np.asarray(rgb).astype(np.float32)
    dist = np.sqrt(((255.0 - a) ** 2).sum(axis=2))    # 0 at white
    mask = (dist > thresh).astype(np.uint8) * 255
    b = Image.fromarray(mask, "L").getbbox()
    if b:
        rgb = rgb.crop(b)
    w, h = rgb.size
    dx, dy = int(w * inset), int(h * inset)
    return rgb.crop((dx, dy, w - dx, h - dy))

# ---- process every file, remembering its source name ----
records = []   # (kind, src_basename, processed_relpath)
counts = {}
for f in sorted(glob.glob(os.path.join(RAW, "*.png"))):
    base = os.path.basename(f)
    kind = classify(base)
    im = Image.open(f)
    if kind == "bg":
        out = crop_paper_margin(im)
    elif kind in ("sparkle", "star"):
        out = cut_warm(im)
    elif kind in ("moon", "cloud"):
        out = cut_paper(im)
    else:                                              # nebula / other -> skip using
        continue
    i = counts.get(kind, 0); counts[kind] = i + 1
    rel = f"processed/{kind}_{i}.png"
    out.save(os.path.join(RAW, rel))
    records.append((kind, base, rel))
    print(f"{kind:8} <- {base[:58]}")
print("\nBuckets:", counts)

def pick(kind, contains=None):
    for k, src, rel in records:
        if k == kind and (contains is None or contains in src.lower()):
            return rel
    for k, src, rel in records:
        if k == kind:
            return rel
    return ""

def all_of(kind):
    return [rel for k, _, rel in records if k == kind]

import random
random.seed(7)

bg    = pick("bg", "mj.run")            # Damla's choice: the navy->lilac cloud sky
moon  = pick("moon")
clouds_pool = all_of("cloud")
tw_pool = all_of("sparkle") + all_of("star")

# navy backing sampled from the sky's top band, so any residual edge reads as sky
navy = "#20204d"
if bg:
    top = np.asarray(Image.open(os.path.join(RAW, bg)).convert("RGB"))[:40]
    navy = "#%02x%02x%02x" % tuple(int(top[:, :, c].mean()) for c in range(3))

# ---- clouds: a small natural band near the moon / wash line (NOT one lone cloud) ----
cc = itertools.cycle(clouds_pool) if clouds_pool else itertools.repeat("")
# (top%, left%, width, opacity, flipX, delay, front?)
cloud_defs = [
    (43, 46, 138, .95, -1, 0.8, True),   # front, big, under the moon
    (40, 20, 74, .6,   1, 1.9, False),   # left, mid
    (47, 74, 88, .68, -1, 0.4, False),   # right, larger
    (52, 40, 66, .5,   1, 2.6, False),   # small filler lower-left
]
clouds = []
for (t, l, w, o, fl, d, front) in cloud_defs:
    z = "z-index:7;" if front else "z-index:3;"
    clouds.append(f'<img class="cloud" style="top:{t}%;left:{l}%;width:{w}px;opacity:{o};{z}'
                  f'--fl:{fl};animation-delay:{d}s" src="{next(cc)}">')

# ---- stars + sparkles: natural scatter across the empty navy sky (organic, varied) ----
# denser toward the top, thinning near the moon; skip the moon disc; mix of sizes.
def in_moon(x, y):
    dx, dy = (x - 47) / 27.0, (y - 30) / 15.0
    return dx * dx + dy * dy < 1.15
pts, tries = [], 0
while len(pts) < 15 and tries < 600:
    tries += 1
    x = random.uniform(6, 94)
    y = random.uniform(4, 46)
    if in_moon(x, y):
        continue
    if y > 30 and random.random() < 0.5:      # thin out lower half -> density up top
        continue
    if any((x - px) ** 2 + (y - py) ** 2 < 42 for px, py, *_ in pts):  # min spacing
        continue
    size = random.choice([11, 13, 14, 16, 16, 18, 22, 26])            # mostly small
    pts.append((x, y, size, round(random.uniform(0, 3.2), 1)))
tw = []
tpool = itertools.cycle(tw_pool) if tw_pool else itertools.repeat("")
for (x, y, s, d) in pts:
    tw.append(f'<img class="el" style="top:{y}%;left:{x}%;width:{s}px;'
              f'animation-delay:{d}s" src="{next(tpool)}">')

sky = (f'<img class="bg" src="{bg}">' if bg else
       f'<div class="bg" style="background:{navy}"></div>')

html = f"""<!DOCTYPE html><html><head><meta charset=utf-8>
<style>
body{{background:#111;display:flex;flex-direction:column;align-items:center;gap:14px;
justify-content:center;min-height:100vh;font-family:-apple-system,sans-serif;padding:40px}}
h2{{color:#fff;font-weight:600}}
.phone{{position:relative;width:320px;height:693px;border-radius:44px;overflow:hidden;
box-shadow:0 30px 80px rgba(0,0,0,.6);border:6px solid #222;background:{navy}}}
.bg{{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;transform:scale(1.05)}}
.moon{{position:absolute;top:31%;left:47%;transform:translate(-50%,-50%);width:200px;z-index:5;
filter:drop-shadow(0 0 22px rgba(255,229,102,.4)) drop-shadow(0 0 58px rgba(255,214,120,.22))}}
.cloud{{position:absolute;transform:translate(-50%,-50%) scaleX(var(--fl,1));
animation:drift 12s ease-in-out infinite}}
@keyframes drift{{0%,100%{{margin-left:0}}50%{{margin-left:12px}}}}
.el{{position:absolute;transform:translate(-50%,-50%);z-index:6;
animation:tw 3.4s ease-in-out infinite}}
@keyframes tw{{0%,100%{{opacity:.4;transform:translate(-50%,-50%) scale(.85)}}
50%{{opacity:1;transform:translate(-50%,-50%) scale(1.1)}}}}
.label{{color:#999;font-size:13px}}
</style></head><body>
<h2>Moonlight — mock</h2>
<div class="phone">
  {sky}
  {''.join(c for c in clouds if 'z-index:3' in c)}
  {'<img class=moon src="'+moon+'">' if moon else ''}
  {''.join(c for c in clouds if 'z-index:7' in c)}
  {''.join(tw)}
</div>
<div class="label">bg: {os.path.basename(bg)[:26] if bg else '-'} · süzülen bulutlar · temiz gold pırıltılar</div>
</body></html>"""

with open(os.path.join(RAW, "mock.html"), "w") as f:
    f.write(html)
print("\nWROTE", os.path.join(RAW, "mock.html"))
