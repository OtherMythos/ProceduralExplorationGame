#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{
    class MapGenDataContainer;

    class MapGenDataContainerUserData{
    public:
        MapGenDataContainerUserData() = delete;
        ~MapGenDataContainerUserData() = delete;

        static void setupDelegateTable(HSQUIRRELVM vm);

        static void MapGenDataContainerToUserData(HSQUIRRELVM vm, MapGenDataContainer* mapData);

        static AV::UserDataGetResult readMapGenDataContainerFromUserData(HSQUIRRELVM vm, SQInteger stackInx, MapGenDataContainer** outMapData);

    private:
        static SQObject MapGenDataContainerDelegateTableObject;

        static SQInteger getValue(HSQUIRRELVM vm);

        static SQInteger MapGenDataContainerObjectReleaseHook(SQUserPointer p, SQInteger size);
    };
}
