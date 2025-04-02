#Generate the texture coordinates for shaders.

for i in range(256):
    COLS_WIDTH = 16
    COLS_HEIGHT = 16
    TILE_WIDTH = (1.0 / COLS_WIDTH) / 2.0
    TILE_HEIGHT = (1.0 / COLS_HEIGHT) / 2.0

    texCoordX = (float(i % COLS_WIDTH) / COLS_WIDTH) + TILE_WIDTH
    texCoordY = (float((int(float(i) / COLS_WIDTH))) / COLS_HEIGHT) + TILE_HEIGHT

    print(f"float2({texCoordX}, {texCoordY}),")