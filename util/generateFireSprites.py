"""Generates a test fireSprites.png texture: 32 frames of 256x256, laid out in a single (8192 x 256) strip.
Each frame is a magenta box with a black outline and a centred frame-index number.
"""

from PIL import Image, ImageDraw, ImageFont
import os

FRAME_COUNT = 32
FRAME_SIZE  = 256
IMG_WIDTH   = FRAME_SIZE * FRAME_COUNT
IMG_HEIGHT  = FRAME_SIZE

img  = Image.new("RGBA", (IMG_WIDTH, IMG_HEIGHT), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
except Exception:
    font = ImageFont.load_default()

for i in range(FRAME_COUNT):
    x0 = i * FRAME_SIZE
    y0 = 0
    x1 = x0 + FRAME_SIZE - 1
    y1 = y0 + FRAME_SIZE - 1

    #Fill magenta
    draw.rectangle([x0, y0, x1, y1], fill=(255, 0, 255, 255))
    #Black outline
    draw.rectangle([x0, y0, x1, y1], outline=(0, 0, 0, 255), width=4)

    #Centre frame index text
    label = str(i)
    bbox  = draw.textbbox((0, 0), label, font=font)
    tw    = bbox[2] - bbox[0]
    th    = bbox[3] - bbox[1]
    tx    = x0 + (FRAME_SIZE - tw) // 2 - bbox[0]
    ty    = y0 + (FRAME_SIZE - th) // 2 - bbox[1]
    draw.text((tx, ty), label, fill=(0, 0, 0, 255), font=font)

out_path = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets", "textures", "fireSprites.png"
)
os.makedirs(os.path.dirname(out_path), exist_ok=True)
img.save(out_path)
print(f"Saved {IMG_WIDTH}x{IMG_HEIGHT} sprite sheet to: {out_path}")
