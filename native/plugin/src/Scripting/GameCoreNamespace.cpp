#include "GameCoreNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Hlms/DatablockUserData.h"
#include "MapGen/Script/ExplorationMapDataUserData.h"
#include "VisitedPlaceMapDataUserData.h"
#include "GameplayState.h"
#include "GamePrerequisites.h"
#include "Voxeliser/Voxeliser.h"
#include "Voxeliser/VoxSceneDumper.h"
#include "MapGen/Script/MapGenScriptManager.h"
#include "MapGen/MapGenScriptClient.h"
#include "MapGen/Script/MapGenScriptVM.h"
#include "PluginBaseSingleton.h"
#include "Platform/iOS/HapticFeedback.h"
#include "Ogre/AreaProceduralWorldEmitter.h"

#include "System/Util/PathUtils.h"

#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/TextureBoxUserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/MeshUserData.h"

#include "VisitedPlaces/VoxMeshSceneDataInserter.h"
#include "VisitedPlaces/TileDataParser.h"
#include "Scripting/ScriptNamespace/Classes/Scene/ParsedAvSceneUserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Scene/SceneNodeUserData.h"
#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"
#include "Scripting/ScriptNamespace/Classes/Animation/AnimationInfoUserData.h"
#include "Scripting/ScriptNamespace/Classes/ColourValueUserData.h"
#include "Collision/CollisionDetectionWorld.h"
#include "Scripting/ScriptNamespace/Classes/CollisionWorldClass.h"
#include "Scripting/ScriptNamespace/ScriptGetterUtils.h"
#include "Scripting/SquirrelDeepCopy.h"

#include "Compositor/OgreCompositorManager2.h"
#include "Compositor/OgreCompositorNodeDef.h"
#include "Compositor/Pass/PassScene/OgreCompositorPassSceneDef.h"

#include "VisitedPlaces/OverworldVoxMeshSceneDataInserter.h"

#include "Scripting/DataPointFileUserData.h"

#include "MapGen/ExplorationMapViewer.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/BaseClient/OverworldMapTextureGenerator.h"
#include "MapGen/MapGen.h"
#include "System/OgreResourceHelper.h"

#include "VisitedPlaces/VisitedPlacesParser.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Scene/MovableObjectUserData.h"
#include "Scripting/ScriptNamespace/SceneNamespace.h"

#include "System/Base.h"
#include "System/BaseSingleton.h"

#include "Ogre/OgreVoxMeshItem.h"
#include "Ogre/OgreVoxMeshManager.h"
#include "Hlms/Pbs/OgreHlmsPbsDatablock.h"

#include "GameCorePBSHlmsListener.h"

#include "../../../../src/Versions.h.nut"

#include <sqstdblob.h>

namespace ProceduralExplorationGamePlugin{

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

        sq_pushstring(vm, _SC("build"), 5);
        #ifdef _DEBUG
            sq_pushstring(vm, _SC("Debug"), 5);
        #else
            sq_pushstring(vm, _SC("Release"), 7);
        #endif
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
        SCRIPT_CHECK_RESULT(ProceduralExplorationGameCore::ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 3, &data));

        ProceduralExplorationGameCore::ExplorationMapViewer viewer;
        viewer.fillStagingTexture(outTexture, data);

        return 1;
    }

    SQInteger GameCoreNamespace::fillBufferWithMapComplex(HSQUIRRELVM vm){
        Ogre::TextureBox* outTexture;
        AV::TextureBoxUserData::readTextureBoxFromUserData(vm, 2, &outTexture);

        ProceduralExplorationGameCore::ExplorationMapData* data;
        SCRIPT_CHECK_RESULT(ProceduralExplorationGameCore::ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 3, &data));

        SQInteger drawOptionsHash;
        sq_getinteger(vm, 4, &drawOptionsHash);

        ProceduralExplorationGameCore::ExplorationMapViewer viewer;
        viewer.fillStagingTextureComplex(outTexture, data, static_cast<AV::uint32>(drawOptionsHash));

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
                /*
                if(strcmp(k, "width") == 0){
                    //data->width = static_cast<AV::uint32>(val);
                    data->uint32("width", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "height") == 0){
                    //data->height = static_cast<AV::uint32>(val);
                    data->uint32("height", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "seed") == 0){
                    //data->seed = static_cast<AV::uint32>(val);
                    data->uint32("seed", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "moistureSeed") == 0){
                    //data->moistureSeed = static_cast<AV::uint32>(val);
                    data->uint32("moistureSeed", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "variationSeed") == 0){
                    //data->variationSeed = static_cast<AV::uint32>(val);
                    data->uint32("variationSeed", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "seaLevel") == 0){
                    //data->seaLevel = static_cast<AV::uint32>(val);
                    data->uint32("seaLevel", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "numRivers") == 0){
                    //data->numRivers = static_cast<AV::uint32>(val);
                    data->uint32("numRivers", static_cast<AV::uint32>(val));
                }
                else if(strcmp(k, "numRegions") == 0){
                    //data->numRegions = static_cast<AV::uint32>(val);
                    data->uint32("numRegions", static_cast<AV::uint32>(val));
                }
                 */
                ProceduralExplorationGameCore::MapDataEntry e;
                e.value.uint32 = static_cast<AV::uint32>(val);
                e.type = ProceduralExplorationGameCore::MapDataEntryType::UINT32;
                data->setEntry(k, e);
            }
            else if(t == OT_ARRAY){
                /*
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
                        //data->placeFrequency[i] = frequency;

                        sq_pop(vm, 1);
                    }
                }
                 */
            }
            sq_pop(vm,2); //pop the key and value
        }
        sq_pop(vm,1); //pops the null iterator

        return 0;
    }

    SQInteger GameCoreNamespace::getRegionFound(HSQUIRRELVM vm){
        SQInteger regionId;
        sq_getinteger(vm, 2, &regionId);
        ProceduralExplorationGameCore::RegionId region = static_cast<ProceduralExplorationGameCore::RegionId>(regionId);
        if(region == ProceduralExplorationGameCore::INVALID_REGION_ID){
            return sq_throwerror(vm, "Invalid region id requested.");
        }

        bool regionFound = ProceduralExplorationGameCore::GameplayState::getFoundRegion(region);
        sq_pushbool(vm, regionFound);

        return 1;
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
        SCRIPT_CHECK_RESULT(ProceduralExplorationGameCore::ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, -1, &mapData));

        ProceduralExplorationGameCore::GameplayState::setNewMapData(mapData);

        return 0;
    }

    SQInteger GameCoreNamespace::createTerrainFromMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_CHECK_RESULT(ProceduralExplorationGameCore::ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, -1, &mapData));

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
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        ProceduralExplorationGameCore::ExplorationMapInputData* inputData = new ProceduralExplorationGameCore::ExplorationMapInputData();
        SQInteger result = tableToExplorationMapInputData(vm, inputData);
        if(result != 0){
            return result;
        }

        mapGen->beginMapGen(inputData);

        return 0;
    }

    SQInteger GameCoreNamespace::recollectMapGenSteps(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        mapGen->recollectMapGenSteps();

        return 0;
    }

    SQInteger GameCoreNamespace::destroyMapData(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* data;
        SCRIPT_CHECK_RESULT(ProceduralExplorationGameCore::ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 2, &data));

        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        mapGen->destroyMapData(data);

        return 0;
    }

    SQInteger GameCoreNamespace::setCustomPassBufferValue(HSQUIRRELVM vm){
        Ogre::Vector3 val;
        SQInteger result = AV::ScriptGetterUtils::vector3Read(vm, &val);
        if(result != 0) return result;

        GameCorePBSHlmsListener::mCustomValues = val;

        return 0;
    }

    SQInteger GameCoreNamespace::setPassBufferFogValue(HSQUIRRELVM vm){
        Ogre::Vector3 val;
        SQInteger result = AV::ScriptGetterUtils::vector3Read(vm, &val);
        if(result != 0) return result;

        GameCorePBSHlmsListener::mFogColour = val;

        return 0;
    }

    SQInteger GameCoreNamespace::setPassBufferFogStartEnd(HSQUIRRELVM vm){
        Ogre::Vector2 val;
        SQInteger result = AV::ScriptGetterUtils::read2FloatsOrVec2(vm, &val);
        if(result != 0) return result;

        GameCorePBSHlmsListener::mFogStartEnd = val;

        return 0;
    }

    SQInteger GameCoreNamespace::registerVoxel(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        SQInteger sVox, sId;
        Ogre::ColourValue sColour;
        sq_getinteger(vm, 2, &sVox);
        sq_getinteger(vm, 3, &sId);
        AV::ColourValueUserData::readColourValueFromUserData(vm, 4, &sColour);

        ProceduralExplorationGameCore::MapGen::VoxelId vox = static_cast<ProceduralExplorationGameCore::MapGen::VoxelId>(sVox);
        AV::uint8 colId = static_cast<AV::uint8>(sId);
        AV::uint32 colourABGR = sColour.getAsABGR();

        mapGen->registerVoxel(vox, colId, colourABGR);

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

    SQInteger GameCoreNamespace::setMapsDirectory(HSQUIRRELVM vm){
        const SQChar *mapName;
        sq_getstring(vm, 2, &mapName);

        ProceduralExplorationGameCore::VisitedPlacesParser::mMapsDirectory = mapName;

        return 0;
    }

    SQInteger GameCoreNamespace::getMapGenStage(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        sq_pushinteger(vm, mapGen->getCurrentStage());

        return 1;
    }

    SQInteger GameCoreNamespace::getTotalMapGenStages(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        sq_pushinteger(vm, mapGen->getNumTotalStages());

        return 1;
    }

    SQInteger GameCoreNamespace::registerMapGenClient(HSQUIRRELVM vm){
        const SQChar *clientName;
        sq_getstring(vm, 2, &clientName);
        const SQChar *scriptPath;
        sq_getstring(vm, 3, &scriptPath);

        std::string outPath;
        AV::formatResToPath(scriptPath, outPath);

        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();
        ProceduralExplorationGameCore::CallbackScript* script = manager->loadScript(outPath);
        if(!script){
            std::string e = std::string("Error parsing script at path ") + outPath;
            return sq_throwerror(vm, e.c_str());
        }

        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "MapGen is active");
        }

        ProceduralExplorationGameCore::MapGenScriptClient* scriptClient = new ProceduralExplorationGameCore::MapGenScriptClient(script, clientName);

        mapGen->registerMapGenClient(clientName, scriptClient, vm);

        return 0;
    }

    SQInteger GameCoreNamespace::setHlmsFlagForDatablock(HSQUIRRELVM vm){
        Ogre::HlmsDatablock* db = 0;
        SCRIPT_CHECK_RESULT(AV::DatablockUserData::getPtrFromUserData(vm, 2, &db));
        Ogre::HlmsPbsDatablock* pbsDb = static_cast<Ogre::HlmsPbsDatablock*>(db);

        SQInteger f;
        sq_getinteger(vm, 3, &f);

        AV::uint32 flag = static_cast<AV::uint32>(f);

        Ogre::Vector4 vals = Ogre::Vector4::ZERO;
        AV::uint32 v = static_cast<AV::uint32>(f);
        vals.x = *reinterpret_cast<Ogre::Real*>(&v);

        pbsDb->setUserValue(0, vals);

        return 0;
    }

    SQInteger GameCoreNamespace::loadOverworld(HSQUIRRELVM vm){
        const SQChar *overworldName;
        sq_getstring(vm, 2, &overworldName);

        sq_newtable(vm);

        ProceduralExplorationGameCore::TileDataParser tileData("res://build/assets/overworld/");

        ProceduralExplorationGameCore::TileDataParser::OutDataContainer outBlend;
        bool result = tileData.readData(&outBlend, overworldName, "terrainBlend.txt");
        if(!result){
            return sq_throwerror(vm, "Error reading terrainBlend.txt");
        }

        ProceduralExplorationGameCore::TileDataParser::OutDataContainer outTiles;
        result = tileData.readData(&outTiles, overworldName, "terrain.txt");
        if(!result){
            return sq_throwerror(vm, "Error reading terrain.txt");
        }

        ProceduralExplorationGameCore::TileDataParser::OutDataContainer outRegions;
        result = tileData.readData(&outRegions, overworldName, "terrainRegion.txt");
        if(!result){
            return sq_throwerror(vm, "Error reading terrainRegion.txt");
        }

        if(outBlend.tilesWidth != outTiles.tilesWidth && outBlend.tilesWidth != outRegions.tilesWidth){
            return sq_throwerror(vm, "Tiles width do not match");
        }
        if(outBlend.tilesHeight != outTiles.tilesHeight && outBlend.tilesWidth != outRegions.tilesWidth){
            return sq_throwerror(vm, "Tiles height do not match");
        }

        ProceduralExplorationGameCore::ExplorationMapData* data = new ProceduralExplorationGameCore::ExplorationMapData();
        data->width = outTiles.tilesWidth;
        data->height = outTiles.tilesHeight;
        data->seaLevel = 100;
        const size_t BUFFER_SIZE = data->width * data->height * sizeof(AV::uint32);
        void* voxelBuffer = malloc(BUFFER_SIZE);
        void* secondaryVoxelBuffer = malloc(BUFFER_SIZE);
        void* tertiaryVoxelBuffer = malloc(BUFFER_SIZE);
        memset(tertiaryVoxelBuffer, 0, BUFFER_SIZE);
        AV::uint32* v = reinterpret_cast<AV::uint32*>(voxelBuffer);
        AV::uint32* s = reinterpret_cast<AV::uint32*>(secondaryVoxelBuffer);
        //memset(v, 0, data->width * data->height * sizeof(AV::uint32));
        //memset(s, 0, data->width * data->height * sizeof(AV::uint32));
        AV::uint32* vv = v;
        for(size_t i = 0; i < outTiles.tilesWidth * outTiles.tilesHeight; i++){
            *vv = static_cast<AV::uint32>(outTiles.tileValues[i]);
            vv++;
        }
        AV::uint32* ss = s;
        for(size_t i = 0; i < outBlend.tilesWidth * outBlend.tilesHeight; i++){
            *ss = 0;
            ss++;
        }
        //memcpy(&voxelBuffer, &(outTiles.tileValues[0]), outTiles.tilesWidth * outTiles.tilesHeight);
        data->voxelBuffer = voxelBuffer;
        data->secondaryVoxelBuffer = secondaryVoxelBuffer;
        data->tertiaryVoxelBuffer = tertiaryVoxelBuffer;

        /*
        for(int y = 10; y < data->height - 10; y++){
            for(int x = 10; x < data->width - 10; x++){
                ProceduralExplorationGameCore::WorldPoint p = ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y);
                *(VOX_PTR_FOR_COORD(data, p)) = 110 + (x % 10) * 10;
                *(VOX_VALUE_PTR_FOR_COORD(data, p)) = 0;
                //*(WATER_GROUP_PTR_FOR_COORD(data, p)) = 0;
                //*(LAND_GROUP_PTR_FOR_COORD(data, p)) = 0;
            }
        }
         */

        std::vector<ProceduralExplorationGameCore::FloodFillEntry*>* e = new std::vector<ProceduralExplorationGameCore::FloodFillEntry*>();
        data->voidPtr("waterData", e);
        e = new std::vector<ProceduralExplorationGameCore::FloodFillEntry*>();
        data->voidPtr("landData", e);
        std::vector<ProceduralExplorationGameCore::RegionData>* regionData = new std::vector<ProceduralExplorationGameCore::RegionData>();
        for(size_t i = 0; i < 0xFF; i++){
            regionData->push_back({static_cast<ProceduralExplorationGameCore::RegionId>(i)});
        }
        data->voidPtr("regionData", regionData);
        data->voidPtr("placedItems", new std::vector<ProceduralExplorationGameCore::PlacedItemData>());
        data->voidPtr("riverData", new std::vector<ProceduralExplorationGameCore::RiverData>());

        data->uint32("width", data->width);
        data->uint32("height", data->height);
        data->uint32("seaLevel", data->seaLevel);

        sq_pushstring(vm, "data", -1);

        for(ProceduralExplorationGameCore::WorldPoint y = 0; y < outBlend.tilesHeight; y++){
            for(ProceduralExplorationGameCore::WorldPoint x = 0; x < outBlend.tilesWidth; x++){
                AV::uint32* secondary = ProceduralExplorationGameCore::FULL_PTR_FOR_COORD_SECONDARY(data, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
                *secondary |= ProceduralExplorationGameCore::DRAW_COLOUR_VOXEL_FLAG;

                AV::uint8* voxPtr = ProceduralExplorationGameCore::VOX_VALUE_PTR_FOR_COORD(data, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
                *voxPtr = static_cast<AV::uint8>(outBlend.tileValues[x + y * outBlend.tilesWidth]);

                AV::uint8* regionPtr = ProceduralExplorationGameCore::REGION_PTR_FOR_COORD(data, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
                *regionPtr = static_cast<AV::uint8>(outRegions.tileValues[x + y * outRegions.tilesWidth]);
            }
        }

        //Generate water texture for overworld
        ProceduralExplorationGameCore::OverworldMapTextureGenerator textureGenerator;
        textureGenerator.generateTexture(data);

        //Create Ogre textures for the water texture buffers
        ProceduralExplorationGameCore::OgreResourceHelper textureHelper;
        float* waterTextureBuffer = data->ptr<float>("waterTextureBuffer");
        float* waterTextureBufferMask = data->ptr<float>("waterTextureBufferMask");

        textureHelper.createTextureFromBuffer("testTexture", data->width, data->height, waterTextureBuffer);
        textureHelper.createTextureFromBuffer("testTextureMask", data->width, data->height, waterTextureBufferMask);

        //Destroy the buffers as they're not needed anymore
        delete waterTextureBuffer;
        delete waterTextureBufferMask;

        ProceduralExplorationGameCore::ExplorationMapDataUserData::ExplorationMapDataToUserData<false>(vm, data);
        sq_newslot(vm, -3, SQFalse);

        return 1;
    }

    SQInteger GameCoreNamespace::checkClaimMapGen(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);

        if(mapGen->hasFailed()){
            return sq_throwerror(vm, "Map Gen failed!");
        }

        if(mapGen->isFinished()){
            //ProceduralExplorationGameCore::ExplorationMapData* mapData = mapGen->claimMapData(vm);
            //ExplorationMapDataUserData::ExplorationMapDataToUserData(vm, mapData);
            bool finished = mapGen->claimMapData(vm);
            assert(finished);
        }else{
            sq_pushnull(vm);
        }

        return 1;
    }

    SQInteger GameCoreNamespace::getNameForMapGenStage(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        assert(mapGen);

        SQInteger idx;
        sq_getinteger(vm, -1, &idx);
        const std::string& stageName = mapGen->getNameForStage(idx);
        sq_pushstring(vm, stageName.c_str(), -1);

        return 1;
    }

    SQInteger GameCoreNamespace::writeFlagsToItem(HSQUIRRELVM vm){
        Ogre::MovableObject* outObject = 0;
        SCRIPT_CHECK_RESULT(AV::MovableObjectUserData::readMovableObjectFromUserData(vm, 2, &outObject, AV::MovableObjectType::Item));

        SQInteger flags = 0;
        sq_getinteger(vm, 3, &flags);

        Ogre::Item* item = dynamic_cast<Ogre::Item*>(outObject);
        assert(item);
        Ogre::Vector4 vals = Ogre::Vector4::ZERO;
        vals.x = *reinterpret_cast<Ogre::Real*>(&flags);
        for(Ogre::Renderable* r : item->mRenderables){
            r->setCustomParameter(0, vals);
            const Ogre::Vector4 currentParam = r->getCustomParameter(0);
            assert(currentParam == vals);
        }

        return 0;
    }

    SQInteger GameCoreNamespace::setupCollisionDataForWorld(HSQUIRRELVM vm){
        AV::CollisionWorldObject* world;
        AV::CollisionWorldClass::readCollisionWorldFromUserData(vm, 2, &world);

        SQInteger width, height;
        sq_getinteger(vm, 4, &width);
        sq_getinteger(vm, 5, &height);

        SQInteger scaleResolution = 1;
        if(sq_gettop(vm) >= 6){
            sq_getinteger(vm, 6, &scaleResolution);
            sq_pop(vm, 1);
        }

        //Get the array at the top.
        sq_pop(vm, 2);

        ProceduralExplorationGameCore::CollisionDetectionWorld* collision = dynamic_cast<ProceduralExplorationGameCore::CollisionDetectionWorld*>(world);
        assert(collision);

        std::vector<bool> data;
        SQInteger arraySize = sq_getsize(vm, -1);
        data.resize(arraySize);

        for(SQInteger i = 0; i < arraySize; i++){
            sq_pushinteger(vm, i);
            sq_get(vm, -2);

            SQObjectType t = sq_gettype(vm, -1);
            assert(t == OT_BOOL || t == OT_INTEGER);

            data[i] = (t == OT_BOOL);

            sq_pop(vm, 1);
        }

        collision->setCollisionGrid(data, width, height, static_cast<int>(scaleResolution));

        return 0;
    }

    SQInteger GameCoreNamespace::createCollisionDetectionWorld(HSQUIRRELVM vm){
        SQInteger id, width, height;
        sq_getinteger(vm, 2, &id);

        ProceduralExplorationGameCore::CollisionDetectionWorld* world = new ProceduralExplorationGameCore::CollisionDetectionWorld(id);

        AV::CollisionWorldClass::collisionWorldToUserData(vm, world);

        return 1;
    }

    SQInteger GameCoreNamespace::disableShadows(HSQUIRRELVM vm){
        Ogre::CompositorManager2 *compositorManager = Ogre::Root::getSingleton().getCompositorManager2();
        Ogre::CompositorNodeDef* nodeDef = compositorManager->getNodeDefinitionNonConst("renderMainGameplayNode");
        for(int i = 0; i < nodeDef->getNumTargetPasses(); i++){
            Ogre::CompositorTargetDef* def = nodeDef->getTargetPass(i);
            for(Ogre::CompositorPassDef* p : def->getCompositorPassesNonConst()){
                if(p->getType() != Ogre::CompositorPassType::PASS_SCENE) continue;

                Ogre::CompositorPassSceneDef* sceneDef = dynamic_cast<Ogre::CompositorPassSceneDef*>(p);
                sceneDef->mShadowNode = Ogre::IdString();
            }
        }

        return 0;
    }

    SQInteger GameCoreNamespace::setCameraForNode(HSQUIRRELVM vm){
        const SQChar *nodeName, *cameraName;
        sq_getstring(vm, 2, &nodeName);
        sq_getstring(vm, 3, &cameraName);

        Ogre::CompositorManager2 *compositorManager = Ogre::Root::getSingleton().getCompositorManager2();
        Ogre::CompositorNodeDef* nodeDef = compositorManager->getNodeDefinitionNonConst(nodeName);
        for(int i = 0; i < nodeDef->getNumTargetPasses(); i++){
            Ogre::CompositorTargetDef* def = nodeDef->getTargetPass(i);
            for(Ogre::CompositorPassDef* p : def->getCompositorPassesNonConst()){
                if(p->getType() != Ogre::CompositorPassType::PASS_SCENE) continue;

                Ogre::CompositorPassSceneDef* sceneDef = dynamic_cast<Ogre::CompositorPassSceneDef*>(p);
                sceneDef->mCameraName = Ogre::IdString(cameraName);
            }
        }

        return 0;
    }

    SQInteger GameCoreNamespace::setupCompositorDefs(HSQUIRRELVM vm){
        SQInteger width, height;
        sq_getinteger(vm, 2, &width);
        sq_getinteger(vm, 3, &height);

        Ogre::CompositorManager2 *compositorManager = Ogre::Root::getSingleton().getCompositorManager2();
        Ogre::CompositorNodeDef* nodeDef = compositorManager->getNodeDefinitionNonConst("renderMainGameplayNode");
        for(Ogre::TextureDefinitionBase::TextureDefinition& t : nodeDef->getLocalTextureDefinitionsNonConst()){
            int divVal = 1;
            if(t.getName() == "windTexture"){
                divVal = 2;
            }
            t.width = static_cast<Ogre::uint32>(width / divVal);
            t.height = static_cast<Ogre::uint32>(height / divVal);
        }

        return 0;
    }

    SQInteger GameCoreNamespace::createVoxMeshItem(HSQUIRRELVM vm){
        SQInteger size = sq_gettop(vm);
        Ogre::SceneMemoryMgrTypes targetType = Ogre::SCENE_DYNAMIC;
        Ogre::uint32 meshFlags = 0;
        bool meshFlagsWritten = false;
        if(size >= 3){
            SQInteger flags = 0;
            sq_getinteger(vm, 3, &flags);
            meshFlags = static_cast<Ogre::uint32>(flags);
            meshFlagsWritten = true;
        }
        if(size >= 4){
            SQInteger sceneNodeType = 0;
            sq_getinteger(vm, 4, &sceneNodeType);
            targetType = static_cast<Ogre::SceneMemoryMgrTypes>(sceneNodeType);
        }

        Ogre::Item* item = 0;
        if(sq_gettype(vm, 2) == OT_STRING){
            const SQChar *meshPath;
            sq_getstring(vm, 2, &meshPath);
            Ogre::NameValuePairList params;
            params["mesh"] = meshPath;
            params["resourceGroup"] = Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME;
            if(meshFlagsWritten){
                params["flags"] = Ogre::StringConverter::toString(meshFlags);
            }
            Ogre::MovableObject *obj;
            Ogre::SceneManager* sceneManager = AV::BaseSingleton::getSceneManager();

            WRAP_OGRE_ERROR(
                obj = sceneManager->createMovableObject(Ogre::VoxMeshItemFactory::FACTORY_TYPE_NAME, &(sceneManager->_getEntityMemoryManager(targetType)), &params);
            )
            Ogre::VoxMeshItem* outVoxMesh = dynamic_cast<Ogre::VoxMeshItem*>(obj);
            item = dynamic_cast<Ogre::Item*>(outVoxMesh);
        }else{
            assert(false);
        }
        item->setListener(AV::SceneNamespace::getMovableObjectListener(AV::MovableObjectType::Item));

        AV::MovableObjectUserData::movableObjectToUserData(vm, (Ogre::MovableObject*)item, AV::MovableObjectType::Item);

        return 1;
    }

    SQInteger GameCoreNamespace::voxeliseMeshForVoxelData(HSQUIRRELVM vm){
        const SQChar *meshName;
        sq_getstring(vm, 2, &meshName);

        SQInteger arraySize = sq_getsize(vm, 3);
        ProceduralExplorationGameCore::VoxelId* values = static_cast<ProceduralExplorationGameCore::VoxelId*>(malloc(sizeof(ProceduralExplorationGameCore::VoxelId) * arraySize));

        ProceduralExplorationGameCore::VoxelId* voxPtr = values;
        for(SQInteger i = 0; i < arraySize; i++){
            sq_pushinteger(vm, i);
            sq_get(vm, 3);

            ProceduralExplorationGameCore::VoxelId targetVox = ProceduralExplorationGameCore::EMPTY_VOXEL;

            SQObjectType foundType = sq_gettype(vm, -1);
            if(foundType == OT_NULL){
                //Stub
            }
            else if(foundType == OT_INTEGER){
                SQInteger voxVal;
                sq_getinteger(vm, -1, &voxVal);
                targetVox = static_cast<ProceduralExplorationGameCore::VoxelId>(voxVal);
            }else{
                return sq_throwerror(vm, "Voxel values must contain either null or an integer.");
            }

            *voxPtr = targetVox;
            voxPtr++;

            sq_pop(vm, 1);
        }

        SQInteger width, height, depth;
        sq_getinteger(vm, 4, &width);
        sq_getinteger(vm, 5, &height);
        sq_getinteger(vm, 6, &depth);

        ProceduralExplorationGameCore::Voxeliser vox;
        Ogre::MeshPtr outMesh;
        vox.createMeshForVoxelData(meshName, values, width, height, depth, &outMesh);

        AV::MeshUserData::MeshToUserData(vm, outMesh);

        return 1;
    }

    SQInteger GameCoreNamespace::createDataPointFileParser(HSQUIRRELVM vm){
        DataPointFileParserUserData::WrappedDataPointFile* dataFile = new DataPointFileParserUserData::WrappedDataPointFile();

        DataPointFileParserUserData::dataPointFileHandlerToUserData(vm, dataFile);

        return 1;
    }

    SQInteger GameCoreNamespace::insertParsedSceneFileVoxMeshGetAnimInfo(HSQUIRRELVM vm){
        AV::ParsedSceneFile* file = 0;
        AV::ParsedAvSceneUserData::readSceneObjectFromUserData(vm, 2, &file);

        AV::CollisionWorldObject* collisionWorld;
        SCRIPT_CHECK_RESULT(AV::CollisionWorldClass::readCollisionWorldFromUserData(vm, 4, &collisionWorld));
        ProceduralExplorationGameCore::CollisionDetectionWorld* detectionWorld = dynamic_cast<ProceduralExplorationGameCore::CollisionDetectionWorld*>(collisionWorld);

        Ogre::SceneNode* node = 0;
        SQInteger top = sq_gettop(vm);
        Ogre::SceneManager* sceneManager = AV::BaseSingleton::getSceneManager();
        SCRIPT_CHECK_RESULT(AV::SceneNodeUserData::readSceneNodeFromUserData(vm, 3, &node));

        Ogre::Vector3 offset = Ogre::Vector3::ZERO;
        if(sq_gettop(vm) >= 5){
            SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, 5, &offset));
        }

        ProceduralExplorationGameCore::VoxMeshSceneDataInserter inserter(sceneManager, detectionWorld, offset);
        AV::AnimationInfoBlockPtr animData = inserter.insertSceneDataGetAnimInfo(file, node);
        if(!animData){
            sq_pushnull(vm);
            return 1;
        }
        AV::AnimationInfoUserData::blockPtrToUserData(vm, animData);

        return 1;
    }

    SQInteger GameCoreNamespace::insertParsedSceneFileVoxMeshGetAnimInfoOverworld(HSQUIRRELVM vm){
        AV::ParsedSceneFile* file = 0;
        AV::ParsedAvSceneUserData::readSceneObjectFromUserData(vm, 2, &file);

        Ogre::SceneNode* node = 0;
        SQInteger top = sq_gettop(vm);
        Ogre::SceneManager* sceneManager = AV::BaseSingleton::getSceneManager();
        SCRIPT_CHECK_RESULT(AV::SceneNodeUserData::readSceneNodeFromUserData(vm, 3, &node));

        //TODO remove the offset obtain
        Ogre::Vector3 offset = Ogre::Vector3::ZERO;
        if(sq_gettop(vm) >= 5){
            SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, 5, &offset));
        }

        ProceduralExplorationGameCore::OverworldVoxMeshSceneDataInserter inserter(sceneManager);
        AV::AnimationInfoBlockPtr animData = inserter.insertSceneDataGetAnimInfo(file, node);

        const std::map<int,Ogre::SceneNode*>& values = inserter.getRegionNodes();
        sq_newtable(vm);
        for(const std::pair<int,Ogre::SceneNode*>& v : values){
            const std::string s = std::to_string(v.first);
            sq_pushstring(vm, s.c_str(), -1);
            AV::SceneNodeUserData::sceneNodeToUserData(vm, v.second);
            sq_rawset(vm, -3);
        }

        /*
        if(!animData){
            sq_pushnull(vm);
            return 1;
        }
        AV::AnimationInfoUserData::blockPtrToUserData(vm, animData);
         */

        return 1;
    }

    SQInteger GameCoreNamespace::deepCopyToMapGenVM(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();
        ProceduralExplorationGameCore::MapGenScriptVM* scriptVM = manager->getScriptVM();
        HSQUIRRELVM squirrelVM = scriptVM->getVM();

        const SQChar *key;
        sq_getstring(vm, -2, &key);

        sq_pushroottable(squirrelVM);
        sq_pushstring(squirrelVM, key, -1);

        AV::SquirrelDeepCopy copy;
        copy.deepCopyValue(vm, squirrelVM, -1);

        sq_newslot(squirrelVM, -3, false);

        sq_pop(squirrelVM, 1);

        return 0;
    }

    SQInteger GameCoreNamespace::dumpSceneToObj(HSQUIRRELVM vm){
        std::string outPath;
        AV::formatResToPath("user://dumpedScene.obj", outPath);

        ProceduralExplorationGameCore::VoxSceneDumper dumper;
        auto it = Ogre::Root::getSingleton().getSceneManagerIterator();
        dumper.dumpToObjFile(outPath, it.getNext()->getRootSceneNode());

        sq_pushstring(vm, outPath.c_str(), -1);
        return 1;
    }

    SQInteger GameCoreNamespace::update(HSQUIRRELVM vm){
        //TODO make this accurate to delta times.
        GameCorePBSHlmsListener::mTimeValue += 0.03;

        Ogre::Vector3 offset = Ogre::Vector3::ZERO;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, 2, &offset));
        GameCorePBSHlmsListener::mPlayerPosition = offset;

        return 0;
    }

    SQInteger GameCoreNamespace::initialiseHapticFeedbackSystem(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::initialiseHapticFeedbackSystem();
        return 0;
    }

    SQInteger GameCoreNamespace::triggerLightHapticFeedback(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::triggerLightHapticFeedback();
        return 0;
    }

    SQInteger GameCoreNamespace::triggerMediumHapticFeedback(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::triggerMediumHapticFeedback();
        return 0;
    }

    SQInteger GameCoreNamespace::triggerHeavyHapticFeedback(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::triggerHeavyHapticFeedback();
        return 0;
    }

    SQInteger GameCoreNamespace::triggerSelectionHapticFeedback(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::triggerSelectionHapticFeedback();
        return 0;
    }

    SQInteger GameCoreNamespace::triggerNotificationHapticFeedback(HSQUIRRELVM vm){
        SQInteger notificationType = 0;
        if(sq_gettype(vm, 2) == OT_INTEGER){
            sq_getinteger(vm, 2, &notificationType);
        }
        ProceduralExplorationGameCore::triggerNotificationHapticFeedback((int)notificationType);
        return 0;
    }

    SQInteger GameCoreNamespace::setupParticleEmitterPoints(HSQUIRRELVM vm){
        Ogre::MovableObject* outObject = 0;
        SCRIPT_ASSERT_RESULT(AV::MovableObjectUserData::readMovableObjectFromUserData(vm, 2, &outObject, AV::MovableObjectType::ParticleSystem));
        Ogre::ParticleSystem* particleSystem = dynamic_cast<Ogre::ParticleSystem*>(outObject);
        assert(particleSystem);

        //Get emitter
        Ogre::ParticleEmitter* emitter = particleSystem->getEmitter(0);
        if(!emitter){
            sq_throwerror(vm, "Particle system has no emitter at index 0");
            return SQ_ERROR;
        }

        //Cast to our custom emitter type
        Ogre::AreaProceduralWorldEmitter* areaEmitter = dynamic_cast<Ogre::AreaProceduralWorldEmitter*>(emitter);
        if(!areaEmitter){
            sq_throwerror(vm, "Emitter is not an AreaProceduralWorldEmitter");
            return SQ_ERROR;
        }

        //Get array of world points
        if(sq_gettype(vm, 3) != OT_ARRAY){
            sq_throwerror(vm, "Third parameter must be an array of world points");
            return SQ_ERROR;
        }

        std::vector<uint32_t> points;
        SQInteger arraySize = sq_getsize(vm, 3);
        for(SQInteger i = 0; i < arraySize; i++){
            sq_pushinteger(vm, i);
            sq_get(vm, 3);
            SQInteger worldPoint = 0;
            sq_getinteger(vm, -1, &worldPoint);
            points.push_back(static_cast<uint32_t>(worldPoint));
            sq_pop(vm, 1);
        }

        //Set the points on the emitter
        areaEmitter->setEmissionPoints(points);

        return 0;
    }

    void GameCoreNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, getGameCoreVersion, "getGameCoreVersion");

        AV::ScriptUtils::addFunction(vm, fillBufferWithMapLean, "fillBufferWithMapLean", 3, ".uu");
        AV::ScriptUtils::addFunction(vm, fillBufferWithMapComplex, "fillBufferWithMapComplex", 4, ".uui");
        AV::ScriptUtils::addFunction(vm, getRegionFound, "getRegionFound", 2, ".i");
        AV::ScriptUtils::addFunction(vm, setRegionFound, "setRegionFound", 3, ".ib");
        AV::ScriptUtils::addFunction(vm, setNewMapData, "setNewMapData", 2, ".u");
        AV::ScriptUtils::addFunction(vm, createTerrainFromMapData, "createTerrainFromMapData", 3, ".su");
        AV::ScriptUtils::addFunction(vm, getNameForMapGenStage, "getNameForMapGenStage", 2, ".i");
        AV::ScriptUtils::addFunction(vm, writeFlagsToItem, "writeFlagsToItem", 3, ".ui");

        AV::ScriptUtils::addFunction(vm, createCollisionDetectionWorld, "createCollisionDetectionWorld", 2, ".i");
        AV::ScriptUtils::addFunction(vm, setupCollisionDataForWorld, "setupCollisionDataForWorld", -5, ".uaiii");

        AV::ScriptUtils::addFunction(vm, beginMapGen, "beginMapGen", 2, ".t");
        AV::ScriptUtils::addFunction(vm, getMapGenStage, "getMapGenStage");
        AV::ScriptUtils::addFunction(vm, checkClaimMapGen, "checkClaimMapGen");
        AV::ScriptUtils::addFunction(vm, getTotalMapGenStages, "getTotalMapGenStages");
        AV::ScriptUtils::addFunction(vm, setHlmsFlagForDatablock, "setHlmsFlagForDatablock", 3, ".ui");
        AV::ScriptUtils::addFunction(vm, registerMapGenClient, "registerMapGenClient", 4, ".sst|o");
        AV::ScriptUtils::addFunction(vm, recollectMapGenSteps, "recollectMapGenSteps");
        AV::ScriptUtils::addFunction(vm, setCustomPassBufferValue, "setCustomPassBufferValue", -2, ".n|unn");
        AV::ScriptUtils::addFunction(vm, setPassBufferFogValue, "setPassBufferFogValue", -2, ".n|unn");
        AV::ScriptUtils::addFunction(vm, setPassBufferFogStartEnd, "setPassBufferFogStartEnd", -2, ".n|un");
        AV::ScriptUtils::addFunction(vm, setCameraForNode, "setCameraForNode", 3, ".ss");
        AV::ScriptUtils::addFunction(vm, loadOverworld, "loadOverworld", 2, ".s");

        AV::ScriptUtils::addFunction(vm, disableShadows, "disableShadows");
        AV::ScriptUtils::addFunction(vm, setupCompositorDefs, "setupCompositorDefs", 3, ".ii");

        AV::ScriptUtils::addFunction(vm, registerVoxel, "registerVoxel", 4, ".nnu");

        AV::ScriptUtils::addFunction(vm, destroyMapData, "destroyMapData", 2, ".u");

        AV::ScriptUtils::addFunction(vm, deepCopyToMapGenVM, "deepCopyToMapGenVM", 3, ".s.");

        AV::ScriptUtils::addFunction(vm, update, "update", 2, ".u");

        AV::ScriptUtils::addFunction(vm, createVoxMeshItem, "createVoxMeshItem", -2, ".sii");

        AV::ScriptUtils::addFunction(vm, beginParseVisitedLocation, "beginParseVisitedLocation");
        AV::ScriptUtils::addFunction(vm, checkClaimParsedVisitedLocation, "checkClaimParsedVisitedLocation");
        AV::ScriptUtils::addFunction(vm, setMapsDirectory, "setMapsDirectory", 2, ".s");

        AV::ScriptUtils::addFunction(vm, voxeliseMeshForVoxelData, "voxeliseMeshForVoxelData", 6, ".saiii");
        AV::ScriptUtils::addFunction(vm, insertParsedSceneFileVoxMeshGetAnimInfo, "insertParsedSceneFileGetAnimInfo", -4, ".uuuu");
        AV::ScriptUtils::addFunction(vm, insertParsedSceneFileVoxMeshGetAnimInfoOverworld, "insertParsedSceneFileGetAnimInfoOverworld", -3, ".uuu");

        AV::ScriptUtils::addFunction(vm, dumpSceneToObj, "dumpSceneToObj");

        AV::ScriptUtils::addFunction(vm, initialiseHapticFeedbackSystem, "initialiseHapticFeedbackSystem");
        AV::ScriptUtils::addFunction(vm, triggerLightHapticFeedback, "triggerLightHapticFeedback");
        AV::ScriptUtils::addFunction(vm, triggerMediumHapticFeedback, "triggerMediumHapticFeedback");
        AV::ScriptUtils::addFunction(vm, triggerHeavyHapticFeedback, "triggerHeavyHapticFeedback");
        AV::ScriptUtils::addFunction(vm, triggerSelectionHapticFeedback, "triggerSelectionHapticFeedback");
        AV::ScriptUtils::addFunction(vm, triggerNotificationHapticFeedback, "triggerNotificationHapticFeedback", -1, ".");

        AV::ScriptUtils::addFunction(vm, setupParticleEmitterPoints, "setupParticleEmitterPoints", 3, ".ua");

        AV::ScriptUtils::addFunction(vm, createDataPointFileParser, "DataPointFile");
    }

};
