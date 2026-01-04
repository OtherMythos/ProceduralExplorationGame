#pragma once

#include "squirrel.h"
#include "rapidjson/document.h"

namespace ProceduralExplorationGameCore{

    class MapGenNamespace{
    public:
        MapGenNamespace()=delete;

        static void setupNamespace(HSQUIRRELVM vm);

    private:
        static SQInteger registerStep(HSQUIRRELVM vm);
        static SQInteger readJSONAsTable(HSQUIRRELVM vm);
        static SQInteger pathExists(HSQUIRRELVM vm);
        static void _readJsonValue(HSQUIRRELVM vm, const rapidjson::Value& value);
        static void _readJsonObject(HSQUIRRELVM vm, const rapidjson::GenericMember<rapidjson::UTF8<>, rapidjson::MemoryPoolAllocator<>>& value);
    };

}
