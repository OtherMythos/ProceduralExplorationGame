#include "ExplorationMapDataUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"

#include <sqstdblob.h>
#include <vector>

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
        pushEmptyArray(vm, "placeData");
        pushRegionData(vm, "regionData", mapData->regionData);
        pushEmptyArray(vm, "placedItems");

        pushBuffer(vm, "voxelBuffer", mapData->voxelBuffer, mapData->voxelBufferSize);
        pushBuffer(vm, "secondaryVoxBuffer", mapData->secondaryVoxelBuffer, mapData->secondaryVoxelBufferSize);
        pushBuffer(vm, "blueNoiseBuffer", mapData->blueNoiseBuffer, mapData->blueNoiseBufferSize);

        return 1;
    }

    void ExplorationMapDataUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, explorationMapDataToTable, "explorationMapDataToTable");

        sq_resetobject(&ExplorationMapDataDelegateTableObject);
        sq_getstackobj(vm, -1, &ExplorationMapDataDelegateTableObject);
        sq_addref(vm, &ExplorationMapDataDelegateTableObject);
        sq_pop(vm, 1);
    }
}
