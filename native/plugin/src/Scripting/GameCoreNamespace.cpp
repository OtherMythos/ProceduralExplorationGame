#include "GameCoreNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"
#include "ExplorationMapDataUserData.h"
#include "GameplayState.h"
#include "GamePrerequisites.h"
#include "Voxeliser/Voxeliser.h"

#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/TextureBoxUserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/MeshUserData.h"

#include "MapGen/ExplorationMapViewer.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/MapGen.h"

#include <sqstdblob.h>

namespace ProceduralExplorationGamePlugin{

    ProceduralExplorationGameCore::MapGen* GameCoreNamespace::currentMapGen = 0;

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

    SQInteger _processRegionTable(HSQUIRRELVM vm, ProceduralExplorationGameCore::RegionData& region){
        sq_pushnull(vm);
        while(SQ_SUCCEEDED(sq_next(vm,-2))){
            const SQChar *k;
            sq_getstring(vm, -2, &k);

            SQObjectType t = sq_gettype(vm, -1);
            if(t == OT_INTEGER){
                SQInteger val;
                sq_getinteger(vm, -1, &val);
                if(strcmp(k, "id") == 0){
                    region.id = val;
                }
                else if(strcmp(k, "total") == 0){
                    region.total = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "seedX") == 0){
                    region.seedX = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "seedY") == 0){
                    region.seedY = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "type") == 0){
                    region.type = static_cast<ProceduralExplorationGameCore::RegionType>(val);
                }
            }
            else if(t == OT_ARRAY){
                if(strcmp(k, "coords") == 0){
                    SQInteger arraySize = sq_getsize(vm, -1);
                    region.coords.resize(arraySize);
                    for(SQInteger i = 0; i < arraySize; i++){
                        sq_pushinteger(vm, i);
                        sq_get(vm, -2);

                        SQInteger worldPoint;
                        sq_getinteger(vm, -1, &worldPoint);
                        region.coords[i] = static_cast<ProceduralExplorationGameCore::WorldPoint>(worldPoint);

                        sq_pop(vm,1);
                    }

                }
            }

            sq_pop(vm,2); //pop the key and value
            AV::ScriptUtils::_debugStack(vm);
        }
        sq_pop(vm,1); //pops the null iterator

        AV::ScriptUtils::_debugStack(vm);
    }
    SQInteger _processRegionData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapData* data){
        SQInteger arraySize = sq_getsize(vm, -1);
        for(SQInteger i = 0; i < arraySize; i++){
            sq_pushinteger(vm, i);
            sq_get(vm, -2);

            SQObjectType t = sq_gettype(vm, -1);
            assert(t == OT_TABLE);

            ProceduralExplorationGameCore::RegionData region;
            _processRegionTable(vm, region);
            data->regionData.push_back(region);

            sq_pop(vm, 1);
        }
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
            else if(strcmp(k, "regionData") == 0){
                _processRegionData(vm, data);
            }
            sq_pop(vm,2); //pop the key and value
        }
        sq_pop(vm,1); //pops the null iterator



        ExplorationMapDataUserData::ExplorationMapDataToUserData(vm, data);

        return 1;
    }

    SQInteger GameCoreNamespace::setRegionFound(HSQUIRRELVM vm){
        SQInteger regionId;
        sq_getinteger(vm, 2, &regionId);
        SQBool found;
        sq_getbool(vm, 3, &found);

        ProceduralExplorationGameCore::RegionId region = static_cast<ProceduralExplorationGameCore::RegionId>(regionId);

        ProceduralExplorationGameCore::GameplayState::setRegionFound(region, found);
    }


    SQInteger GameCoreNamespace::setNewMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_CHECK_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, -1, &mapData));

        ProceduralExplorationGameCore::GameplayState::setNewMapData(mapData);
    }

    SQInteger GameCoreNamespace::createTerrainFromMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_CHECK_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, -1, &mapData));

        ProceduralExplorationGameCore::Voxeliser vox;
        //TOOD constant for max number of regions.
        Ogre::MeshPtr outPtrs[0xFF];
        AV::uint32 numRegions = 0;
        vox.createTerrainFromMapData("terrain", mapData, &outPtrs[0], &numRegions);

        sq_newarray(vm, numRegions);
        for(int i = 0; i < numRegions; i++){
            sq_pushinteger(vm, i);
            if(outPtrs[i].isNull()){
                sq_pushnull(vm);
            }else{
                AV::MeshUserData::MeshToUserData(vm, outPtrs[i]);
            }

            AV::ScriptUtils::_debugStack(vm);
            sq_set(vm, -3);
        }

        return 1;
    }

    SQInteger GameCoreNamespace::beginMapGen(HSQUIRRELVM vm){
        if(GameCoreNamespace::currentMapGen != 0){
            return sq_throwerror(vm, "Map gen is already in process");
        }
        GameCoreNamespace::currentMapGen = new ProceduralExplorationGameCore::MapGen();

        currentMapGen->beginMapGen();

        return 0;
    }

    SQInteger GameCoreNamespace::getMapGenStage(HSQUIRRELVM vm){
        if(!GameCoreNamespace::currentMapGen){
            return sq_throwerror(vm, "Map gen is not active.");
        }
        sq_pushinteger(vm, GameCoreNamespace::currentMapGen->getCurrentStage());

        return 1;
    }

    SQInteger GameCoreNamespace::getTotalMapGenStages(HSQUIRRELVM vm){
        sq_pushinteger(vm, ProceduralExplorationGameCore::MapGen::getNumTotalStages());

        return 1;
    }

    SQInteger GameCoreNamespace::checkClaimMapGen(HSQUIRRELVM vm){
        if(!GameCoreNamespace::currentMapGen){
            return sq_throwerror(vm, "Map gen is not active.");
        }

        if(currentMapGen->isFinished()){
            //TODO for now.
            sq_pushbool(vm, true);
        }else{
            sq_pushnull(vm);
        }

        return 1;
    }

    void GameCoreNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, getGameCoreVersion, "getGameCoreVersion");

        AV::ScriptUtils::addFunction(vm, fillBufferWithMapLean, "fillBufferWithMapLean", 3, ".uu");
        AV::ScriptUtils::addFunction(vm, tableToExplorationMapData, "tableToExplorationMapData", 2, ".t");
        AV::ScriptUtils::addFunction(vm, setRegionFound, "setRegionFound", 3, ".ib");
        AV::ScriptUtils::addFunction(vm, setNewMapData, "setNewMapData", 2, ".u");
        AV::ScriptUtils::addFunction(vm, createTerrainFromMapData, "createTerrainFromMapData", 3, ".su");

        AV::ScriptUtils::addFunction(vm, beginMapGen, "beginMapGen");
        AV::ScriptUtils::addFunction(vm, getMapGenStage, "getMapGenStage");
        AV::ScriptUtils::addFunction(vm, checkClaimMapGen, "checkClaimMapGen");
        AV::ScriptUtils::addFunction(vm, getTotalMapGenStages, "getTotalMapGenStages");
    }

};
