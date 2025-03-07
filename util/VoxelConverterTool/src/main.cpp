#include <iostream>

#include "File/VoxelFileParser.h"
#include "Pipeline/VoxToFaces.h"
#include "Pipeline/FacesToVerticesFile.h"
#include "Pipeline/FaceMerger.h"
#include "Pipeline/AutoCentre.h"
#include "Util/Timer.h"

#include <cstring>

#include "Prerequisites.h"

enum Flags{
    FLAG_DISABLE_GREEDY_MESH,
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
-g Disable face merging\n \
-c Enable auto centering, where the tool will shift the origin of the mesh automatically\n \
[inputFile] [outputFile]";

    std::cout << help << std::endl;
}

void printStats(const VoxelConverterTool::OutputFaces& out){
    std::cout << std::endl << "Wrote " << out.outFaces.size() << " faces" << std::endl;
}

void parseArgs(int argc, char *argv[], bool (&totalFlags)[FLAG_MAX], const char* (&totalInputs)[INPUT_MAX]){

    int inputCount = 0;
    int current = 1;
    while(current < argc){
        const char* val = argv[current];
        if(strcmp(val, "-g") == 0){
            totalFlags[FLAG_DISABLE_GREEDY_MESH] = true;
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

    VoxelConverterTool::Timer t;
    t.start();

    VoxelConverterTool::VoxelFileParser p;
    VoxelConverterTool::ParsedVoxFile out;
    p.parseFile(inputVals[INPUT_INPUT_FILE], out);

    if(out.data.empty()){
        std::cerr << "Error: No vertices parsed for input." << std::endl;
        return 1;
    }

    t.stop();
    std::cout << "Time to parse file: " << t << std::endl;

    if(totalFlags[FLAG_AUTO_CENTRE]){
        t.start();
        VoxelConverterTool::AutoCentre c;
        c.centreForParsedFile(out);
        t.stop();
        std::cout << "Time to centre voxels: " << t << std::endl;
    }

    //
    t.start();
    VoxelConverterTool::OutputFaces outFaces;
    VoxelConverterTool::VoxToFaces f;
    f.voxToFaces(out, outFaces);
    t.stop();
    std::cout << "Time to resolve faces: " << t << std::endl;

    size_t previousNumFaces = outFaces.outFaces.size();
    size_t mergedFaces = outFaces.outFaces.size();
    if(!totalFlags[FLAG_DISABLE_GREEDY_MESH]){
        t.start();
        VoxelConverterTool::FaceMerger merger;
        outFaces = merger.mergeFaces(outFaces);
        t.stop();
        std::cout << "Time to perform greedy meshing: " << t << std::endl;
        mergedFaces = outFaces.outFaces.size();
    }

    t.start();
    VoxelConverterTool::FacesToVerticesFile outFile;
    outFile.writeToFile(inputVals[INPUT_OUTPUT_FILE], outFaces);
    t.stop();
    std::cout << "Time to write vertices: " << t << std::endl;

    if(!totalFlags[FLAG_DISABLE_GREEDY_MESH]){
        std::cout << "Pre merge face number: " << previousNumFaces << std::endl;
        std::cout << "Merged face number: " << mergedFaces << std::endl;
        std::cout << "Merge improvements: " << (float(mergedFaces) / float(previousNumFaces)) << std::endl;
    }

    printStats(outFaces);

    return 0;
}
