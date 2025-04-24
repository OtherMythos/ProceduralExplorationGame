#pragma once

#include "squirrel.h"

namespace ProceduralExplorationGameCore{

    class MapGenNamespace{
    public:
        MapGenNamespace() = delete;

        static void setupNamespace(HSQUIRRELVM vm);

    private:
        static SQInteger registerStep(HSQUIRRELVM vm);
    };

}
