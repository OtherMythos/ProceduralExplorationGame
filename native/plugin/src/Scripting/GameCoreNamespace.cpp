#include "GameCoreNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"
#include "ExplorationMapDataUserData.h"
#include "VisitedPlaceMapDataUserData.h"
#include "GameplayState.h"
#include "GamePrerequisites.h"
#include "Voxeliser/Voxeliser.h"

#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/TextureBoxUserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/MeshUserData.h"

#include "MapGen/ExplorationMapViewer.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/MapGen.h"

#include "VisitedPlaces/VisitedPlacesParser.h"

#include "../../../../src/Versions.h.nut"

#include <sqstdblob.h>

namespace ProceduralExplorationGamePlugin{

    ProceduralExplorationGameCore::MapGen* GameCoreNamespace::currentMapGen = 0;
    ProceduralExplorationGameCore::VisitedPlacesParser* GameCoreNamespace::currentVisitedPlacesParser = 0;

    SQInteger GameCoreNamespace::getGameCoreVersion(HSQUIRRELVM vm){
        sq_newtableex(vm, 4);

        sq_pushstring(vm, _SC("major"), 5);
        sq_pushinteger(vm, GAME_VERSION_MAJOR);
        sq_newslot(vm,-3,SQFalse);

        sq_pushstring(vm, _SC("minor"), 5);
        sq_pushinteger(vm, GAME_VERSION_MINOR);
        sq_newslot(vm,-3,SQFalse);

        sq_pushstring(vm, _SC("patch"), 5);
        sq_pushinteger(vm, GAME_VERSION_PATCH);
        sq_newslot(vm,-3,SQFalse);

        sq_pushstring(vm, _SC("suffix"), 6);
        sq_pushstring(vm, GAME_VERSION_SUFFIX, -1);
        sq_newslot(vm,-3,SQFalse);
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

    SQInteger GameCoreNamespace::fillBufferWithMapComplex(HSQUIRRELVM vm){
        Ogre::TextureBox* outTexture;
        AV::TextureBoxUserData::readTextureBoxFromUserData(vm, 2, &outTexture);

        ProceduralExplorationGameCore::ExplorationMapData* data;
        SCRIPT_CHECK_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 3, &data));

        SQInteger drawOptionsHash;
        sq_getinteger(vm, 4, &drawOptionsHash);

        ProceduralExplorationGameCore::ExplorationMapViewer viewer;
        viewer.fillStagingTextureComplex(outTexture, data, static_cast<AV::uint32>(drawOptionsHash));

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
        }
        sq_pop(vm,1); //pops the null iterator

        return 0;
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

        return 0;
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

    SQInteger GameCoreNamespace::tableToExplorationMapInputData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapInputData* data){
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
                else if(strcmp(k, "numRivers") == 0){
                    data->numRivers = static_cast<AV::uint32>(val);
                }
                else if(strcmp(k, "numRegions") == 0){
                    data->numRegions = static_cast<AV::uint32>(val);
                }
            }
            else if(t == OT_ARRAY){
                if(strcmp(k, "placeFrequency") == 0){
                    //Read the values from the array.
                    SQInteger placesSize = sq_getsize(vm, -1);
                    if(placesSize != (size_t)ProceduralExplorationGameCore::PlaceType::MAX){
                        sq_throwerror(vm, "Invalid place frequency entries.");
                    }
                    for(SQInteger i = 0; i < placesSize; i++){
                        sq_pushinteger(vm, i);
                        sq_rawget(vm, -2);

                        SQInteger frequency = 0;
                        sq_getinteger(vm, -1, &frequency);
                        data->placeFrequency[i] = frequency;

                        sq_pop(vm, 1);
                    }
                }
            }
            sq_pop(vm,2); //pop the key and value
        }
        sq_pop(vm,1); //pops the null iterator

        return 0;
    }

    SQInteger GameCoreNamespace::setRegionFound(HSQUIRRELVM vm){
        SQInteger regionId;
        sq_getinteger(vm, 2, &regionId);
        SQBool found;
        sq_getbool(vm, 3, &found);

        ProceduralExplorationGameCore::RegionId region = static_cast<ProceduralExplorationGameCore::RegionId>(regionId);
        if(region == ProceduralExplorationGameCore::INVALID_REGION_ID){
            return sq_throwerror(vm, "Invalid region id requested.");
        }

        ProceduralExplorationGameCore::GameplayState::setRegionFound(region, found);

        return 0;
    }


    SQInteger GameCoreNamespace::setNewMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_CHECK_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, -1, &mapData));

        ProceduralExplorationGameCore::GameplayState::setNewMapData(mapData);

        return 0;
    }

    SQInteger GameCoreNamespace::createTerrainFromMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_CHECK_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, -1, &mapData));

        ProceduralExplorationGameCore::Voxeliser vox;
        //TOOD constant for max number of regions.
        Ogre::MeshPtr outPtrs[0xFF];
        AV::uint32 numRegions = 0;
        //TODO script is not parsing the string and applying here.
        vox.createTerrainFromMapData("terrain", mapData, &outPtrs[0], &numRegions);

        sq_newarray(vm, numRegions);
        for(int i = 0; i < numRegions; i++){
            sq_pushinteger(vm, i);
            if(outPtrs[i].isNull()){
                sq_pushnull(vm);
            }else{
                AV::MeshUserData::MeshToUserData(vm, outPtrs[i]);
            }
            sq_rawset(vm, -3);
        }

        return 1;
    }

    SQInteger GameCoreNamespace::beginMapGen(HSQUIRRELVM vm){
        if(GameCoreNamespace::currentMapGen != 0){
            return sq_throwerror(vm, "Map gen is already in progress");
        }
        GameCoreNamespace::currentMapGen = new ProceduralExplorationGameCore::MapGen();

        ProceduralExplorationGameCore::ExplorationMapInputData* inputData = new ProceduralExplorationGameCore::ExplorationMapInputData();
        SQInteger result = tableToExplorationMapInputData(vm, inputData);
        if(result != 0){
            return result;
        }

        currentMapGen->beginMapGen(inputData);

        return 0;
    }

    SQInteger GameCoreNamespace::beginParseVisitedLocation(HSQUIRRELVM vm){
        if(GameCoreNamespace::currentVisitedPlacesParser != 0){
            return sq_throwerror(vm, "Visited places parse is already active.");
        }

        const SQChar *visitedLocationName;
        sq_getstring(vm, -1, &visitedLocationName);

        GameCoreNamespace::currentVisitedPlacesParser = new ProceduralExplorationGameCore::VisitedPlacesParser();

        currentVisitedPlacesParser->beginMapGen(visitedLocationName);

        return 0;
    }

    SQInteger GameCoreNamespace::checkClaimParsedVisitedLocation(HSQUIRRELVM vm){
        if(!GameCoreNamespace::currentVisitedPlacesParser){
            return sq_throwerror(vm, "Visited place parser is not active.");
        }

        if(currentVisitedPlacesParser->isFinished()){
            ProceduralExplorationGameCore::VisitedPlaceMapData* mapData = GameCoreNamespace::currentVisitedPlacesParser->claimMapData();
            VisitedPlaceMapDataUserData::visitedPlaceMapDataToUserData(vm, mapData);
            delete GameCoreNamespace::currentVisitedPlacesParser;
            GameCoreNamespace::currentVisitedPlacesParser = 0;
        }else{
            sq_pushnull(vm);
        }

        return 1;
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
            ProceduralExplorationGameCore::ExplorationMapData* mapData = GameCoreNamespace::currentMapGen->claimMapData();
            ExplorationMapDataUserData::ExplorationMapDataToUserData(vm, mapData);
            delete GameCoreNamespace::currentMapGen;
            GameCoreNamespace::currentMapGen = 0;
        }else{
            sq_pushnull(vm);
        }

        return 1;
    }

    SQInteger GameCoreNamespace::getNameForMapGenStage(HSQUIRRELVM vm){
        SQInteger idx;
        sq_getinteger(vm, -1, &idx);
        const std::string& stageName = ProceduralExplorationGameCore::MapGen::getNameForStage(idx);
        sq_pushstring(vm, stageName.c_str(), -1);

        return 1;
    }


    void GameCoreNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, getGameCoreVersion, "getGameCoreVersion");

        AV::ScriptUtils::addFunction(vm, fillBufferWithMapLean, "fillBufferWithMapLean", 3, ".uu");
        AV::ScriptUtils::addFunction(vm, fillBufferWithMapComplex, "fillBufferWithMapComplex", 4, ".uui");
        AV::ScriptUtils::addFunction(vm, tableToExplorationMapData, "tableToExplorationMapData", 2, ".t");
        AV::ScriptUtils::addFunction(vm, setRegionFound, "setRegionFound", 3, ".ib");
        AV::ScriptUtils::addFunction(vm, setNewMapData, "setNewMapData", 2, ".u");
        AV::ScriptUtils::addFunction(vm, createTerrainFromMapData, "createTerrainFromMapData", 3, ".su");
        AV::ScriptUtils::addFunction(vm, getNameForMapGenStage, "getNameForMapGenStage", 2, ".i");

        AV::ScriptUtils::addFunction(vm, beginMapGen, "beginMapGen", 2, ".t");
        AV::ScriptUtils::addFunction(vm, getMapGenStage, "getMapGenStage");
        AV::ScriptUtils::addFunction(vm, checkClaimMapGen, "checkClaimMapGen");
        AV::ScriptUtils::addFunction(vm, getTotalMapGenStages, "getTotalMapGenStages");

        AV::ScriptUtils::addFunction(vm, beginParseVisitedLocation, "beginParseVisitedLocation");
        AV::ScriptUtils::addFunction(vm, checkClaimParsedVisitedLocation, "checkClaimParsedVisitedLocation");
    }

};
