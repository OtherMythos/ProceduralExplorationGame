from assetModules.AssetModule import *

from pathlib import Path
from PIL import Image
import numpy as np

'''
Convert a .BMP file to terrain data.
The BMP file is easier to edit earlier on and python makes it easier to export in an engine format than reading the texture from the engine.
'''
class AssetModuleTerrainBMP(AssetModule):
    def __init__(self, settings):
        super().__init__(settings)
        self.extension = ".bmp"

    def exportForFile(self, filePath):
        retPath = filePath.with_suffix(".txt")
        outputTarget = self.prepareOutputDirectoryForFile(retPath, True)

        self.exportBMPToText(filePath, outputTarget)

    def exportBMPToText(self, inPath, outPath):
        img = np.array(Image.open(inPath))

        with open(outPath, 'a') as out:
            for i in img:
                for y in i:
                    out.write(str(y) + ',')
                out.write('\n')