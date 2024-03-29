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
            #Order of y and z flipped for Ogre's coordinate system.
            pos = ET.SubElement(vert, "position")
            pos.attrib["x"] = str(float(v[0]-0.5))
            pos.attrib["y"] = str(float(v[2]-0.5))
            pos.attrib["z"] = str(float(-(v[1]-0.5)))

            n = self.data.vertNormals[i]
            normal = ET.SubElement(vert, "normal")
            normal.attrib["x"] = str(float(n[0]))
            normal.attrib["y"] = str(float(n[2]))
            normal.attrib["z"] = str(float(-n[1]))

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
            [1.000000, 1.000000, 1.000000],
            [1.000000, 1.000000, 0.800000],
            [1.000000, 1.000000, 0.600000],
            [1.000000, 1.000000, 0.400000],
            [1.000000, 1.000000, 0.200000],
            [1.000000, 1.000000, 0.000000],
            [1.000000, 0.800000, 1.000000],
            [1.000000, 0.800000, 0.800000],
            [1.000000, 0.800000, 0.600000],
            [1.000000, 0.800000, 0.400000],
            [1.000000, 0.800000, 0.200000],
            [1.000000, 0.800000, 0.000000],
            [1.000000, 0.600000, 1.000000],
            [1.000000, 0.600000, 0.800000],
            [1.000000, 0.600000, 0.600000],
            [1.000000, 0.600000, 0.400000],
            [1.000000, 0.600000, 0.200000],
            [1.000000, 0.600000, 0.000000],
            [1.000000, 0.400000, 1.000000],
            [1.000000, 0.400000, 0.800000],
            [1.000000, 0.400000, 0.600000],
            [1.000000, 0.400000, 0.400000],
            [1.000000, 0.400000, 0.200000],
            [1.000000, 0.400000, 0.000000],
            [1.000000, 0.200000, 1.000000],
            [1.000000, 0.200000, 0.800000],
            [1.000000, 0.200000, 0.600000],
            [1.000000, 0.200000, 0.400000],
            [1.000000, 0.200000, 0.200000],
            [1.000000, 0.200000, 0.000000],
            [1.000000, 0.000000, 1.000000],
            [1.000000, 0.000000, 0.800000],
            [1.000000, 0.000000, 0.600000],
            [1.000000, 0.000000, 0.400000],
            [1.000000, 0.000000, 0.200000],
            [1.000000, 0.000000, 0.000000],
            [0.800000, 1.000000, 1.000000],
            [0.800000, 1.000000, 0.800000],
            [0.800000, 1.000000, 0.600000],
            [0.800000, 1.000000, 0.400000],
            [0.800000, 1.000000, 0.200000],
            [0.800000, 1.000000, 0.000000],
            [0.800000, 0.800000, 1.000000],
            [0.800000, 0.800000, 0.800000],
            [0.800000, 0.800000, 0.600000],
            [0.800000, 0.800000, 0.400000],
            [0.800000, 0.800000, 0.200000],
            [0.800000, 0.800000, 0.000000],
            [0.800000, 0.600000, 1.000000],
            [0.800000, 0.600000, 0.800000],
            [0.800000, 0.600000, 0.600000],
            [0.800000, 0.600000, 0.400000],
            [0.800000, 0.600000, 0.200000],
            [0.800000, 0.600000, 0.000000],
            [0.800000, 0.400000, 1.000000],
            [0.800000, 0.400000, 0.800000],
            [0.800000, 0.400000, 0.600000],
            [0.800000, 0.400000, 0.400000],
            [0.800000, 0.400000, 0.200000],
            [0.800000, 0.400000, 0.000000],
            [0.800000, 0.200000, 1.000000],
            [0.800000, 0.200000, 0.800000],
            [0.800000, 0.200000, 0.600000],
            [0.800000, 0.200000, 0.400000],
            [0.800000, 0.200000, 0.200000],
            [0.800000, 0.200000, 0.000000],
            [0.800000, 0.000000, 1.000000],
            [0.800000, 0.000000, 0.800000],
            [0.800000, 0.000000, 0.600000],
            [0.800000, 0.000000, 0.400000],
            [0.800000, 0.000000, 0.200000],
            [0.800000, 0.000000, 0.000000],
            [0.600000, 1.000000, 1.000000],
            [0.600000, 1.000000, 0.800000],
            [0.600000, 1.000000, 0.600000],
            [0.600000, 1.000000, 0.400000],
            [0.600000, 1.000000, 0.200000],
            [0.600000, 1.000000, 0.000000],
            [0.600000, 0.800000, 1.000000],
            [0.600000, 0.800000, 0.800000],
            [0.600000, 0.800000, 0.600000],
            [0.600000, 0.800000, 0.400000],
            [0.600000, 0.800000, 0.200000],
            [0.600000, 0.800000, 0.000000],
            [0.600000, 0.600000, 1.000000],
            [0.600000, 0.600000, 0.800000],
            [0.600000, 0.600000, 0.600000],
            [0.600000, 0.600000, 0.400000],
            [0.600000, 0.600000, 0.200000],
            [0.600000, 0.600000, 0.000000],
            [0.600000, 0.400000, 1.000000],
            [0.600000, 0.400000, 0.800000],
            [0.600000, 0.400000, 0.600000],
            [0.600000, 0.400000, 0.400000],
            [0.600000, 0.400000, 0.200000],
            [0.600000, 0.400000, 0.000000],
            [0.600000, 0.200000, 1.000000],
            [0.600000, 0.200000, 0.800000],
            [0.600000, 0.200000, 0.600000],
            [0.600000, 0.200000, 0.400000],
            [0.600000, 0.200000, 0.200000],
            [0.600000, 0.200000, 0.000000],
            [0.600000, 0.000000, 1.000000],
            [0.600000, 0.000000, 0.800000],
            [0.600000, 0.000000, 0.600000],
            [0.600000, 0.000000, 0.400000],
            [0.600000, 0.000000, 0.200000],
            [0.600000, 0.000000, 0.000000],
            [0.400000, 1.000000, 1.000000],
            [0.400000, 1.000000, 0.800000],
            [0.400000, 1.000000, 0.600000],
            [0.400000, 1.000000, 0.400000],
            [0.400000, 1.000000, 0.200000],
            [0.400000, 1.000000, 0.000000],
            [0.400000, 0.800000, 1.000000],
            [0.400000, 0.800000, 0.800000],
            [0.400000, 0.800000, 0.600000],
            [0.400000, 0.800000, 0.400000],
            [0.400000, 0.800000, 0.200000],
            [0.400000, 0.800000, 0.000000],
            [0.400000, 0.600000, 1.000000],
            [0.400000, 0.600000, 0.800000],
            [0.400000, 0.600000, 0.600000],
            [0.400000, 0.600000, 0.400000],
            [0.400000, 0.600000, 0.200000],
            [0.400000, 0.600000, 0.000000],
            [0.400000, 0.400000, 1.000000],
            [0.400000, 0.400000, 0.800000],
            [0.400000, 0.400000, 0.600000],
            [0.400000, 0.400000, 0.400000],
            [0.400000, 0.400000, 0.200000],
            [0.400000, 0.400000, 0.000000],
            [0.400000, 0.200000, 1.000000],
            [0.400000, 0.200000, 0.800000],
            [0.400000, 0.200000, 0.600000],
            [0.400000, 0.200000, 0.400000],
            [0.400000, 0.200000, 0.200000],
            [0.400000, 0.200000, 0.000000],
            [0.400000, 0.000000, 1.000000],
            [0.400000, 0.000000, 0.800000],
            [0.400000, 0.000000, 0.600000],
            [0.400000, 0.000000, 0.400000],
            [0.400000, 0.000000, 0.200000],
            [0.400000, 0.000000, 0.000000],
            [0.200000, 1.000000, 1.000000],
            [0.200000, 1.000000, 0.800000],
            [0.200000, 1.000000, 0.600000],
            [0.200000, 1.000000, 0.400000],
            [0.200000, 1.000000, 0.200000],
            [0.200000, 1.000000, 0.000000],
            [0.200000, 0.800000, 1.000000],
            [0.200000, 0.800000, 0.800000],
            [0.200000, 0.800000, 0.600000],
            [0.200000, 0.800000, 0.400000],
            [0.200000, 0.800000, 0.200000],
            [0.200000, 0.800000, 0.000000],
            [0.200000, 0.600000, 1.000000],
            [0.200000, 0.600000, 0.800000],
            [0.200000, 0.600000, 0.600000],
            [0.200000, 0.600000, 0.400000],
            [0.200000, 0.600000, 0.200000],
            [0.200000, 0.600000, 0.000000],
            [0.200000, 0.400000, 1.000000],
            [0.200000, 0.400000, 0.800000],
            [0.200000, 0.400000, 0.600000],
            [0.200000, 0.400000, 0.400000],
            [0.200000, 0.400000, 0.200000],
            [0.200000, 0.400000, 0.000000],
            [0.200000, 0.200000, 1.000000],
            [0.200000, 0.200000, 0.800000],
            [0.200000, 0.200000, 0.600000],
            [0.200000, 0.200000, 0.400000],
            [0.200000, 0.200000, 0.200000],
            [0.200000, 0.200000, 0.000000],
            [0.200000, 0.000000, 1.000000],
            [0.200000, 0.000000, 0.800000],
            [0.200000, 0.000000, 0.600000],
            [0.200000, 0.000000, 0.400000],
            [0.200000, 0.000000, 0.200000],
            [0.200000, 0.000000, 0.000000],
            [0.000000, 1.000000, 1.000000],
            [0.000000, 1.000000, 0.800000],
            [0.000000, 1.000000, 0.600000],
            [0.000000, 1.000000, 0.400000],
            [0.000000, 1.000000, 0.200000],
            [0.000000, 1.000000, 0.000000],
            [0.000000, 0.800000, 1.000000],
            [0.000000, 0.800000, 0.800000],
            [0.000000, 0.800000, 0.600000],
            [0.000000, 0.800000, 0.400000],
            [0.000000, 0.800000, 0.200000],
            [0.000000, 0.800000, 0.000000],
            [0.000000, 0.600000, 1.000000],
            [0.000000, 0.600000, 0.800000],
            [0.000000, 0.600000, 0.600000],
            [0.000000, 0.600000, 0.400000],
            [0.000000, 0.600000, 0.200000],
            [0.000000, 0.600000, 0.000000],
            [0.000000, 0.400000, 1.000000],
            [0.000000, 0.400000, 0.800000],
            [0.000000, 0.400000, 0.600000],
            [0.000000, 0.400000, 0.400000],
            [0.000000, 0.400000, 0.200000],
            [0.000000, 0.400000, 0.000000],
            [0.000000, 0.200000, 1.000000],
            [0.000000, 0.200000, 0.800000],
            [0.000000, 0.200000, 0.600000],
            [0.000000, 0.200000, 0.400000],
            [0.000000, 0.200000, 0.200000],
            [0.000000, 0.200000, 0.000000],
            [0.000000, 0.000000, 1.000000],
            [0.000000, 0.000000, 0.800000],
            [0.000000, 0.000000, 0.600000],
            [0.000000, 0.000000, 0.400000],
            [0.000000, 0.000000, 0.200000],
            [0.933333, 0.000000, 0.000000],
            [0.866667, 0.000000, 0.000000],
            [0.733333, 0.000000, 0.000000],
            [0.666667, 0.000000, 0.000000],
            [0.533333, 0.000000, 0.000000],
            [0.466667, 0.000000, 0.000000],
            [0.333333, 0.000000, 0.000000],
            [0.266667, 0.000000, 0.000000],
            [0.133333, 0.000000, 0.000000],
            [0.066667, 0.000000, 0.000000],
            [0.000000, 0.933333, 0.000000],
            [0.000000, 0.866667, 0.000000],
            [0.000000, 0.733333, 0.000000],
            [0.000000, 0.666667, 0.000000],
            [0.000000, 0.533333, 0.000000],
            [0.000000, 0.466667, 0.000000],
            [0.000000, 0.333333, 0.000000],
            [0.000000, 0.266667, 0.000000],
            [0.000000, 0.133333, 0.000000],
            [0.000000, 0.066667, 0.000000],
            [0.000000, 0.000000, 0.933333],
            [0.000000, 0.000000, 0.866667],
            [0.000000, 0.000000, 0.733333],
            [0.000000, 0.000000, 0.666667],
            [0.000000, 0.000000, 0.533333],
            [0.000000, 0.000000, 0.466667],
            [0.000000, 0.000000, 0.333333],
            [0.000000, 0.000000, 0.266667],
            [0.000000, 0.000000, 0.133333],
            [0.000000, 0.000000, 0.066667],
            [0.933333, 0.933333, 0.933333],
            [0.866667, 0.866667, 0.866667],
            [0.733333, 0.733333, 0.733333],
            [0.666667, 0.666667, 0.666667],
            [0.533333, 0.533333, 0.533333],
            [0.466667, 0.466667, 0.466667],
            [0.333333, 0.333333, 0.333333],
            [0.266667, 0.266667, 0.266667],
            [0.133333, 0.133333, 0.133333],
            [0.066667, 0.066667, 0.066667],
            [0.000000, 0.000000, 0.000000]
        ]
        #Resolve the colours to their summed hash value for fast lookup.
        #They're written like this above just to keep track of the original values.
        for i in range(len(self.colData)):
            self.colData[i] = self.hash(self.colData[i])

        self.resolveTexCoords()

    '''
    Determine the coordinates relative to the texture.
    '''
    def resolveTexCoords(self):
        numTilesHeight = 16
        numTilesWidth = int(len(self.colData) / numTilesHeight)
        tileWidth = (1.0 / numTilesWidth) / 2.0
        tileHeight = (1.0 / numTilesHeight) / 2.0

        self.texCoords = [None] * len(self.colData)
        for i in range(len(self.colData)):
            tileX = i % numTilesWidth
            tileY = int(i / numTilesWidth)
            self.texCoords[i] = (tileX / numTilesWidth + tileWidth, tileY / numTilesHeight + tileHeight)
            print("coords for %i is %f, %f" % (i, self.texCoords[i][0], self.texCoords[i][1]))

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
            val = self.hash(self.vertColours[i])
            if not val in entries:
                targetIdx = self.colData.index(val)
                entries[val] = targetIdx
            self.vertColours[i] = entries[val]

    def hash(self, cols):
        finished = 0
        for i in range(len(cols)):
            intVal = int(cols[i] * 255)
            finished = finished | (intVal << 8 * i)

        return finished

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

    '''
    .obj files specify vertices and normals separately, and then match them up in the face definition.
    OgreXML expects there to be an entry for each vertice, even when they have the same position but different normals.
    So I have to match up vertex definitions with normal definitions to check if that combination has been specified before.
    If not, duplicate and push the values, change whatever is needed, register the new id and return it.
    '''
    def checkResolveFace(self, entries, face, newNorms):
        faceVertId = face[0] - 1
        faceNormId = face[1] - 1

        #Populate the norms regardless, each vertice needs a normal.
        newNorms[faceVertId] = self.vertNormals[faceNormId]

        if face in entries:
            return entries[face]

        newId = len(self.verts)
        self.verts.append(self.verts[faceVertId])
        self.vertColours.append(self.vertColours[faceVertId])
        self.texCoords.append(self.texCoords[faceVertId])
        newNorms.append(self.vertNormals[faceNormId])

        entries[face] = newId

        return newId

    def resolveFaces(self):
        entries = {}
        newNorms = [None] * len(self.verts)

        #Determine if this combination of vertices and normal values has been created for each vertice used.
        #If not then they need to be created
        newFaces = []
        for i in self.faces:
            f0 = self.checkResolveFace(entries, i[0], newNorms)
            f1 = self.checkResolveFace(entries, i[1], newNorms)
            f2 = self.checkResolveFace(entries, i[2], newNorms)
            f3 = self.checkResolveFace(entries, i[3], newNorms)

            newFaces.append([f1, f2, f3])
            newFaces.append([f3, f0, f1])

        self.faces = newFaces
        self.vertNormals = newNorms
        assert len(self.vertNormals) == len(self.verts)

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
