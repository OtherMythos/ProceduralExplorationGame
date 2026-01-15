#include "ExplorationMapDataUserData.h"

#include "ProceduralExplorationGameCoreScriptTypeTags.h"

//TODO think about making this generic.
#include "VisitedPlaces/TileDataParser.h"

#include <sqstdblob.h>
#include <vector>

#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    SQObject ExplorationMapDataUserData::ExplorationMapDataDelegateTableObject;
    SQObject ExplorationMapDataUserData::ExplorationMapDataDelegateTableObjectMapGenVM;

    template void ExplorationMapDataUserData::ExplorationMapDataToUserData<true>(HSQUIRRELVM vm, ExplorationMapData* data);
    template void ExplorationMapDataUserData::ExplorationMapDataToUserData<false>(HSQUIRRELVM vm, ExplorationMapData* data);
    template void ExplorationMapDataUserData::setupDelegateTable<true>(HSQUIRRELVM vm);
    template void ExplorationMapDataUserData::setupDelegateTable<false>(HSQUIRRELVM vm);

    template <bool B>
    void ExplorationMapDataUserData::ExplorationMapDataToUserData(HSQUIRRELVM vm, ExplorationMapData* data){
        ExplorationMapData** pointer = (ExplorationMapData**)sq_newuserdata(vm, sizeof(ExplorationMapData*));
        *pointer = data;

        SQObject* tableObj = 0;
        if(B){
            tableObj = &ExplorationMapDataDelegateTableObjectMapGenVM;
        }else{
            tableObj = &ExplorationMapDataDelegateTableObject;
        }

        sq_pushobject(vm, *tableObj);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, ExplorationMapDataTypeTag);
        //sq_setreleasehook(vm, -1, ExplorationMapDataObjectReleaseHook);
    }

    AV::UserDataGetResult ExplorationMapDataUserData::readExplorationMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ExplorationMapData** outData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != ExplorationMapDataTypeTag){
            *outData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        ExplorationMapData** p = (ExplorationMapData**)pointer;
        *outData = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger ExplorationMapDataUserData::ExplorationMapDataObjectReleaseHook(SQUserPointer p, SQInteger size){
        ExplorationMapData** ptr = static_cast<ExplorationMapData**>(p);
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
    inline void pushFloat(HSQUIRRELVM vm, const char* key, float value){
        sq_pushstring(vm, key, -1);
        sq_pushfloat(vm, value);
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
    inline void pushFloodData(HSQUIRRELVM vm, const char* key, std::vector<FloodFillEntry*>& waterData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, waterData.size());
        for(size_t i = 0; i < waterData.size(); i++){
            sq_pushinteger(vm, i);

            const FloodFillEntry& e = *waterData[i];
            sq_newtable(vm);

            pushInteger(vm, "id", e.id);
            pushInteger(vm, "total", e.total);
            pushInteger(vm, "seedX", e.seedX);
            pushInteger(vm, "seedY", e.seedY);
            pushBool(vm, "nextToWorldEdge", e.nextToWorldEdge);
            pushArray<WorldPoint>(vm, "coords", e.coords);
            pushArray<WorldPoint>(vm, "edges", e.edges);

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void pushRegionData(HSQUIRRELVM vm, const char* key, std::vector<RegionData>& regionData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, regionData.size());
        for(size_t i = 0; i < regionData.size(); i++){
            sq_pushinteger(vm, i);

            const RegionData& e = regionData[i];
            sq_newtable(vm);

            pushInteger(vm, "id", e.id);
            pushInteger(vm, "total", e.total);
            pushInteger(vm, "seedX", e.seedX);
            pushInteger(vm, "seedY", e.seedY);
            pushInteger(vm, "type", static_cast<SQInteger>(e.type));
            pushInteger(vm, "deepestPoint", static_cast<SQInteger>(e.deepestPoint));
            pushInteger(vm, "deepestDistance", static_cast<SQInteger>(e.deepestDistance));
            pushInteger(vm, "centrePoint", static_cast<SQInteger>(e.centrePoint));
            pushFloat(vm, "radius", e.radius);
            pushArray<WorldPoint>(vm, "coords", e.coords);
            //pushArray<WorldPoint>(vm, "edges", e.edges);

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
/*
    inline void pushPlaceData(HSQUIRRELVM vm, const char* key, std::vector<PlaceData>& placeData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, placeData.size());
        for(size_t i = 0; i < placeData.size(); i++){
            sq_pushinteger(vm, i);

            const PlaceData& e = placeData[i];
            sq_newtable(vm);

            pushInteger(vm, "placeId", static_cast<SQInteger>(e.type));
            pushInteger(vm, "region", e.region);
            pushInteger(vm, "originX", e.originX);
            pushInteger(vm, "originY", e.originY);

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
 */
    inline void pushPlacedItemData(HSQUIRRELVM vm, const char* key, std::vector<PlacedItemData>& itemData){
        sq_pushstring(vm, key, -1);
        sq_newarray(vm, itemData.size());
        for(size_t i = 0; i < itemData.size(); i++){
            sq_pushinteger(vm, i);

            const PlacedItemData& e = itemData[i];
            sq_newtable(vm);

            pushInteger(vm, "type", static_cast<SQInteger>(e.type));
            pushInteger(vm, "originX", e.originX);
            pushInteger(vm, "originY", e.originY);
            pushInteger(vm, "region", static_cast<SQInteger>(e.region));

            sq_rawset(vm, -3);
        }
        sq_rawset(vm, -3);
    }
    inline void generatePushedItemBuffer(HSQUIRRELVM vm, const char* key, AV::uint32 width, AV::uint32 height, std::vector<PlacedItemData>& itemData){
        size_t len = width * height * sizeof(AV::uint16);
        sq_pushstring(vm, key, -1);
        void* b = sqstd_createblob(vm, len);
        AV::uint16* buf = static_cast<AV::uint16*>(b);
        memset(buf, 0xFFFF, len);

        AV::uint16 c = 0;
        for(const PlacedItemData& d : itemData){
            *(buf + (d.originX + d.originY * width)) = c;
            c++;
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
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        sq_newtable(vm);

        const std::map<std::string, MapDataEntry>& data = mapData->getEntries();

        for(const std::pair<std::string, MapDataEntry>& entry : data){
            if(entry.first == "playerStart"){
                pushInteger(vm, entry.first.c_str(), entry.second.value.uint32);
            }
            if(entry.second.type == MapDataEntryType::UINT32){
                pushInteger(vm, entry.first.c_str(), entry.second.value.uint32);
            }
            else if(entry.second.type == MapDataEntryType::WORLD_POINT){
                pushInteger(vm, entry.first.c_str(), entry.second.value.worldPoint);
            }
        }

        //pushInteger(vm, "seed", mapData->seed);
        //pushInteger(vm, "moistureSeed", mapData->moistureSeed);
        //pushInteger(vm, "variationSeed", mapData->variationSeed);
        /*
        pushInteger(vm, "width", mapData->width);
        pushInteger(vm, "height", mapData->height);
        pushInteger(vm, "seaLevel", mapData->uint32("seaLevel"));
        pushInteger(vm, "playerStart", mapData->worldPoint("playerStart"));
        pushInteger(vm, "gatewayPosition", mapData->worldPoint("gatewayPosition"));
        */

        pushFloodData(vm, "waterData", *mapData->ptr<std::vector<FloodFillEntry*>>("waterData"));
        pushFloodData(vm, "landData", *mapData->ptr<std::vector<FloodFillEntry*>>("landData"));
        //pushPlaceData(vm, "placeData", mapData->placeData);
        pushRegionData(vm, "regionData", *mapData->ptr<std::vector<RegionData>>("regionData"));
        pushPlacedItemData(vm, "placedItems", *mapData->ptr<std::vector<PlacedItemData>>("placedItems"));
        //generatePushedItemBuffer(vm, "placedItemsBuffer", mapData->width, mapData->height, *mapData->ptr<std::vector<PlacedItemData>>("placedItems"));

        //pushBuffer(vm, "voxelBuffer", mapData->voxelBuffer, mapData->voxelBufferSize);
        //pushBuffer(vm, "secondaryVoxBuffer", mapData->secondaryVoxelBuffer, mapData->secondaryVoxelBufferSize);
        //pushBuffer(vm, "blueNoiseBuffer", mapData->blueNoiseBuffer, mapData->blueNoiseBufferSize);

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getAltitudeForPos(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, 0);
            return 1;
        }

        WorldCoord x, y;
        x = static_cast<WorldCoord>(outVec.x);
        y = static_cast<WorldCoord>(outVec.z);

        const AV::uint8* voxPtr = VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));

        sq_pushinteger(vm, static_cast<SQInteger>(*voxPtr));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getLandmassForPos(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        LandId outLandmass = INVALID_LAND_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, static_cast<SQInteger>(outLandmass));
            return 1;
        }

        WorldCoord x, y;
        x = static_cast<WorldCoord>(outVec.x);
        y = static_cast<WorldCoord>(outVec.z);

        const AV::uint8* landPtr = LAND_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
        outLandmass = *landPtr;

        sq_pushinteger(vm, static_cast<SQInteger>(outLandmass));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getWaterGroupForPos(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        WaterId outWater = INVALID_WATER_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, static_cast<SQInteger>(outWater));
            return 1;
        }

        WorldCoord x, y;
        x = static_cast<WorldCoord>(outVec.x);
        y = static_cast<WorldCoord>(outVec.z);

        const WaterId* waterPtr = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
        outWater = *waterPtr;

        sq_pushinteger(vm, static_cast<SQInteger>(outWater));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getIsWaterForCoord(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger x, y;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);

        WaterId outWater = INVALID_WATER_ID;

        if(x < 0 || y < 0 || x >= mapData->width || y >= mapData->height){
            sq_pushinteger(vm, static_cast<SQInteger>(outWater));
            return 1;
        }

        const WaterId* waterPtr = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
        if(*waterPtr == INVALID_WATER_ID){
            sq_pushbool(vm, false);
            return 1;
        }

        sq_pushbool(vm, true);

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getIsWaterForPoint(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger worldPoint;
        sq_getinteger(vm, 2, &worldPoint);

        WorldPoint p = static_cast<WorldPoint>(worldPoint);

        const WaterId* waterPtr = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, p);
        if(*waterPtr == INVALID_WATER_ID){
            sq_pushbool(vm, false);
            return 1;
        }

        sq_pushbool(vm, true);

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getIsWaterForPos(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        WaterId outWater = INVALID_WATER_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushbool(vm, true);
            return 1;
        }

        WorldCoord x, y;
        x = static_cast<WorldCoord>(outVec.x);
        y = static_cast<WorldCoord>(outVec.z);

        WorldPoint p = WRAP_WORLD_POINT(x, y);

        AV::uint32* worldPtr = FULL_PTR_FOR_COORD_SECONDARY(mapData, p);
        if(*worldPtr & RIVER_VOXEL_FLAG){
            sq_pushbool(vm, true);
            return 1;
        }

        const AV::uint8* waterPtr = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, p);
        if(*waterPtr == INVALID_WATER_ID){
            sq_pushbool(vm, false);
            return 1;
        }

        sq_pushbool(vm, true);

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionForPos(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, -1, &outVec));
        outVec.z = -outVec.z;

        RegionId outRegion = INVALID_REGION_ID;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, static_cast<SQInteger>(outRegion));
            return 1;
        }

        WorldCoord x, y;
        x = static_cast<WorldCoord>(outVec.x);
        y = static_cast<WorldCoord>(outVec.z);

        const AV::uint8* regionPtr = REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
        outRegion = *regionPtr;

        sq_pushinteger(vm, static_cast<SQInteger>(outRegion));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::randomIntMinMax(HSQUIRRELVM vm){
        SQInteger min, max;
        sq_getinteger(vm, 2, &min);
        sq_getinteger(vm, 3, &max);
        size_t result = mapGenRandomIntMinMax(min, max);

        sq_pushinteger(vm, static_cast<SQInteger>(result));
        return 1;
    }

    SQInteger ExplorationMapDataUserData::setValue(HSQUIRRELVM vm){
        ExplorationMapData* outMapData;
        SCRIPT_ASSERT_RESULT(readExplorationMapDataFromUserData(vm, 1, &outMapData));

        const SQChar *key;
        sq_getstring(vm, 2, &key);

        MapDataEntry entry;

        SQObjectType t = sq_gettype(vm, 3);
        if(t == OT_INTEGER){
            SQInteger val;
            sq_getinteger(vm, 3, &val);
            AV::uint32 v = static_cast<AV::uint32>(val);
            entry.value.uint32 = v;
            entry.type = MapDataEntryType::UINT32;

            outMapData->setEntry(key, entry);
        }else{
            assert(false);
        }

        return 0;
    }

    SQInteger ExplorationMapDataUserData::getValue(HSQUIRRELVM vm){
        ExplorationMapData* outMapData;
        SCRIPT_ASSERT_RESULT(readExplorationMapDataFromUserData(vm, 1, &outMapData));

        const SQChar *key;
        sq_getstring(vm, 2, &key);

        MapDataEntry outEntry;
        MapDataReadResult result = outMapData->readEntry(key, &outEntry);
        if(result == MapDataReadResult::NOT_FOUND){
            std::string val = std::string("The requested value '") + key + "' was not found.";
            return sq_throwerror(vm, val.c_str());
        }


        if(outEntry.type == MapDataEntryType::UINT32){
            sq_pushinteger(vm, outEntry.value.uint32);
        }
        else if(outEntry.type == MapDataEntryType::WORLD_POINT){
            sq_pushinteger(vm, outEntry.value.worldPoint);
        }
        else if(outEntry.type == MapDataEntryType::VOID_PTR){
            assert(false);
        }
        else if(outEntry.type == MapDataEntryType::SIZE_TYPE){
            sq_pushinteger(vm, outEntry.value.size);
        }
        else{
            assert(false);
        }

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getNumRegions(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        size_t numRegions = mapData->ptr<std::vector<RegionData>>("regionData")->size();
        sq_pushinteger(vm, static_cast<SQInteger>(numRegions));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionTotal(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        const std::vector<RegionData>* numRegions = mapData->ptr<const std::vector<RegionData>>("regionData");
        sq_pushinteger(vm, static_cast<SQInteger>((*numRegions)[idx].total));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionType(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        const std::vector<RegionData>* numRegions = mapData->ptr<const std::vector<RegionData>>("regionData");
        sq_pushinteger(vm, static_cast<SQInteger>((*numRegions)[idx].type));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionTotalCoords(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        const std::vector<RegionData>* regions = mapData->ptr<const std::vector<RegionData>>("regionData");
        sq_pushinteger(vm, static_cast<SQInteger>((*regions)[idx].coords.size()));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionCoordForIdx(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        SQInteger coordIdx;
        sq_getinteger(vm, 3, &coordIdx);

        const std::vector<RegionData>* regions = mapData->ptr<const std::vector<RegionData>>("regionData");
        sq_pushinteger(vm, static_cast<SQInteger>((*regions)[idx].coords[coordIdx]));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::getRegionId(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        const std::vector<RegionData>* regions = mapData->ptr<const std::vector<RegionData>>("regionData");
        sq_pushinteger(vm, static_cast<SQInteger>((*regions)[idx].id));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::voxValueForCoord(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger x, y;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);

        const AV::uint8* val = VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));

        AV::uint32 outVal = *(reinterpret_cast<const AV::uint32*>(val));
        sq_pushinteger(vm, static_cast<SQInteger>(outVal));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::writeVoxValueForCoord(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger x, y, val;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);
        sq_getinteger(vm, 4, &val);

        AV::uint8* ptr = VOX_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));

        AV::uint32 writeVal = static_cast<AV::uint32>(val);
        *(reinterpret_cast<AV::uint32*>(ptr)) = writeVal;

        return 0;
    }

    SQInteger ExplorationMapDataUserData::secondaryValueForCoord(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger x, y;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);

        const AV::uint32* val = FULL_PTR_FOR_COORD_SECONDARY(mapData, WRAP_WORLD_POINT(x, y));

        sq_pushinteger(vm, static_cast<SQInteger>(*val));

        return 1;
    }

    SQInteger ExplorationMapDataUserData::writeSecondaryValueForCoord(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger x, y, val;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);
        sq_getinteger(vm, 4, &val);

        AV::uint32* ptr = FULL_PTR_FOR_COORD_SECONDARY(mapData, WRAP_WORLD_POINT(x, y));

        *ptr = static_cast<AV::uint32>(val);

        return 0;
    }

    SQInteger ExplorationMapDataUserData::averageOutAltitudeRectangle(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        SQInteger oX, oY, hX, hY, ditherDist;
        SQInteger rId;
        sq_getinteger(vm, 2, &oX);
        sq_getinteger(vm, 3, &oY);
        sq_getinteger(vm, 4, &hX);
        sq_getinteger(vm, 5, &hY);
        sq_getinteger(vm, 6, &ditherDist); // New dither distance parameter
        sq_getinteger(vm, 7, &rId); // New dither distance parameter

        AV::uint32 originX, originY, halfX, halfY, ditherDistance;
        RegionId regionId = static_cast<RegionId>(rId);
        originX = static_cast<AV::uint32>(oX);
        originY = static_cast<AV::uint32>(oY);
        halfX = static_cast<AV::uint32>(hX);
        halfY = static_cast<AV::uint32>(hY);
        ditherDistance = static_cast<AV::uint32>(ditherDist);

        // First pass: Calculate the average altitude for the core region
        size_t count = 0;
        size_t altitudeTotal = 0;
        for(AV::uint32 y = originY - halfY; y < originY + halfY; y++){
            for(AV::uint32 x = originX - halfX; x < originX + halfX; x++){
                const AV::uint8* voxPtr = VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                altitudeTotal += *voxPtr;
                count++;
            }
        }

        size_t averageAlt = altitudeTotal / count;

        // Second pass: Apply the averaged altitude with dithering
        AV::uint32 totalHalfX = halfX + ditherDistance;
        AV::uint32 totalHalfY = halfY + ditherDistance;

        for(AV::uint32 y = originY - totalHalfY; y < originY + totalHalfY; y++){
            for(AV::uint32 x = originX - totalHalfX; x < originX + totalHalfX; x++){
                // Calculate distance from the core region boundary
                int distX = 0, distY = 0;

                // Distance to core region in X direction
                if(x < originX - halfX) {
                    distX = (originX - halfX) - x;
                } else if(x >= originX + halfX) {
                    distX = x - (originX + halfX - 1);
                }

                // Distance to core region in Y direction
                if(y < originY - halfY) {
                    distY = (originY - halfY) - y;
                } else if(y >= originY + halfY) {
                    distY = y - (originY + halfY - 1);
                }

                // Use maximum distance for rectangular regions
                AV::uint32 distanceFromCore = static_cast<AV::uint32>(std::max(distX, distY));

                AV::uint8* voxPtr = VOX_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                //AV::uint8* regionPtr = REGION_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                AV::uint8 originalAltitude = *voxPtr;

                AV::uint8 newAltitude = 0;
                RegionId newRegion = regionId;
                if(distanceFromCore == 0) {
                    // Inside core region - apply full average
                    newAltitude = static_cast<AV::uint8>(averageAlt);
                } else if(distanceFromCore <= ditherDistance) {
                    // In dither zone - blend between average and original
                    float blendFactor = static_cast<float>(distanceFromCore) / static_cast<float>(ditherDistance);

                    // Apply smooth interpolation (you can use linear or smoothstep)
                    // Linear interpolation:
                    AV::uint8 blendedAltitude = static_cast<AV::uint8>(
                        averageAlt * (1.0f - blendFactor) + originalAltitude * blendFactor
                    );

                    newAltitude = blendedAltitude;
                } else {
                    newAltitude = originalAltitude;
                }

                // Set region for this point
                if(newAltitude < mapData->seaLevel){
                    newRegion = *REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                }
                setRegionForPoint(mapData, WRAP_WORLD_POINT(x, y), newRegion);
                *voxPtr = newAltitude;
                // Points beyond dither distance remain unchanged
            }
        }

        return 0;
    }

    SQInteger ExplorationMapDataUserData::averageOutAltitudeRadius(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));
        SQInteger oX, oY, radius, ditherDist;
        SQInteger rId;
        sq_getinteger(vm, 2, &oX);
        sq_getinteger(vm, 3, &oY);
        sq_getinteger(vm, 4, &radius);
        sq_getinteger(vm, 5, &ditherDist); // Dither distance parameter
        sq_getinteger(vm, 6, &rId); // Region ID parameter

        AV::uint32 originX, originY, coreRadius, ditherDistance;
        RegionId regionId = static_cast<RegionId>(rId);
        originX = static_cast<AV::uint32>(oX);
        originY = static_cast<AV::uint32>(oY);
        coreRadius = static_cast<AV::uint32>(radius);
        ditherDistance = static_cast<AV::uint32>(ditherDist);

        // First pass: Calculate the average altitude for the core circular region
        size_t count = 0;
        size_t altitudeTotal = 0;

        // Iterate through the bounding box of the core circle
        for(AV::uint32 y = originY - coreRadius; y <= originY + coreRadius; y++){
            for(AV::uint32 x = originX - coreRadius; x <= originX + coreRadius; x++){
                // Calculate distance from center
                int dx = static_cast<int>(x) - static_cast<int>(originX);
                int dy = static_cast<int>(y) - static_cast<int>(originY);
                float distanceFromCenter = std::sqrt(dx * dx + dy * dy);

                // Only include points within the core circle
                if(distanceFromCenter <= coreRadius) {
                    const AV::uint8* voxPtr = VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                    altitudeTotal += *voxPtr;
                    count++;
                }
            }
        }

        size_t averageAlt = altitudeTotal / count;

        // Second pass: Apply the averaged altitude with dithering
        AV::uint32 totalRadius = coreRadius + ditherDistance;

        for(AV::uint32 y = originY - totalRadius; y <= originY + totalRadius; y++){
            for(AV::uint32 x = originX - totalRadius; x <= originX + totalRadius; x++){
                // Calculate distance from center
                int dx = static_cast<int>(x) - static_cast<int>(originX);
                int dy = static_cast<int>(y) - static_cast<int>(originY);
                float distanceFromCenter = std::sqrt(dx * dx + dy * dy);

                // Only process points within the total circle (core + dither)
                if(distanceFromCenter <= totalRadius) {
                    AV::uint8* voxPtr = VOX_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                    AV::uint8 originalAltitude = *voxPtr;

                    AV::uint8 newAltitude = 0;
                    RegionId newRegion = regionId;
                    if(distanceFromCenter <= coreRadius) {
                        // Inside core circle - apply full average
                        newAltitude = static_cast<AV::uint8>(averageAlt);
                    } else {
                        // In dither zone - blend between average and original
                        float distanceFromCore = distanceFromCenter - coreRadius;
                        float blendFactor = distanceFromCore / static_cast<float>(ditherDistance);

                        // Apply smooth interpolation (linear)
                        AV::uint8 blendedAltitude = static_cast<AV::uint8>(
                            averageAlt * (1.0f - blendFactor) + originalAltitude * blendFactor
                        );
                        newAltitude = blendedAltitude;
                    }

                    // Set region for this point
                    if(newAltitude < mapData->seaLevel){
                        newRegion = *REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                    }
                    setRegionForPoint(mapData, WRAP_WORLD_POINT(x, y), newRegion);
                    *voxPtr = newAltitude;
                }
                // Points beyond total radius remain unchanged
            }
        }

        return 0;
    }

    SQInteger ExplorationMapDataUserData::applyTerrainVoxelsForPlace(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        const SQChar *mapName;
        const SQChar *basePath;
        SQInteger xx, yy;
        sq_getstring(vm, 2, &mapName);
        sq_getstring(vm, 3, &basePath);
        sq_getinteger(vm, 4, &xx);
        sq_getinteger(vm, 5, &yy);

        TileDataParser tileData(basePath);
        TileDataParser::OutDataContainer out;
        bool result = tileData.readData(&out, mapName, "terrainBlend.txt");
        if(!result){
            sq_pushbool(vm, false);
            return 1;
        }

        TileDataParser::OutDataContainer altitudeOut;
        result = tileData.readData(&altitudeOut, mapName, "terrain.txt");
        if(!result){
            sq_pushbool(vm, false);
            return 1;
        }

        for(AV::uint32 y = 0; y < out.tilesHeight; y++){
            for(AV::uint32 x = 0; x < out.tilesWidth; x++){
                if(altitudeOut.tileValues[x + y * out.tilesWidth] == 0){
                    continue;
                }

                AV::uint32 xxx = x + static_cast<AV::uint32>(xx);
                AV::uint32 yyy = y + static_cast<AV::uint32>(yy);
                AV::uint8* voxPtr = VOX_VALUE_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(xxx, yyy));
                *voxPtr = out.tileValues[x + y * out.tilesWidth];

                AV::uint32* secondaryVoxPtr = FULL_PTR_FOR_COORD_SECONDARY(mapData, WRAP_WORLD_POINT(xxx, yyy));
                *secondaryVoxPtr |= (DRAW_COLOUR_VOXEL_FLAG | DO_NOT_CHANGE_VOXEL);
            }
        }

        sq_pushbool(vm, true);
        return 1;
    }

    SQInteger ExplorationMapDataUserData::calculateEdgeVoxels(HSQUIRRELVM vm){
        ExplorationMapData* mapData;
        SCRIPT_ASSERT_RESULT(ExplorationMapDataUserData::readExplorationMapDataFromUserData(vm, 1, &mapData));

        AV::uint32 width = mapData->uint32("width");
        AV::uint32 height = mapData->uint32("height");

        //Create a table to return the edge voxel positions
        sq_newtable(vm);

        //Helper lambda to check if a position has land
        auto hasLand = [mapData](AV::uint32 x, AV::uint32 y)->bool{
            const AV::uint8* voxPtr = VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
            return *voxPtr >= 100;
        };

        //Helper lambda to push a Vec3 to the stack
        auto pushVec3 = [vm](const char* key, float x, float y, float z){
            sq_pushstring(vm, key, -1);
            AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(x, y, z));
            sq_rawset(vm, -3);
        };

        //Find top edge (largest y in world space, smallest gridY, scan from left to right)
        sq_pushstring(vm, "top", -1);
        bool foundTop = false;
        for(AV::uint32 y = 0; y < height && !foundTop; y++){
            for(AV::uint32 x = 0; x < width; x++){
                if(hasLand(x, y)){
                    float worldY = -(static_cast<float>(height - 1 - y));
                    AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(static_cast<float>(x), 0.0f, worldY));
                    foundTop = true;
                    break;
                }
            }
        }
        sq_rawset(vm, -3);

        //Find bottom edge (smallest y in world space, largest gridY, scan from left to right)
        sq_pushstring(vm, "bottom", -1);
        bool foundBottom = false;
        for(int y = static_cast<int>(height) - 1; y >= 0 && !foundBottom; y--){
            for(AV::uint32 x = 0; x < width; x++){
                if(hasLand(x, static_cast<AV::uint32>(y))){
                    float worldY = -(static_cast<float>(height - 1 - y));
                    AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(static_cast<float>(x), 0.0f, worldY));
                    foundBottom = true;
                    break;
                }
            }
        }
        sq_rawset(vm, -3);

        //Find left edge (smallest x in world space, smallest x index, scan from top to bottom)
        sq_pushstring(vm, "left", -1);
        bool foundLeft = false;
        for(AV::uint32 x = 0; x < width && !foundLeft; x++){
            for(AV::uint32 y = 0; y < height; y++){
                if(hasLand(x, y)){
                    float worldY = -(static_cast<float>(height - 1 - y));
                    AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(static_cast<float>(x), 0.0f, worldY));
                    foundLeft = true;
                    break;
                }
            }
        }
        sq_rawset(vm, -3);

        //Find right edge (largest x in world space, largest x index, scan from top to bottom)
        sq_pushstring(vm, "right", -1);
        bool foundRight = false;
        for(int x = static_cast<int>(width) - 1; x >= 0 && !foundRight; x--){
            for(AV::uint32 y = 0; y < height; y++){
                if(hasLand(static_cast<AV::uint32>(x), y)){
                    float worldY = -(static_cast<float>(height - 1 - y));
                    AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(static_cast<float>(x), 0.0f, worldY));
                    foundRight = true;
                    break;
                }
            }
        }
        sq_rawset(vm, -3);

        return 1;
    }

    template <bool B>
    void ExplorationMapDataUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, explorationMapDataToTable, "explorationMapDataToTable");
        AV::ScriptUtils::addFunction(vm, getAltitudeForPos, "getAltitudeForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, getLandmassForPos, "getLandmassForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, getWaterGroupForPos, "getWaterGroupForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, getIsWaterForPos, "getIsWaterForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, getRegionForPos, "getRegionForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, randomIntMinMax, "randomIntMinMax", 3, ".ii");

        AV::ScriptUtils::addFunction(vm, getIsWaterForCoord, "getIsWaterForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, getIsWaterForPoint, "getIsWaterForPoint", 2, ".i");

        AV::ScriptUtils::addFunction(vm, setValue, "_set");
        AV::ScriptUtils::addFunction(vm, getValue, "_get");

        AV::ScriptUtils::addFunction(vm, voxValueForCoord, "voxValueForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, writeVoxValueForCoord, "writeVoxValueForCoord", 4, ".iii");
        AV::ScriptUtils::addFunction(vm, secondaryValueForCoord, "secondaryValueForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, writeSecondaryValueForCoord, "writeSecondaryValueForCoord", 4, ".iii");

        AV::ScriptUtils::addFunction(vm, getNumRegions, "getNumRegions");
        AV::ScriptUtils::addFunction(vm, getRegionTotal, "getRegionTotal", 2, ".i");
        AV::ScriptUtils::addFunction(vm, getRegionType, "getRegionType", 2, ".i");
        AV::ScriptUtils::addFunction(vm, getRegionTotalCoords, "getRegionTotalCoords", 2, ".i");
        AV::ScriptUtils::addFunction(vm, getRegionCoordForIdx, "getRegionCoordForIdx", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, getRegionId, "getRegionId", 2, ".i");

        AV::ScriptUtils::addFunction(vm, averageOutAltitudeRectangle, "averageOutAltitudeRectangle", 7, ".iiiiii");
        AV::ScriptUtils::addFunction(vm, averageOutAltitudeRadius, "averageOutAltitudeRadius", 6, ".iiiii");
        AV::ScriptUtils::addFunction(vm, applyTerrainVoxelsForPlace, "applyTerrainVoxelsForPlace", 5, ".ssii");
        AV::ScriptUtils::addFunction(vm, calculateEdgeVoxels, "calculateEdgeVoxels");

        SQObject* tableObj = 0;
        if(B){
            tableObj = &ExplorationMapDataDelegateTableObjectMapGenVM;
        }else{
            tableObj = &ExplorationMapDataDelegateTableObject;
        }
        sq_resetobject(tableObj);
        sq_getstackobj(vm, -1, tableObj);
        sq_addref(vm, tableObj);
        sq_pop(vm, 1);
    }
}
