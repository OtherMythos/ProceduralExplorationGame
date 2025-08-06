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

        #self.goxelExportToObj(filePath, outputTarget)

        meshPath = filePath.with_suffix(".mesh.xml")
        actualMeshPath = self.prepareOutputDirectoryForFile(meshPath, True)
        self.convertObjToOgre(outputTarget, actualMeshPath)

        #Goxel changes

        extraFlags = " -g "

        if(resSettings.enableFaceMerging):
            extraFlags = "  "
        if(resSettings.disableAmbient):
            extraFlags = extraFlags + " -a "
        if(resSettings.disableFaces):
            faces = ",".join(map(str, resSettings.disableFaces))
            extraFlags = extraFlags + " -f " + faces
        if(resSettings.animValues):
            extraFlags = extraFlags + " -v " + resSettings.animValues

        if(resSettings.separateLayers):
            extraFlags = extraFlags + " -c "
            #Separate layers iterates all layers and exports them separately
            goxelLayers = self.goxelDetermineLayers(filePath)
            if goxelLayers is None:
                print(f"Warning: No layers found for {filePath}")
                return

            for i in goxelLayers:
                retPath = filePath.with_name(f"{filePath.stem}.{i}.txt")
                goxelTxtTarget = self.prepareOutputDirectoryForFile(retPath, True)
                fileValid = self.goxelExportToTxt(filePath, goxelTxtTarget, i)
                if not fileValid:
                    continue

                retPath = retPath.with_suffix(".voxMesh")
                print(retPath)
                voxMeshTarget = self.prepareOutputDirectoryForFile(retPath, True)
                self.exportToVoxMesh(goxelTxtTarget, voxMeshTarget, extraFlags)

                goxelTxtTarget.unlink()
        else:
            retPath = filePath.with_suffix(".txt")
            goxelTxtTarget = self.prepareOutputDirectoryForFile(retPath, True)
            self.goxelExportToTxt(filePath, goxelTxtTarget)

            retPath = filePath.with_suffix(".voxMesh")
            voxMeshTarget = self.prepareOutputDirectoryForFile(retPath, True)
            self.exportToVoxMesh(goxelTxtTarget, voxMeshTarget, extraFlags)

            goxelTxtTarget.unlink()

    def flip_yz(self, v_line):
        parts = v_line.strip().split()
        if len(parts) < 4:
            return v_line.rstrip()  # malformed line, return as-is

        x = float(parts[1])
        y = float(parts[2])
        z = float(parts[3])

        # Swap y and z, negate the new z
        new_y = -z
        new_z = y

        # Preserve any extra components (e.g. vertex color)
        extra = parts[4:]
        return f"v {x} {new_y} {new_z}" + (" " + " ".join(extra) if extra else "")

    def process_obj_in_place(self, file_path):
        with open(file_path, 'r') as f:
            lines = f.readlines()

        new_lines = []
        for line in lines:
            if line.startswith("v "):
                new_lines.append(self.flip_yz(line) + "\n")
            else:
                new_lines.append(line)

        with open(file_path, 'w') as f:
            f.writelines(new_lines)

    def goxelExportToObj(self, inPath, outPath):
        devnull = open(os.devnull, 'w')
        process = subprocess.Popen(["goxel", str(inPath), "-e", str(outPath)], stdout=devnull, stderr=devnull)
        process.wait()
        devnull.close()

        #Flip the coordinates to match Ogre
        self.process_obj_in_place(outPath)

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
        result = subprocess.run(["goxel", str(inPath), "--list"], capture_output=True, text=True)
        if result.stdout == "":
            return None

        layerNames = {line.split(": ")[1] for line in result.stdout.splitlines() if "layer:" in line}

        return layerNames

    def goxelExportToTxt(self, inPath, outPath, layerName=None):
        devnull = open(os.devnull, 'w')

        command = ["goxel", str(inPath), "-e", str(outPath)]
        if layerName is not None:
            command.append("--layer=" + layerName)

        process = subprocess.Popen(command, stdout=devnull, stderr=devnull)
        #result = subprocess.run(command, capture_output=True, text=True)
        #print(result.stdout)
        #print(result.stderr)
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

    def exportToVoxMesh(self, filePath, outPath, extraFlags=""):
        devnull = open(os.devnull, 'w')
        command = ["VoxelConverterTool", str(filePath), str(outPath)]
        if extraFlags != "":
            vals = extraFlags.split(' ')
            vals = [string for string in vals if string != ""]
            command.extend(vals)
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=devnull)
        process.wait()
        devnull.close()
