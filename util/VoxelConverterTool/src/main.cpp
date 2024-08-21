#include <iostream>

#include "File/VoxelFileParser.h"
#include "Pipeline/VoxToFaces.h"
#include "Pipeline/FacesToVerticesFile.h"

#include <cstring>

#include "Prerequisites.h"

enum Flags{
    FLAG_GREEDY_MESH,

    FLAG_MAX
};
enum Inputs{
    INPUT_INPUT_FILE,
    INPUT_OUTPUT_FILE,

    INPUT_MAX
};

void printHelp(){
    const char* help = "VoxelConverterTool - Convert an exported voxel file into a VoxMesh format. \n \
-g Enable greedy meshing (not implemented yet \n \
[inputFile] [outputFile]";

    std::cout << help << std::endl;
}

void parseArgs(int argc, char *argv[], bool (&totalFlags)[FLAG_MAX], const char* (&totalInputs)[INPUT_MAX]){

    int inputCount = 0;
    int current = 1;
    while(current < argc){
        const char* val = argv[current];
        if(strcmp(val, "-g") == 0){
            totalFlags[FLAG_GREEDY_MESH] = true;
        }else{
            //Assume it's an input
            totalInputs[inputCount] = val;
            inputCount++;
        }
        current++;
    }
}

int main(int argc, char *argv[]){
    if(argc <= 1){
        printHelp();
        return 0;
    }

    bool totalFlags[FLAG_MAX];
    const char* inputVals[INPUT_MAX];
    memset(&totalFlags[0], 0, sizeof(totalFlags));
    memset(&inputVals[0], 0, sizeof(inputVals));

    parseArgs(argc, argv, totalFlags, inputVals);

    VoxelConverterTool::VoxelFileParser p;
    VoxelConverterTool::ParsedVoxFile out;
    p.parseFile(inputVals[INPUT_INPUT_FILE], out);

    //
    VoxelConverterTool::OutputFaces outFaces;
    VoxelConverterTool::VoxToFaces f;
    f.voxToFaces(out, outFaces);

    VoxelConverterTool::FacesToVerticesFile outFile;
    outFile.writeToFile(inputVals[INPUT_OUTPUT_FILE], outFaces);

    return 0;
}
