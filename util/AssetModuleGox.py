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

    def exportForFile(self, filePath, resSettings):
        retPath = filePath.with_suffix(".obj")
        outputTarget = self.prepareOutputDirectoryForFile(retPath, True)

        self.goxelExportToObj(filePath, outputTarget)

        meshPath = filePath.with_suffix(".mesh.xml")
        actualMeshPath = self.prepareOutputDirectoryForFile(meshPath, True)
        self.convertObjToOgre(outputTarget, actualMeshPath)

        #Goxel changes

        if(resSettings.separateLayers):
            #Separate layers iterates all layers and exports them separately
            goxelLayers = self.goxelDetermineLayers(filePath)
            for i in goxelLayers:
                retPath = filePath.with_name(f"{filePath.stem}.{i}.txt")
                goxelTxtTarget = self.prepareOutputDirectoryForFile(retPath, True)
                fileValid = self.goxelExportToTxt(filePath, goxelTxtTarget, i)
                if not fileValid:
                    continue

                retPath = retPath.with_suffix(".voxMesh")
                print(retPath)
                voxMeshTarget = self.prepareOutputDirectoryForFile(retPath, True)
                self.exportToVoxMesh(goxelTxtTarget, voxMeshTarget)
        else:
            retPath = filePath.with_suffix(".txt")
            goxelTxtTarget = self.prepareOutputDirectoryForFile(retPath, True)
            self.goxelExportToTxt(filePath, goxelTxtTarget)

            retPath = filePath.with_suffix(".voxMesh")
            voxMeshTarget = self.prepareOutputDirectoryForFile(retPath, True)
            self.exportToVoxMesh(goxelTxtTarget, voxMeshTarget)

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

    def fileHasExactlyThreeLines(self, filename):
        with open(filename, "r", encoding="utf-8") as f:
            for i, _ in enumerate(f, start=1):
                if i > 3:
                    return False
        return i == 3

    def goxelDetermineLayers(self, inPath):
        devnull = open(os.devnull, 'w')
        result = subprocess.run(["xvfb-run", "goxel", str(inPath), "--list"], capture_output=True, text=True)

        layerNames = {line.split(": ")[1] for line in result.stdout.splitlines() if "layer:" in line}

        devnull.close()

        return layerNames

    def goxelExportToTxt(self, inPath, outPath, layerName=None):
        devnull = open(os.devnull, 'w')

        command = ["xvfb-run", "goxel", str(inPath), "-e", str(outPath)]
        if layerName is not None:
            command.append("--layer=" + layerName)

        process = subprocess.Popen(command, stdout=devnull, stderr=devnull)
        #result = subprocess.run(command, capture_output=True, text=True)
        #print(result.stdout)
        process.wait()

        fileValid = True
        if outPath.exists():
            if self.fileHasExactlyThreeLines(outPath):
                os.remove(outPath)
                fileValid = False
        else:
            print(f"Warning: no file was outputted for {outPath} from {inPath}")

        devnull.close()

        return fileValid

    def exportToVoxMesh(self, filePath, outPath):
        devnull = open(os.devnull, 'w')
        process = subprocess.Popen(["VoxelConverterTool", str(filePath), str(outPath)], stdout=subprocess.PIPE, stderr=devnull)
        process.wait()
        devnull.close()
