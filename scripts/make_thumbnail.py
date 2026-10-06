#!/usr/bin/env python3
"""Build the mod thumbnail from K2's biomass item icon.

Usage: python3 make_thumbnail.py <src.png> <out.png>
Trims transparent margins, scales to fit, centers on a dark background.
"""
import sys

from PIL import Image

SIZE = 144
PAD = 12
BG = (38, 41, 45, 255)

src_path, out_path = sys.argv[1], sys.argv[2]

sprite = Image.open(src_path).convert("RGBA")
bbox = sprite.getbbox()
if bbox is None:
    raise SystemExit("sprite is fully transparent")
sprite = sprite.crop(bbox)

fit = SIZE - 2 * PAD
scale = fit / max(sprite.size)
new_size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
sprite = sprite.resize(new_size, Image.LANCZOS)

canvas = Image.new("RGBA", (SIZE, SIZE), BG)
canvas.paste(sprite, ((SIZE - new_size[0]) // 2, (SIZE - new_size[1]) // 2), sprite)
canvas.save(out_path, "PNG")
print(f"{out_path}: {SIZE}x{SIZE}, sprite {new_size[0]}x{new_size[1]} from crop {bbox}")
