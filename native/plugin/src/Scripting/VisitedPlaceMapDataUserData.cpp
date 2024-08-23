#include "VisitedPlaceMapDataUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"

#include <sqstdblob.h>
#include <vector>

#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/MeshUserData.h"

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

    void VisitedPlaceMapDataUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, getAltitudeForPos, "getAltitudeForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, getIsWaterForPos, "getIsWaterForPos", 2, ".u");
        AV::ScriptUtils::addFunction(vm, voxeliseTerrainMeshForData, "voxeliseTerrainMeshForData", 6, ".siiii");

        AV::ScriptUtils::addFunction(vm, getWidth, "getWidth");
        AV::ScriptUtils::addFunction(vm, getHeight, "getHeight");
        AV::ScriptUtils::addFunction(vm, getAltitudeForCoord, "getAltitudeForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, getVoxelForCoord, "getVoxelForCoord", 3, ".ii");
        AV::ScriptUtils::addFunction(vm, setAltitudeForCoord, "setAltitudeForCoord", 4, ".iii");
        AV::ScriptUtils::addFunction(vm, setVoxelForCoord, "setVoxelForCoord", 4, ".iii");

        sq_resetobject(&VisitedPlaceMapDataDelegateTableObject);
        sq_getstackobj(vm, -1, &VisitedPlaceMapDataDelegateTableObject);
        sq_addref(vm, &VisitedPlaceMapDataDelegateTableObject);
        sq_pop(vm, 1);
    }
}
