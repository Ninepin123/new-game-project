# -*- coding: utf-8 -*-
"""Print native size + opaque bbox for every monster frame, to choose a consistent scale."""
from pathlib import Path
from PIL import Image

SRC = Path(r"E:\someMob素材")
ALPHA_T = 12

for folder in ["跳躍蜥蜴怪", "地洞爬行獸"]:
    print(f"\n=== {folder} ===")
    for p in sorted((SRC / folder).glob("*.png")):
        img = Image.open(p).convert("RGBA")
        mask = img.getchannel("A").point(lambda a: 255 if a > ALPHA_T else 0)
        box = mask.getbbox()
        bw = box[2] - box[0]
        bh = box[3] - box[1]
        print(f"{p.name:18s} native={img.width}x{img.height}  bbox={bw}x{bh}")
