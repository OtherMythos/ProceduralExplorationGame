#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{
    struct ExplorationMapData;
}

namespace ProceduralExplorationGamePlugin{
    class ExplorationMapDataUserData{
    public:
        ExplorationMapDataUserData() = delete;
        ~ExplorationMapDataUserData() = delete;

        static void setupDelegateTable(HSQUIRRELVM vm);

        static void ExplorationMapDataToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapData* program);

        static AV::UserDataGetResult readExplorationMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::ExplorationMapData** outProg);

    private:
        static SQObject ExplorationMapDataDelegateTableObject;

        static SQInteger explorationMapDataToTable(HSQUIRRELVM vm);
        static SQInteger getAltitudeForPos(HSQUIRRELVM vm);
        static SQInteger getLandmassForPos(HSQUIRRELVM vm);
        static SQInteger getIsWaterForPos(HSQUIRRELVM vm);
        static SQInteger getRegionForPos(HSQUIRRELVM vm);

        static SQInteger ExplorationMapDataObjectReleaseHook(SQUserPointer p, SQInteger size);
    };
}
