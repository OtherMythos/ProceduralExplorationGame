"""Combines assets/textures/frame01.webp … frame32.webp into a single
(256*32, 256) = (8192 x 256) sprite sheet using nearest-neighbour scaling.
Output: assets/textures/fireSpritesDone.png
"""

from PIL import Image
import os
import glob

FRAME_COUNT = 32
FRAME_SIZE  = 256
IMG_WIDTH   = FRAME_SIZE * FRAME_COUNT
IMG_HEIGHT  = FRAME_SIZE

repo_root    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
textures_dir = os.path.join(repo_root, "assets", "textures")

img = Image.new("RGBA", (IMG_WIDTH, IMG_HEIGHT), (0, 0, 0, 0))

for i in range(1, FRAME_COUNT + 1):
    path = os.path.join(textures_dir, f"frame{i:02d}.webp")
    if not os.path.exists(path):
        print(f"Warning: missing {path}, skipping")
        continue

    frame = Image.open(path).convert("RGBA")
    if frame.size != (FRAME_SIZE, FRAME_SIZE):
        frame = frame.resize((FRAME_SIZE, FRAME_SIZE), Image.NEAREST)

    img.paste(frame, ((i - 1) * FRAME_SIZE, 0))

out_path = os.path.join(textures_dir, "fireSpritesDone.png")
img.save(out_path)
print(f"Saved {IMG_WIDTH}x{IMG_HEIGHT} sprite sheet to: {out_path}")
