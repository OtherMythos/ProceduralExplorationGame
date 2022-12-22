from assetModules.AssetModule import *

from pathlib import Path
import subprocess

'''
Convert Goxel .gox files to Ogre meshes.
This export procedure uses the file voxelConverter.py to convert between .obj and Ogre's mesh xml format.
In total the expected procedure is .gox --goxel--> .obj --voxelConverter.py--> Ogre.mesh.xml --OgreMeshTool--> Ogre.mesh
Voxel converter is also responsible for correctly setting up the mesh's texture uvs for the correct palette.
'''
class AssetModuleGox(AssetModule):
    def __init__(self, settings):
        super().__init__(settings)
        self.extension = ".gox"

    def exportForFile(self, filePath):
        retPath = filePath.with_suffix(".obj")
        outputTarget = self.prepareOutputDirectoryForFile(retPath, True)

        self.goxelExportToObj(filePath, outputTarget)

        meshPath = filePath.with_suffix(".mesh.xml")
        actualMeshPath = self.prepareOutputDirectoryForFile(meshPath, True)
        self.convertObjToOgre(outputTarget, actualMeshPath)

    def goxelExportToObj(self, inPath, outPath):
        devnull = open(os.devnull, 'w')
        process = subprocess.Popen(["xvfb-run", "goxel", str(inPath), "-e", str(outPath)], stdout=devnull, stderr=devnull)
        process.wait()
        devnull.close()

    def convertObjToOgre(self, outputTarget, actualMeshPath):
        devnull = open(os.devnull, 'w')
        process = subprocess.Popen(["python3", "/builder/voxelConverter.py", str(outputTarget), str(actualMeshPath)], stdout=subprocess.PIPE, stderr=devnull)
        process.wait()
        devnull.close()