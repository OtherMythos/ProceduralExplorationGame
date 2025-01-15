#include "VisitedPlaceMapDataUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"

#include <sqstdblob.h>
#include <vector>

#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/MeshUserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Scene/RayUserData.h"
#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"

#include "VisitedPlaces/VisitedPlacesPrerequisites.h"
#include "VisitedPlaces/VisitedPlaceMapDataHelper.h"

#include "Ogre.h"

namespace ProceduralExplorationGamePlugin{

    SQObject VisitedPlaceMapDataUserData::VisitedPlaceMapDataDelegateTableObject;

    void VisitedPlaceMapDataUserData::visitedPlaceMapDataToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::VisitedPlaceMapData* data){
        ProceduralExplorationGameCore::VisitedPlaceMapData** pointer = (ProceduralExplorationGameCore::VisitedPlaceMapData**)sq_newuserdata(vm, sizeof(ProceduralExplorationGameCore::VisitedPlaceMapData*));
        *pointer = data;

        sq_pushobject(vm, VisitedPlaceMapDataDelegateTableObject);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, VisitedPlaceMapDataTypeTag);
        sq_setreleasehook(vm, -1, visitedPlaceMapDataObjectReleaseHook);
    }

    AV::UserDataGetResult VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::VisitedPlaceMapData** outData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != VisitedPlaceMapDataTypeTag){
            *outData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        ProceduralExplorationGameCore::VisitedPlaceMapData** p = (ProceduralExplorationGameCore::VisitedPlaceMapData**)pointer;
        *outData = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger VisitedPlaceMapDataUserData::visitedPlaceMapDataObjectReleaseHook(SQUserPointer p, SQInteger size){
        ProceduralExplorationGameCore::VisitedPlaceMapData** ptr = static_cast<ProceduralExplorationGameCore::VisitedPlaceMapData**>(p);
        delete *ptr;

        return 0;
    }

    SQInteger VisitedPlaceMapDataUserData::getAltitudeForPos(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        Ogre::Vector3 outVec;
        SCRIPT_CHECK_RESULT(AV::Vector3UserData::readVector3FromUserData(vm, 2, &outVec));
        outVec.z = -outVec.z;

        if(outVec.x < 0 || outVec.z < 0 || outVec.x >= mapData->width || outVec.z >= mapData->height){
            sq_pushinteger(vm, 0);
            return 1;
        }

        ProceduralExplorationGameCore::WorldCoord x, y;
        x = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.x);
        y = static_cast<ProceduralExplorationGameCore::WorldCoord>(outVec.z);

        AV::uint8 altitude = mapData->altitudeValues[x + y * mapData->width];

        sq_pushinteger(vm, static_cast<SQInteger>(altitude));

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getIsWaterForPos(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

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

        /*
        const AV::uint8* waterPtr = ProceduralExplorationGameCore::WATER_GROUP_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x, y));
        if(*waterPtr == ProceduralExplorationGameCore::INVALID_WATER_ID){
            sq_pushbool(vm, false);
            return 1;
        }
        */

        sq_pushbool(vm, true);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::voxeliseTerrainMeshForData(HSQUIRRELVM vm){
        const SQChar *meshName;
        sq_getstring(vm, 2, &meshName);

        SQInteger x, y, width, height;
        sq_getinteger(vm, 3, &x);
        sq_getinteger(vm, 4, &y);
        sq_getinteger(vm, 5, &width);
        sq_getinteger(vm, 6, &height);

        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        Ogre::MeshPtr outPtr;
        ProceduralExplorationGameCore::VisitedPlaceMapDataHelper helper(mapData);
        helper.voxeliseToTerrainMeshes(meshName, &outPtr, x, y, width, height);

        if(!outPtr){
            sq_pushnull(vm);
            return 1;
        }

        AV::MeshUserData::MeshToUserData(vm, outPtr);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getWidth(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        sq_pushinteger(vm, mapData->width);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getHeight(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        sq_pushinteger(vm, mapData->height);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getTilesWidth(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        sq_pushinteger(vm, mapData->tilesWidth);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getTilesHeight(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        sq_pushinteger(vm, mapData->tilesHeight);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getNumDataPoints(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        sq_pushinteger(vm, mapData->dataPointValues.size());

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::terrainActive(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        sq_pushbool(vm, !mapData->voxelValues.empty());

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getDataPointAt(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        SQInteger idx = 0;
        sq_getinteger(vm, 2, &idx);

        if(sq_getsize(vm, -2) > 2) return sq_throwerror(vm, "The provided array was too small.");

        if(idx < 0 || idx >= mapData->dataPointValues.size()){
            return sq_throwerror(vm, "Invalid idx");
        }
        const ProceduralExplorationGameCore::DataPointData& e = mapData->dataPointValues[idx];
        sq_pushinteger(vm, 0);
        AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(e.x, e.y, e.z));
        sq_rawset(vm, 3);
        sq_pushinteger(vm, 1);
        sq_pushinteger(vm, e.wrapped);
        sq_rawset(vm, 3);

        return 0;
    }

    template<typename T>
    SQInteger _getDataForVec(HSQUIRRELVM vm, std::vector<T>& vec, AV::uint32 width, AV::uint32 height, T** out){

        SQInteger x, y;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);

        if(x < 0 || y < 0 || x >= width || y >= height){
            sq_throwerror(vm, "Invalid coordinates to query.");
            return 1;
        }

        *out = &(vec[x + y * width]);

        return 0;
    }
    SQInteger VisitedPlaceMapDataUserData::getAltitudeForCoord(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        AV::uint8* outVal;
        _getDataForVec<AV::uint8>(vm, mapData->altitudeValues, mapData->width, mapData->height, &outVal);

        sq_pushinteger(vm, *outVal);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::getVoxelForCoord(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        ProceduralExplorationGameCore::VoxelId* voxVal;
        _getDataForVec<ProceduralExplorationGameCore::VoxelId>(vm, mapData->voxelValues, mapData->width, mapData->height, &voxVal);

        sq_pushinteger(vm, *voxVal);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::setAltitudeForCoord(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        SQInteger altitude;
        sq_getinteger(vm, 4, &altitude);

        AV::uint8* outVal;
        _getDataForVec<AV::uint8>(vm, mapData->altitudeValues, mapData->width, mapData->height, &outVal);

        *outVal = altitude;

        return 0;
    }

    template<typename T>
    inline void pushArray(HSQUIRRELVM vm, const std::vector<T>& vec){
        sq_newarray(vm, vec.size());
        for(size_t i = 0; i < vec.size(); i++){
            sq_pushinteger(vm, i);
            sq_pushinteger(vm, vec[i]);
            sq_rawset(vm, -3);
        }
    }
    SQInteger VisitedPlaceMapDataUserData::getTileArray(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        if(mapData->tileValues.empty()){
            sq_pushnull(vm);
            return 1;
        }

        pushArray<ProceduralExplorationGameCore::TilePoint>(vm, mapData->tileValues);

        return 1;
    }

    SQInteger VisitedPlaceMapDataUserData::setVoxelForCoord(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        SQInteger voxel;
        sq_getinteger(vm, 4, &voxel);

        ProceduralExplorationGameCore::VoxelId* outVal;
        _getDataForVec<ProceduralExplorationGameCore::VoxelId>(vm, mapData->voxelValues, mapData->width, mapData->height, &outVal);

        *outVal = voxel;

        return 0;
    }

    SQInteger VisitedPlaceMapDataUserData::castRayForTerrain(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::VisitedPlaceMapData* mapData;
        SCRIPT_ASSERT_RESULT(VisitedPlaceMapDataUserData::readVisitedPlaceMapDataFromUserData(vm, 1, &mapData));

        Ogre::Ray outRay;
        SCRIPT_CHECK_RESULT(AV::RayUserData::readRayFromUserData(vm, 2, &outRay));

        bool collision = false;
        Ogre::Vector3 result(Ogre::Vector3::ZERO);
        for(int i = 0; i < 1000; i++){
            //TODO this is a dumb search.
            //A better method would be, do a low resolution search until a hit is found, then binary search the space in between to find a more accurate position.
            Ogre::Vector3 point = outRay.getPoint(static_cast<float>(i) / 10);
            Ogre::Vector3 outPoint(point);

            point.z = -point.z;

            if(point.x < 0 || point.z < 0 || point.x >= mapData->width || point.z >= mapData->height){
                continue;
            }

            ProceduralExplorationGameCore::WorldCoord x, y;
            x = static_cast<ProceduralExplorationGameCore::WorldCoord>(point.x);
            y = static_cast<ProceduralExplorationGameCore::WorldCoord>(point.z);

            AV::uint8 altitude = mapData->altitudeValues[x + y * mapData->width];
            if(point.y < static_cast<float>(altitude)*0.4 && point.y >= 0.0f){
                collision = true;
                result = outPoint;
                break;
            }
        }

        if(collision){
            AV::Vector3UserData::vector3ToUserData(vm, result);
        }else{
            sq_pushnull(vm);
        }

        return 1;
    }

    void VisitedPlaceMapDataUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, getAltitudeForPos, "getAltitudeForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, getIsWaterForPos, "getIsWaterForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, voxeliseTerrainMeshForData, "voxeliseTerrainMeshForData", 6, ".siiii");

        AV::ScriptUtils::addFunction(vm, getWidth, "getWidth");
        AV::ScriptUtils::addFunction(vm, getHeight, "getHeight");
        AV::ScriptUtils::addFunction(vm, getTilesWidth, "getTilesWidth");
        AV::ScriptUtils::addFunction(vm, getTilesHeight, "getTilesHeight");
        AV::ScriptUtils::addFunction(vm, getNumDataPoints, "getNumDataPoints");
        AV::ScriptUtils::addFunction(vm, terrainActive, "terrainActive");
        AV::ScriptUtils::addFunction(vm, getDataPointAt, "getDataPointAt", 3, ".ia");
        AV::ScriptUtils::addFunction(vm, getAltitudeForCoord, "getAltitudeForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, getVoxelForCoord, "getVoxelForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, setAltitudeForCoord, "setAltitudeForCoord", 4, ".iii");
        AV::ScriptUtils::addFunction(vm, setVoxelForCoord, "setVoxelForCoord", 4, ".iii");
        AV::ScriptUtils::addFunction(vm, getTileArray, "getTileArray");

        AV::ScriptUtils::addFunction(vm, castRayForTerrain, "castRayForTerrain", 2, ".u");

        sq_resetobject(&VisitedPlaceMapDataDelegateTableObject);
        sq_getstackobj(vm, -1, &VisitedPlaceMapDataDelegateTableObject);
        sq_addref(vm, &VisitedPlaceMapDataDelegateTableObject);
        sq_pop(vm, 1);
    }
}
