#include <iostream>

#include "File/VoxelFileParser.h"
#include "Pipeline/VoxToFaces.h"
#include "Pipeline/FacesToVerticesFile.h"
#include "Pipeline/FaceMerger.h"
#include "Pipeline/AutoCentre.h"
#include "Util/Timer.h"

#include <cstring>
#include <sstream>

#include "Prerequisites.h"

enum Flags{
    FLAG_DISABLE_GREEDY_MESH,
    FLAG_AUTO_CENTRE,
    FLAG_DISABLE_FACE,
    FLAG_DISABLE_AMBIENT,

    FLAG_MAX
};
enum Inputs{
    INPUT_INPUT_FILE,
    INPUT_OUTPUT_FILE,

    INPUT_MAX
};

struct InputArgs{
    bool totalFlags[FLAG_MAX];
    const char* totalInputs[INPUT_MAX];
    bool disabledFaces[VoxelConverterTool::MAX_FACES];
};

void printHelp(){
    const char* help = "VoxelConverterTool - Convert an exported voxel file into a VoxMesh format. \n \
-g Disable face merging\n \
-c Enable auto centering, where the tool will shift the origin of the mesh automatically\n \
-f Disable a specific number of faces. Faces to be disabled are deliniated with a comma, i.e '1,2'\n \
-a Disable all ambient calculations\n \
[inputFile] [outputFile]";

    std::cout << help << std::endl;
}

void printStats(const VoxelConverterTool::OutputFaces& out){
    std::cout << std::endl << "Wrote " << out.outFaces.size() << " faces" << std::endl;
}

void parseDisableFaces(InputArgs& args, const char* input){
    if (!input || *input == '\0') {
        throw std::invalid_argument("Input string is null or empty");
    }

    std::set<int> result;
    std::stringstream ss(input);
    std::string token;

    while (std::getline(ss, token, ',')) {
        if (token.empty()) {
            throw std::invalid_argument("Malformed input: consecutive commas or trailing comma detected");
        }

        try {
            result.insert(std::stoi(token));
        } catch (const std::exception&) {
            throw std::invalid_argument("Malformed input: contains non-numeric values");
        }
    }

    for(int i : result){
        if(i < 0 || i >= VoxelConverterTool::MAX_FACES) continue;
        args.disabledFaces[i] = true;
    }

    return result;
}

void parseArgs(int argc, char *argv[], InputArgs& args){

    int inputCount = 0;
    int current = 1;
    bool flagValue = false;
    Flags flagType = FLAG_MAX;
    while(current < argc){
        const char* val = argv[current];
        if(!flagValue){
            if(strcmp(val, "-g") == 0){
                args.totalFlags[FLAG_DISABLE_GREEDY_MESH] = true;
            }else if(strcmp(val, "-c") == 0){
                args.totalFlags[FLAG_AUTO_CENTRE] = true;
            }else if(strcmp(val, "-f") == 0){
                flagType = FLAG_DISABLE_FACE;
                args.totalFlags[flagType] = true;
                flagValue = true;
            }else if(strcmp(val, "-a") == 0){
                args.totalFlags[FLAG_DISABLE_AMBIENT] = true;
            }else{
                //Assume it's an input
                args.totalInputs[inputCount] = val;
                inputCount++;
            }
        }else{
            if(flagType == FLAG_DISABLE_FACE){
                parseDisableFaces(args, val);
            }
            flagValue = false;
        }
        current++;
    }
}

int main(int argc, char *argv[]){
    if(argc <= 1){
        printHelp();
        return 0;
    }

    InputArgs inputArgs;
    memset(&inputArgs, 0, sizeof(InputArgs));

    parseArgs(argc, argv, inputArgs);

    if(!inputArgs.totalInputs[INPUT_INPUT_FILE]){
        std::cerr << "Error: No input file specified." << std::endl;
        printHelp();
        return 1;
    }
    if(!inputArgs.totalInputs[INPUT_OUTPUT_FILE]){
        std::cerr << "Error: No output file specified." << std::endl;
        printHelp();
        return 1;
    }

    VoxelConverterTool::Timer t;
    t.start();

    VoxelConverterTool::VoxelFileParser p;
    VoxelConverterTool::ParsedVoxFile out;
    p.parseFile(inputArgs.totalInputs[INPUT_INPUT_FILE], out);

    if(out.data.empty()){
        std::cerr << "Error: No vertices parsed for input." << std::endl;
        return 1;
    }

    t.stop();
    std::cout << "Time to parse file: " << t << std::endl;

    t.stop();
    std::cout << "Time to parse file: " << t << std::endl;

    if(inputArgs.totalFlags[FLAG_AUTO_CENTRE]){
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
    f.voxToFaces(out, outFaces, inputArgs.disabledFaces, inputArgs.totalFlags[FLAG_DISABLE_AMBIENT]);
    t.stop();
    std::cout << "Time to resolve faces: " << t << std::endl;

    size_t previousNumFaces = outFaces.outFaces.size();
    size_t mergedFaces = outFaces.outFaces.size();
    if(!inputArgs.totalFlags[FLAG_DISABLE_GREEDY_MESH]){
        t.start();
        VoxelConverterTool::FaceMerger merger;
        outFaces = merger.mergeFaces(outFaces);
        t.stop();
        std::cout << "Time to perform greedy meshing: " << t << std::endl;
        mergedFaces = outFaces.outFaces.size();
    }

    t.start();
    VoxelConverterTool::FacesToVerticesFile outFile;
    outFile.writeToFile(inputArgs.totalInputs[INPUT_OUTPUT_FILE], outFaces);

    printStats(outFaces);

    return 0;
}
