#pragma once

#include "squirrel.h"

namespace ProceduralExplorationGameCore{

    typedef SQInteger(*PopulateFunction)(HSQUIRRELVM vm);
    typedef SQInteger(*ReturnFunction)(HSQUIRRELVM vm);

    /**
    A class to manage a Squirrel VM for use on a worker thread.
    */
    class MapGenScriptVM{
    public:
        MapGenScriptVM();
        ~MapGenScriptVM();

        void setup();

        HSQUIRRELVM getVM();
        bool callClosure(HSQOBJECT closure, const HSQOBJECT* context = 0, PopulateFunction populateFunc = 0, ReturnFunction retFunc = 0);

    private:
        HSQUIRRELVM mVM;
    };

}
