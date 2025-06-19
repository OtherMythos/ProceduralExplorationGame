#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{
    class MapGenDataContainer;

    class MapGenDataContainerUserData{
    public:
        MapGenDataContainerUserData() = delete;
        ~MapGenDataContainerUserData() = delete;

        template <typename T, bool B>
        static void setupDelegateTable(HSQUIRRELVM vm);

        template <typename T, bool B>
        static void MapGenDataContainerToUserData(HSQUIRRELVM vm, T mapData);
        template <typename T>
        static AV::UserDataGetResult readMapGenDataContainerFromUserData(HSQUIRRELVM vm, SQInteger stackInx, T* outMapData);

    private:
        static SQObject MapGenDataContainerDelegateTableObject;
        static SQObject MapGenDataContainerConstDelegateTableObject;

        //Const and non Const
        template <typename T>
        static SQInteger getValue(HSQUIRRELVM vm);
        template <typename T>
        static SQInteger voxValueForCoord(HSQUIRRELVM vm);

        //non Const only
        static SQInteger setValue(HSQUIRRELVM vm);
        static SQInteger setValueConst(HSQUIRRELVM vm);
        static SQInteger writeVoxValueForCoord(HSQUIRRELVM vm);

        static SQInteger MapGenDataContainerObjectReleaseHook(SQUserPointer p, SQInteger size);

        template <typename T>
        static void _defineBaseFunctions(HSQUIRRELVM vm);
    };
}
