#pragma once

#include "Prerequisites.h"
#include <string>
#include <vector>
#include "Pipeline/VoxToFaces.h"

namespace VoxelConverterTool {

    class FacesToObjFile {
    public:
        FacesToObjFile();
        ~FacesToObjFile();


        void writeToFile(const std::string& objFilePath, const OutputFaces& outFaces);

    private:
        void writeMesh(std::ofstream& objStream, const OutputFaces& outFaces);
    };

} // namespace VoxelConverterTool
