#pragma once

#include <squirrel.h>

namespace ProceduralExplorationGamePlugin{

    class GameCoreNamespace{
    public:
        GameCoreNamespace() = delete;

        static void setupNamespace(HSQUIRRELVM vm);

    private:
        static SQInteger getGameCoreVersion(HSQUIRRELVM vm);
        static SQInteger fillBufferWithMapLean(HSQUIRRELVM vm);
        static SQInteger tableToExplorationMapData(HSQUIRRELVM vm);
    };

};
