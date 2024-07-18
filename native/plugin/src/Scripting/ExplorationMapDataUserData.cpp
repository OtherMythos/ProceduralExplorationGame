#include "ExplorationMapDataUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"

#include <sqstdblob.h>
#include <vector>

#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGamePlugin{

    SQObject ExplorationMapDataUserData::ExplorationMapDataDelegateTableObject;

    void ExplorationMapDataUserData::ExplorationMapDataToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapData* data){
        ProceduralExplorationGameCore::ExplorationMapData** pointer = (ProceduralExplorationGameCore::ExplorationMapData**)sq_newuserdata(vm, sizeof(ProceduralExplorationGameCore::ExplorationMapData*));
        *pointer = data;

        sq_pushobject(vm, ExplorationMapDataDelegateTableObject);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, ExplorationMapDataTypeTag);
        sq_setreleasehook(vm, -1, ExplorationMapDataObjectReleaseHook);
    }

    AV::UserDataGetResult ExplorationMapDataUserData::readExplorationMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::ExplorationMapData** outData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != ExplorationMapDataTypeTag){
            *outData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        ProceduralExplorationGameCore::ExplorationMapData** p = (ProceduralExplorationGameCore::ExplorationMapData**)pointer;
        *outData = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger ExplorationMapDataUserData::ExplorationMapDataObjectReleaseHook(SQUserPointer p, SQInteger size){
        ProceduralExplorationGameCore::ExplorationMapData** ptr = static_cast<ProceduralExplorationGameCore::ExplorationMapData**>(p);
        delete *ptr;

        return 0;
    }

    inline void pushInteger(HSQUIRRELVM vm, const char* key, SQInteger value){
        sq_pushstring(vm, key, -1);
        sq_pushinteger(vm, value);
        sq_rawset(vm, -3);
    }
    inline void pushBool(HSQUIRRELVM vm, const char* key, SQInteger value){
        sq_pushstring(vm, key, -1);
        sq_pushinteger(vm, value);
        sq_rawset(vm, -3);
    }
    inline void pushEmptyArray(HSQUIRRELVM vm, const char* key){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, 0);
        sq_rawset(vm, -3);
    }
    template<typename T>
    inline void pushArray(HSQUIRRELVM vm, const char* key, const std::vector<T>& vec){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, vec.size());
        for(size_t i = 0; i < vec.size(); i++){
            sq_pushinteger(vm, i);
            sq_pushinteger(vm, vec[i]);
            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void pushFloodData(HSQUIRRELVM vm, const char* key, std::vector<ProceduralExplorationGameCore::FloodFillEntry*>& waterData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, waterData.size());
        for(size_t i = 0; i < waterData.size(); i++){
            sq_pushinteger(vm, i);

            const ProceduralExplorationGameCore::FloodFillEntry& e = *waterData[i];
            sq_newtable(vm);

            pushInteger(vm, "id", e.id);
            pushInteger(vm, "total", e.total);
            pushInteger(vm, "seedX", e.seedX);
            pushInteger(vm, "seedY", e.seedY);
            pushBool(vm, "nextToWorldEdge", e.nextToWorldEdge);
            pushArray<ProceduralExplorationGameCore::WorldPoint>(vm, "coords", e.coords);
            pushArray<ProceduralExplorationGameCore::WorldPoint>(vm, "edges", e.edges);

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void pushRegionData(HSQUIRRELVM vm, const char* key, std::vector<ProceduralExplorationGameCore::RegionData>& regionData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, regionData.size());
        for(size_t i = 0; i < regionData.size(); i++){
            sq_pushinteger(vm, i);

            const ProceduralExplorationGameCore::RegionData& e = regionData[i];
            sq_newtable(vm);

            pushInteger(vm, "id", e.id);
            pushInteger(vm, "total", e.total);
            pushInteger(vm, "seedX", e.seedX);
            pushInteger(vm, "seedY", e.seedY);
            pushInteger(vm, "type", static_cast<SQInteger>(e.type));
            pushArray<ProceduralExplorationGameCore::WorldPoint>(vm, "coords", e.coords);
            //pushArray<ProceduralExplorationGameCore::WorldPoint>(vm, "edges", e.edges);

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void pushPlaceData(HSQUIRRELVM vm, const char* key, std::vector<ProceduralExplorationGameCore::PlaceData>& placeData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, placeData.size());
        for(size_t i = 0; i < placeData.size(); i++){
            sq_pushinteger(vm, i);

            const ProceduralExplorationGameCore::PlaceData& e = placeData[i];
            sq_newtable(vm);

            pushInteger(vm, "placeId", static_cast<SQInteger>(e.type));
            pushInteger(vm, "region", e.region);
            pushInteger(vm, "originX", e.originX);
            pushInteger(vm, "originY", e.originY);

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void pushPlacedItemData(HSQUIRRELVM vm, const char* key, std::vector<ProceduralExplorationGameCore::PlacedItemData>& itemData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, itemData.size());
        for(size_t i = 0; i < itemData.size(); i++){
            sq_pushinteger(vm, i);

            const ProceduralExplorationGameCore::PlacedItemData& e = itemData[i];
            sq_newtable(vm);

            pushInteger(vm, "type", static_cast<SQInteger>(e.type));
            pushInteger(vm, "originX", e.originX);
            pushInteger(vm, "originY", e.originY);
            pushInteger(vm, "region", static_cast<SQInteger>(e.region));

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void pushBuffer(HSQUIRRELVM vm, const char* key, void* buf, size_t size){
        sq_pushstring(vm, key, -1);
        //Annoyingly I have to create a new blob and copy the buffer over to that.
        //Luckily though that keeps the buffer const.
        SQUserPointer ptr = sqstd_createblob(vm, size*sizeof(float));
        memcpy(static_cast<float*>(ptr), static_cast<float*>(buf), size);
        sq_rawset(vm, 2);
    }
    SQInteger ExplorationMapDataUserData::explorationMapDataToTable(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        sq_newtable(vm);

        pushInteger(vm, "seed", mapData->seed);
        pushInteger(vm, "moistureSeed", mapData->moistureSeed);
        pushInteger(vm, "variationSeed", mapData->variationSeed);
        pushInteger(vm, "width", mapData->width);
        pushInteger(vm, "height", mapData->height);
        pushInteger(vm, "seaLevel", mapData->seaLevel);
        pushInteger(vm, "playerStart", mapData->playerStart);
        pushInteger(vm, "gatewayPosition", mapData->gatewayPosition);

        pushFloodData(vm, "waterData", mapData->waterData);
        pushFloodData(vm, "landData", mapData->landData);
        pushPlaceData(vm, "placeData", mapData->placeData);
        pushRegionData(vm, "regionData", mapData->regionData);
        pushPlacedItemData(vm, "placedItems", mapData->placedItems);

        pushBuffer(vm, "voxelBuffer", mapData->voxelBuffer, mapData->voxelBufferSize);
        pushBuffer(vm, "secondaryVoxBuffer", mapData->secondaryVoxelBuffer, mapData->secondaryVoxelBufferSize);
        pushBuffer(vm, "blueNoiseBuffer", mapData->blueNoiseBuffer, mapData->blueNoiseBufferSize);

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getAltitudeForPos(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, 0);
            return 1;
        }

        ProceduralExplorationGameCore::WorldCoord x, y;
        x = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.x);
        y = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.z);

        const AV::uint8* voxPtr = ProceduralExplorationGameCore::VOX_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));

        sq_pushinteger(vm, static_cast<SQInteger>(*voxPtr));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getLandmassForPos(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        ProceduralExplorationGameCore::LandId outLandmass = ProceduralExplorationGameCore::INVALID_LAND_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, static_cast<SQInteger>(outLandmass));
            return 1;
        }

        ProceduralExplorationGameCore::WorldCoord x, y;
        x = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.x);
        y = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.z);

        const AV::uint8* landPtr = ProceduralExplorationGameCore::LAND_GROUP_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
        outLandmass = *landPtr;

        sq_pushinteger(vm, static_cast<SQInteger>(outLandmass));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getIsWaterForPos(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        ProceduralExplorationGameCore::WaterId outWater = ProceduralExplorationGameCore::INVALID_WATER_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushbool(vm, false);
            return 1;
        }

        ProceduralExplorationGameCore::WorldCoord x, y;
        x = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.x);
        y = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.z);

        const AV::uint8* waterPtr = ProceduralExplorationGameCore::WATER_GROUP_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
        if(*waterPtr == ProceduralExplorationGameCore::INVALID_WATER_ID){
            sq_pushbool(vm, false);
            return 1;
        }

        sq_pushbool(vm, true);

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionForPos(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        ProceduralExplorationGameCore::RegionId outRegion = ProceduralExplorationGameCore::INVALID_REGION_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, static_cast<SQInteger>(outRegion));
            return 1;
        }

        ProceduralExplorationGameCore::WorldCoord x, y;
        x = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.x);
        y = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.z);

        const AV::uint8* regionPtr = ProceduralExplorationGameCore::REGION_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
        outRegion = *regionPtr;

        sq_pushinteger(vm, static_cast<SQInteger>(outRegion));

        return 1;
    }

    void ExplorationMapDataUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, explorationMapDataToTable, "explorationMapDataToTable");
        AV::ScriptUtils::addFunction(vm, getAltitudeForPos, "getAltitudeForPos");
        AV::ScriptUtils::addFunction(vm, getLandmassForPos, "getLandmassForPos");
        AV::ScriptUtils::addFunction(vm, getIsWaterForPos, "getIsWaterForPos");
        AV::ScriptUtils::addFunction(vm, getRegionForPos, "getRegionForPos");

        sq_resetobject(&ExplorationMapDataDelegateTableObject);
        sq_getstackobj(vm, -1, &ExplorationMapDataDelegateTableObject);
        sq_addref(vm, &ExplorationMapDataDelegateTableObject);
        sq_pop(vm, 1);
    }
}
