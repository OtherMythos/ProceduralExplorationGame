#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{
    class ExplorationMapData;

    class ExplorationMapDataUserData{
    public:
        ExplorationMapDataUserData() = delete;
        ~ExplorationMapDataUserData() = delete;

        template <bool B>
        static void setupDelegateTable(HSQUIRRELVM vm);

        template <bool B>
        static void ExplorationMapDataToUserData(HSQUIRRELVM vm, ExplorationMapData* mapData);

        static AV::UserDataGetResult readExplorationMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ExplorationMapData** outMapData);

    private:
        static SQObject ExplorationMapDataDelegateTableObject;
        static SQObject ExplorationMapDataDelegateTableObjectMapGenVM;

        static SQInteger explorationMapDataToTable(HSQUIRRELVM vm);
        static SQInteger getAltitudeForPos(HSQUIRRELVM vm);
        static SQInteger getLandmassForPos(HSQUIRRELVM vm);
        static SQInteger getIsWaterForPos(HSQUIRRELVM vm);
        static SQInteger getRegionForPos(HSQUIRRELVM vm);
        static SQInteger getWaterGroupForPos(HSQUIRRELVM vm);
        static SQInteger randomIntMinMax(HSQUIRRELVM vm);

        static SQInteger getValue(HSQUIRRELVM vm);
        static SQInteger setValue(HSQUIRRELVM vm);

        static SQInteger getNumRegions(HSQUIRRELVM vm);
        static SQInteger getRegionTotal(HSQUIRRELVM vm);
        static SQInteger getRegionType(HSQUIRRELVM vm);
        static SQInteger getRegionTotalCoords(HSQUIRRELVM vm);
        static SQInteger getRegionCoordForIdx(HSQUIRRELVM vm);
        static SQInteger getRegionId(HSQUIRRELVM vm);

        static SQInteger voxValueForCoord(HSQUIRRELVM vm);
        static SQInteger writeVoxValueForCoord(HSQUIRRELVM vm);
        static SQInteger secondaryValueForCoord(HSQUIRRELVM vm);
        static SQInteger writeSecondaryValueForCoord(HSQUIRRELVM vm);

        static SQInteger getIsWaterForCoord(HSQUIRRELVM vm);

        static SQInteger ExplorationMapDataObjectReleaseHook(SQUserPointer p, SQInteger size);
    };
}
