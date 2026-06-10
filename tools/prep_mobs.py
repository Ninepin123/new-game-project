# -*- coding: utf-8 -*-
"""Normalize monster sprite frames into uniform, FEET-ALIGNED, CONSISTENT-SCALE canvases.

The earlier bug: each frame was scaled independently to a fixed content *height*.
Because walk-1 (low, arched) and walk-2 (tall stride) have very different bbox
heights, that made the creature's body width swing wildly between frames -> it
appeared to grow/shrink while walking.

Fix: every frame of one monster uses ONE scale factor *per native-art-scale group*
(scale = TARGET_W / ref_w, where ref_w is shared by all frames drawn at the same
native scale). This preserves the artist's true relative sizes, so the walk cycle
stays a constant size; only the natural pose bob remains. Frames are pasted
bottom-center so the feet line up.
"""
from collections import deque
from pathlib import Path

from PIL import Image

SRC = Path(r"E:\someMob素材")
OUT = Path(r"E:\Mario\新遊戲專案\textures\mobs")
ALPHA_T = 12

# (source subpath, output name, ref_w, scale_mul, largest_only)
#   scale = TARGET_W / ref_w * scale_mul
#   ref_w  = native bbox width representative of that frame's art-scale GROUP.
#            Frames sharing a group share ref_w -> identical scale -> no size jump.

LIZARD_TARGET_W = 190
LIZARD_CANVAS = (224, 184)
LIZARD = [
    ("跳躍蜥蜴怪/待機.png", "lizard_idle", 156, 1.0, False),
    ("跳躍蜥蜴怪/行走1.png", "lizard_walk1", 156, 1.0, False),
    ("跳躍蜥蜴怪/行走2.png", "lizard_walk2", 156, 1.0, False),
    ("跳躍蜥蜴怪/發現玩家.png", "lizard_spot", 156, 1.0, False),
    ("跳躍蜥蜴怪/跳躍起飛.png", "lizard_takeoff", 156, 1.0, False),
    ("跳躍蜥蜴怪/空中.png", "lizard_air", 156, 1.0, True),  # drop baked motion lines/shadow
    ("跳躍蜥蜴怪/落地攻擊.png", "lizard_land", 156, 1.0, False),
    ("跳躍蜥蜴怪/死亡（倒地）.png", "lizard_dead", 585, 1.0, False),  # big-art corpse
]

BURROWER_TARGET_W = 184
BURROWER_CANVAS = (230, 170)
BURROWER = [
    ("地洞爬行獸/藏在地底.png", "burrower_hidden", 461, 1.0, False),    # big-art mound
    ("地洞爬行獸/鉆出地面.png", "burrower_emerge", 200, 1.0, False),    # small-art zoom (mound burst)
    ("地洞爬行獸/出現或探頭.png", "burrower_peek", 215, 1.0, False),    # small-art zoom (head)
    ("地洞爬行獸/行走1.png", "burrower_walk1", 460, 1.0, False),        # big-art full body
    ("地洞爬行獸/行走2.png", "burrower_walk2", 460, 1.0, False),        # big-art full body
    ("地洞爬行獸/張嘴攻擊.png", "burrower_bite", 235, 1.0, False),      # small-art zoom (head lunge)
    ("地洞爬行獸/縮回地底.png", "burrower_retreat", 460, 1.0, False),   # big-art
    ("地洞爬行獸/死亡（翻肚）.png", "burrower_dead", 569, 1.0, False),   # big-art corpse
]


def largest_component(img: Image.Image) -> Image.Image:
    """Keep only the largest 4-connected opaque blob (drops drop-shadows / motion lines)."""
    w, h = img.size
    px = img.load()
    seen = [[False] * w for _ in range(h)]
    best = None
    for y in range(h):
        for x in range(w):
            if seen[y][x] or px[x, y][3] <= ALPHA_T:
                continue
            comp = []
            dq = deque([(x, y)])
            seen[y][x] = True
            while dq:
                cx, cy = dq.popleft()
                comp.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and px[nx, ny][3] > ALPHA_T:
                        seen[ny][nx] = True
                        dq.append((nx, ny))
            if best is None or len(comp) > len(best):
                best = comp
    keep = set(best or [])
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    opx = out.load()
    for x, y in keep:
        opx[x, y] = px[x, y]
    return out


def bbox(img: Image.Image):
    mask = img.getchannel("A").point(lambda a: 255 if a > ALPHA_T else 0)
    return mask.getbbox()


def process(entries, target_w, canvas_size, subdir):
    out_dir = OUT / subdir
    out_dir.mkdir(parents=True, exist_ok=True)
    cw, ch = canvas_size
    sheet_cols = []
    for rel, name, ref_w, mul, largest_only in entries:
        img = Image.open(SRC / rel).convert("RGBA")
        if largest_only:
            img = largest_component(img)
        img = img.crop(bbox(img))
        scale = (target_w / ref_w) * mul
        new_w = max(1, round(img.width * scale))
        new_h = max(1, round(img.height * scale))
        img = img.resize((new_w, new_h), Image.LANCZOS)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        # clamp if a frame is taller than the canvas (align feet at bottom)
        paste_x = (cw - img.width) // 2
        paste_y = ch - img.height
        canvas.paste(img, (paste_x, paste_y), img)
        canvas.save(out_dir / f"{name}.png")
        print(f"{name:18s} content {img.width}x{img.height} on {cw}x{ch}")
        sheet_cols.append((name, canvas))

    # contact sheet: all frames side by side on a shared baseline for size review
    pad = 8
    sheet = Image.new("RGBA", ((cw + pad) * len(sheet_cols) + pad, ch + 2 * pad), (40, 40, 48, 255))
    for i, (_, c) in enumerate(sheet_cols):
        sheet.paste(c, (pad + i * (cw + pad), pad), c)
    sheet.save(OUT / f"_sheet_{subdir}.png")


process(LIZARD, LIZARD_TARGET_W, LIZARD_CANVAS, "lizard")
process(BURROWER, BURROWER_TARGET_W, BURROWER_CANVAS, "burrower")
print("done")
