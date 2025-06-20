#include <squirrel.h>
#include <sqstdaux.h>

namespace ProceduralExplorationGameCore{

    class DeepCopy{
    public:
        static bool deepCopyValue(HSQUIRRELVM srcvm, HSQUIRRELVM dstvm, SQInteger srcidx);
        static bool deepCopyTable(HSQUIRRELVM srcvm, HSQUIRRELVM dstvm, SQInteger srcidx);
        static bool deepCopyArray(HSQUIRRELVM srcvm, HSQUIRRELVM dstvm, SQInteger srcidx);
    };

}