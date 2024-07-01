#include "GameCoreNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"
#include "ExplorationMapDataUserData.h"

#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/TextureBoxUserData.h"

#include "MapGen/ExplorationMapViewer.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <sqstdblob.h>

namespace ProceduralExplorationGamePlugin{

    SQInteger GameCoreNamespace::getGameCoreVersion(HSQUIRRELVM vm){


        return 1;
    }

    SQInteger GameCoreNamespace::fillBufferWithMapLean(HSQUIRRELVM vm){
        Ogre::TextureBox* outTexture;
        AV::TextureBoxUserData::readTextureBoxFromUserData(vm, 2, &outTexture);

        ProceduralExplorationGameCore::ExplorationMapData* data;
        SCRIPT_CHECK_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 3, &data));

        ProceduralExplorationGameCore::ExplorationMapViewer viewer;
        viewer.fillStagingTexture(outTexture, data);

        return 1;
    }

    SQInteger GameCoreNamespace::tableToExplorationMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* data = new ProceduralExplorationGameCore::ExplorationMapData();

        sq_pushnull(vm);
        while(SQ_SUCCEEDED(sq_next(vm,-2))){
            //here -1 is the value and -2 is the key
            const SQChar *k;
            sq_getstring(vm, -2, &k);

            SQObjectType t = sq_gettype(vm, -1);
            if(t == OT_INTEGER){
                SQInteger val;
                sq_getinteger(vm, -1, &val);
                if(strcmp(k, "width") == 0){
                    data->width = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "height") == 0){
                    data->height = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "seed") == 0){
                    data->seed = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "moistureSeed") == 0){
                    data->moistureSeed = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "variationSeed") == 0){
                    data->variationSeed = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "seaLevel") == 0){
                    data->seaLevel = static_cast<AV::uint32>(val);
                }
            }
            sq_pop(vm,2); //pop the key and value
        }
        sq_pop(vm,1); //pops the null iterator

        /*
        ProceduralExplorationGameCore::ExplorationMapData::BufferData bufData;
        data->calculateBuffer(&bufData);
        void* bufferData = malloc(bufData.size);
        memset(bufferData, 0x0, bufData.size);
         */

        /*
        data->voxelBuffer = bufferData;
        data->secondaryVoxelBuffer = static_cast<AV::uint32*>(bufferData) + bufData.secondaryVoxel;
        data->blueNoiseBuffer = static_cast<AV::uint32*>(bufferData) + bufData.blueNoise;
         */



        sq_pushnull(vm);
        while(SQ_SUCCEEDED(sq_next(vm,-2))){
            //here -1 is the value and -2 is the key
            const SQChar *k;
            sq_getstring(vm, -2, &k);

            SQObjectType t = sq_gettype(vm, -1);
            if(strcmp(k, "voxelBuffer") == 0){
                SQUserPointer buffer = 0;
                sqstd_getblob(vm, -1, &buffer);
                data->voxelBuffer = static_cast<void*>(buffer);
            }
            else if(strcmp(k, "secondaryVoxBuffer") == 0){
                SQUserPointer buffer = 0;
                sqstd_getblob(vm, -1, &buffer);
                data->secondaryVoxelBuffer = static_cast<void*>(buffer);
            }
            else if(strcmp(k, "blueNoiseBuffer") == 0){
                SQUserPointer buffer = 0;
                sqstd_getblob(vm, -1, &buffer);
                data->blueNoiseBuffer = static_cast<void*>(buffer);
            }
            sq_pop(vm,2); //pop the key and value
        }
        sq_pop(vm,1); //pops the null iterator



        ExplorationMapDataUserData::ExplorationMapDataToUserData(vm, data);

        return 1;
    }

    void GameCoreNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, getGameCoreVersion, "getGameCoreVersion");

        AV::ScriptUtils::addFunction(vm, fillBufferWithMapLean, "fillBufferWithMapLean", 3, ".uu");
        AV::ScriptUtils::addFunction(vm, tableToExplorationMapData, "tableToExplorationMapData", 2, ".t");
    }

};
