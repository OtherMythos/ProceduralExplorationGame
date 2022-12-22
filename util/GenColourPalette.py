from PIL import Image, ImageDraw
import sys

if len(sys.argv) <= 1:
    print("Please provide an export path")
    sys.exit(1)
outPath = sys.argv[1]

# size of image
canvas = (400, 300)

# init canvas
im = Image.new('RGB', canvas, (255, 255, 255))
draw = ImageDraw.Draw(im)

colours = [
    (0,0,0),
    (26,23,40),
    (57,27,47,),
    (89,40,35),
    (133,64,40),
    (233,83,0),
    (219,139,73),
    (243,180,130),
    (252,243,0),
    (133,232,30),
    (60,184,0),
    (0,135,88),
    (52,89,28),
    (66,59,22),
    (36,46,43),
    (48,46,100),
    (22,78,114),
    (68,85,227),
    (64,135,255),
    (28,199,225),
    (188,210,255),
    (255,255,255),
    (133,158,170),
    (114,106,117),
    (86,87,87),
    (71,68,64),
    (106,42,123),
    (171,15,33),
    (227,50,77),
    (221,90,175),
    (123,136,46),
    (124,91,25)
]

numWidth = 8
numHeight = 4
squareWidth = float(canvas[0]) / float(numWidth)
squareHeight = float(canvas[1]) / float(numHeight)
# draw rectangles
for i in range(numWidth*numHeight):
    currentWidth = i % numWidth
    currentHeight = int(i / numWidth)
    xPos = currentWidth * squareWidth
    yPos = currentHeight * squareHeight
    draw.rectangle([xPos, yPos, xPos + squareWidth, yPos + squareHeight], fill=colours[i])

# make thumbnail
im.thumbnail(canvas)

# save image
im.save(outPath)