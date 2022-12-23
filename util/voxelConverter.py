#!/usr/bin/python3

import argparse
import re
from pathlib import Path
import xml.etree.cElementTree as ET

class XMLWriter:
    def __init__(self, data):
        self.data = data

    def populateFaces(self, faces):
        for i in self.data.faces:
            face = ET.SubElement(faces, "face")
            face.attrib["v1"] = str(i[0])
            face.attrib["v2"] = str(i[1])
            face.attrib["v3"] = str(i[2])

    def populateVertices(self, container):
        for i in range(len(self.data.verts)):
            vert = ET.SubElement(container, "vertex")

            v = self.data.verts[i]
            pos = ET.SubElement(vert, "position")
            pos.attrib["x"] = str(float(v[0]))
            pos.attrib["y"] = str(float(v[2]))
            pos.attrib["z"] = str(float(v[1]))

            normal = ET.SubElement(vert, "normal")
            normal.attrib["x"] = "1.0"
            normal.attrib["y"] = "0.0"
            normal.attrib["z"] = "0.0"

            t = self.data.texCoords[self.data.vertColours[i]]
            texcoord = ET.SubElement(vert, "texcoord")
            texcoord.attrib["u"] = str(t[0])
            texcoord.attrib["v"] = str(t[1])

    def writeToFile(self, filePath):
        materialName = "baseVoxelMaterial"

        root = ET.Element("mesh")

        sharedgeometry = ET.SubElement(root, "sharedgeometry")
        sharedgeometry.attrib["vertexcount"] = str(len(self.data.verts))

        vertexBuffer = ET.SubElement(sharedgeometry, "vertexbuffer")
        vertexBuffer.attrib["colours_diffuse"] = "False"
        vertexBuffer.attrib["normals"] = "true"
        vertexBuffer.attrib["positions"] = "true"
        vertexBuffer.attrib["texture_coords"] = "1"
        vertexBuffer.attrib["tangent_dimensions"] = "0"
        vertexBuffer.attrib["tangents"] = "False"

        self.populateVertices(vertexBuffer)

        submeshes = ET.SubElement(root, "submeshes")
        submesh = ET.SubElement(submeshes, "submesh")
        submesh.attrib["material"] = materialName
        submesh.attrib["operationtype"] = "triangle_list"
        #TODO if scenes get large might I need this?
        submesh.attrib["use32bitindexes"] = "False"
        submesh.attrib["usesharedvertices"] = "true"

        faces = ET.SubElement(submesh, "faces")
        faces.attrib["count"] = str(len(self.data.faces))

        self.populateFaces(faces)

        submeshnames = ET.SubElement(root, "submeshnames")
        submesh = ET.SubElement(submeshnames, "submesh")
        submesh.attrib["index"] = "0"
        submesh.attrib["name"] = materialName

        tree = ET.ElementTree(root)
        #ET.indent(tree, space="    ", level=0)
        tree.write(str(filePath))

class CompleteData:
    def __init__(self):
        self.verts = []
        self.vertColours = []
        self.vertNormals = []
        self.faces = []
        self.texCoords = []

        self.colData = [
            [0.000000, 0.000000, 0.000000],
            [0.133333, 0.125490, 0.203922],
            [0.270588, 0.156863, 0.235294],
            [0.400000, 0.223529, 0.192157],
            [0.560784, 0.337255, 0.231373],
            [0.874510, 0.443137, 0.149020],
            [0.850980, 0.627451, 0.400000],
            [0.933333, 0.764706, 0.603922],
            [0.984314, 0.949020, 0.211765],
            [0.600000, 0.898039, 0.313725],
            [0.415686, 0.745098, 0.188235],
            [0.215686, 0.580392, 0.431373],
            [0.294118, 0.411765, 0.184314],
            [0.321569, 0.294118, 0.141176],
            [0.196078, 0.235294, 0.223529],
            [0.247059, 0.247059, 0.454902],
            [0.188235, 0.376471, 0.509804],
            [0.356863, 0.431373, 0.882353],
            [0.388235, 0.607843, 1.000000],
            [0.372549, 0.803922, 0.894118],
            [0.796078, 0.858824, 0.988235],
            [1.000000, 1.000000, 1.000000],
            [0.607843, 0.678431, 0.717647],
            [0.517647, 0.494118, 0.529412],
            [0.411765, 0.415686, 0.415686],
            [0.349020, 0.337255, 0.321569],
            [0.462745, 0.258824, 0.541176],
            [0.674510, 0.196078, 0.196078],
            [0.850980, 0.341176, 0.388235],
            [0.843137, 0.482353, 0.729412],
            [0.560784, 0.592157, 0.290196],
            [0.541176, 0.435294, 0.188235],
        ]
        #Resolve the colours to their summed hash value for fast lookup.
        #They're written like this above just to keep track of the original values.
        for i in range(len(self.colData)):
            self.colData[i] = sum(self.colData[i])

        self.resolveTexCoords()

    '''
    Determine the coordinates relative to the texture.
    '''
    def resolveTexCoords(self):
        numTilesWidth = 8
        numTilesHeight = 4
        tileWidth = (1.0 / numTilesWidth) / 2.0
        tileHeight = (1.0 / numTilesHeight) / 2.0

        self.texCoords = [None] * len(self.colData)
        for i in range(len(self.colData)):
            tileX = i % numTilesWidth
            tileY = int(i / numTilesWidth)
            self.texCoords[i] = (tileX / numTilesWidth + tileWidth, tileY / numTilesHeight + tileHeight)

    def addVert(self, vert):
        if len(vert) != 7:
            return False
        addArray = [int(numeric_string) for numeric_string in vert[1:4]]
        self.verts.append(addArray)
        addArray = [float(numeric_string) for numeric_string in vert[4:8]]
        self.vertColours.append(addArray)
        return True

    def addVertNorm(self, norm):
        if len(norm) != 4:
            return False
        addArray = [float(numeric_string) for numeric_string in norm[1:4]]
        self.vertNormals.append(addArray)
        return True

    def parseFaceEntry(self, entry):
        numbers = re.findall(r'\d+', entry)
        return (int(numbers[0]), int(numbers[1]))

    def addFace(self, face):
        if len(face) != 5:
            return False
        totalFace = []
        for i in face[1:]:
            result = self.parseFaceEntry(i)
            totalFace.append(result)
        if len(totalFace) == 0:
            return False
        self.faces.append(totalFace)
        return True

    def resolveColours(self):
        entries = {}
        for i in range(len(self.vertColours)):
            val = sum(self.vertColours[i])
            if not val in entries:
                targetIdx = self.colData.index(val)
                entries[val] = targetIdx
            self.vertColours[i] = entries[val]


    '''
    Iterate all faces and match up the vertices with the normals.
    '''
    def resolveNormals(self):
        newNorms = [None] * len(self.verts)
        for i in self.faces:
            for y in i:
                newNorms[y[0] - 1] = self.vertNormals[y[1] - 1]

        #print(self.vertNormals)
        #print(newNorms)

    def resolveFaces(self):
        newFaces = []
        for i in self.faces:
            newFaces.append([i[3][0] - 1, i[2][0] - 1, i[1][0] - 1])
            newFaces.append([i[1][0] - 1, i[0][0] - 1, i[3][0] - 1])

        self.faces = newFaces

    def reduce(self):
        #self.resolveNormals()
        self.resolveFaces()
        self.resolveColours()

def parseLine(line, total):
    result = True
    targetLine = line[0]
    if targetLine == "v":
        result = total.addVert(line)
    elif targetLine == "vn":
        result = total.addVertNorm(line)
    elif targetLine == "f":
        result = total.addFace(line)

    return result


def parseFile(file):
    total = CompleteData()
    for line in file:
        result = parseLine(line.split(), total)
        if not result:
            print("Error parsing file")
            return None

    total.reduce()

    return total

#Gather all the vertices, find all the unique colour definitions and boil that down to just an id.

def main():
    helpText = '''Convert a .obj file exported from a voxel tool such as goxel to a format Ogre can understand.
    While doing this, change the colour values to be texture uv values.'''

    parser = argparse.ArgumentParser(description = helpText)

    parser.add_argument('input', metavar='I', type=str, nargs='?', help='A path to the input file.')
    parser.add_argument('output', metavar='O', type=str, nargs='?', help='A path to the output file.')

    args = parser.parse_args()

    if args.input is None or args.output is None:
        print("Please provide both an input and output file path")
        return

    inFile = Path(args.input)
    if not inFile.exists() or not inFile.is_file():
        print("Input path is not a file.")
        return

    totalData = None
    with open(args.input) as fp:
        totalData = parseFile(fp)

    if totalData is None:
        return

    outFile = Path(args.output)
    writer = XMLWriter(totalData)
    writer.writeToFile(outFile)

    print("exported %s to %s" % (args.input, args.output))


if __name__ == "__main__":
    main()
