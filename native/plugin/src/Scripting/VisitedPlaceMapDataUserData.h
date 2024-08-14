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

        static SQInteger visitedPlaceMapDataObjectReleaseHook(SQUserPointer p, SQInteger size);
    };
}
