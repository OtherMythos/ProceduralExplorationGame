#include <iostream>

#include "File/VoxelFileParser.h"
#include "Pipeline/VoxToFaces.h"
#include "Pipeline/FacesToVerticesFile.h"
#include "Pipeline/FaceMerger.h"
#include "Pipeline/AutoCentre.h"

#include <cstring>

#include "Prerequisites.h"

enum Flags{
    FLAG_GREEDY_MESH,
    FLAG_AUTO_CENTRE,

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
-c Enable auto centering, where the tool will shift the origin of the mesh automatically\n \
[inputFile] [outputFile]";

    std::cout << help << std::endl;
}

void printStats(const VoxelConverterTool::OutputFaces& out){
    std::cout << "Wrote " << out.outFaces.size() << " faces" << std::endl;
}

void parseArgs(int argc, char *argv[], bool (&totalFlags)[FLAG_MAX], const char* (&totalInputs)[INPUT_MAX]){

    int inputCount = 0;
    int current = 1;
    while(current < argc){
        const char* val = argv[current];
        if(strcmp(val, "-g") == 0){
            totalFlags[FLAG_GREEDY_MESH] = true;
        }else if(strcmp(val, "-c") == 0){
            totalFlags[FLAG_AUTO_CENTRE] = true;
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

    if(!inputVals[INPUT_INPUT_FILE]){
        std::cerr << "Error: No input file specified." << std::endl;
        printHelp();
        return 1;
    }
    if(!inputVals[INPUT_OUTPUT_FILE]){
        std::cerr << "Error: No output file specified." << std::endl;
        printHelp();
        return 1;
    }

    VoxelConverterTool::VoxelFileParser p;
    VoxelConverterTool::ParsedVoxFile out;
    p.parseFile(inputVals[INPUT_INPUT_FILE], out);

    if(out.data.empty()){
        std::cerr << "Error: No vertices parsed for input." << std::endl;
        return 1;
    }

    if(totalFlags[FLAG_AUTO_CENTRE]){
        VoxelConverterTool::AutoCentre c;
        c.centreForParsedFile(out);
    }

    //
    VoxelConverterTool::OutputFaces outFaces;
    VoxelConverterTool::VoxToFaces f;
    f.voxToFaces(out, outFaces);

    VoxelConverterTool::FaceMerger merger;
    VoxelConverterTool::OutputFaces mergedFaces = merger.mergeFaces(outFaces);

    VoxelConverterTool::FacesToVerticesFile outFile;
    outFile.writeToFile(inputVals[INPUT_OUTPUT_FILE], mergedFaces);

    printStats(outFaces);

    return 0;
}
