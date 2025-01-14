#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{
    struct VisitedPlaceMapData;
}

namespace ProceduralExplorationGamePlugin{
    class VisitedPlaceMapDataUserData{
    public:
        VisitedPlaceMapDataUserData() = delete;
        ~VisitedPlaceMapDataUserData() = delete;

        static void setupDelegateTable(HSQUIRRELVM vm);

        static void visitedPlaceMapDataToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::VisitedPlaceMapData* mapData);

        static AV::UserDataGetResult readVisitedPlaceMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::VisitedPlaceMapData** outMapData);

    private:
        static SQObject VisitedPlaceMapDataDelegateTableObject;

        static SQInteger getAltitudeForPos(HSQUIRRELVM vm);
        static SQInteger getIsWaterForPos(HSQUIRRELVM vm);
        static SQInteger voxeliseTerrainMeshForData(HSQUIRRELVM vm);

        static SQInteger getWidth(HSQUIRRELVM vm);
        static SQInteger getHeight(HSQUIRRELVM vm);
        static SQInteger getTilesWidth(HSQUIRRELVM vm);
        static SQInteger getTilesHeight(HSQUIRRELVM vm);
        static SQInteger getNumDataPoints(HSQUIRRELVM vm);
        static SQInteger getDataPointAt(HSQUIRRELVM vm);
        static SQInteger terrainActive(HSQUIRRELVM vm);

        static SQInteger getAltitudeForCoord(HSQUIRRELVM vm);
        static SQInteger getVoxelForCoord(HSQUIRRELVM vm);
        static SQInteger setAltitudeForCoord(HSQUIRRELVM vm);
        static SQInteger setVoxelForCoord(HSQUIRRELVM vm);
        static SQInteger getTileArray(HSQUIRRELVM vm);

        static SQInteger castRayForTerrain(HSQUIRRELVM vm);

        static SQInteger getAltitude(HSQUIRRELVM vm);

        static SQInteger visitedPlaceMapDataObjectReleaseHook(SQUserPointer p, SQInteger size);
    };
}
