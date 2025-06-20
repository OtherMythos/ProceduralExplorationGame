#include "SquirrelDeepCopy.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{

    bool DeepCopy::deepCopyValue(HSQUIRRELVM srcvm, HSQUIRRELVM dstvm, SQInteger srcidx) {
        SQObjectType type = sq_gettype(srcvm, srcidx);

        switch (type) {
            case OT_NULL:
                sq_pushnull(dstvm);
                break;

            case OT_BOOL: {
                SQBool value;
                if (SQ_FAILED(sq_getbool(srcvm, srcidx, &value))) return false;
                sq_pushbool(dstvm, value);
                break;
            }

            case OT_INTEGER: {
                SQInteger value;
                if (SQ_FAILED(sq_getinteger(srcvm, srcidx, &value))) return false;
                sq_pushinteger(dstvm, value);
                break;
            }

            case OT_FLOAT: {
                SQFloat value;
                if (SQ_FAILED(sq_getfloat(srcvm, srcidx, &value))) return false;
                sq_pushfloat(dstvm, value);
                break;
            }

            case OT_STRING: {
                const SQChar* value;
                if (SQ_FAILED(sq_getstring(srcvm, srcidx, &value))) return false;
                sq_pushstring(dstvm, value, -1);
                break;
            }

            case OT_TABLE: {
                // Normalize index to positive
                SQInteger normalizedIdx = srcidx < 0 ? sq_gettop(srcvm) + srcidx + 1 : srcidx;
                return deepCopyTable(srcvm, dstvm, normalizedIdx);
            }

            case OT_ARRAY: {
                // Normalize index to positive
                SQInteger normalizedIdx = srcidx < 0 ? sq_gettop(srcvm) + srcidx + 1 : srcidx;
                return deepCopyArray(srcvm, dstvm, normalizedIdx);
            }

            case OT_USERDATA:
            case OT_CLOSURE:
            case OT_NATIVECLOSURE:
            case OT_GENERATOR:
            case OT_USERPOINTER:
            case OT_THREAD:
            case OT_FUNCPROTO:
            case OT_CLASS:
            case OT_INSTANCE:
            case OT_WEAKREF:
                // For complex types that can't be easily copied, you might want to:
                // 1. Skip them (push null)
                // 2. Use sq_move if they're compatible
                // 3. Implement custom serialization

                // Using sq_move for these types (may not work for all cases)
                sq_move(dstvm, srcvm, srcidx);
                break;

            default:
                // Unknown type, push null
                sq_pushnull(dstvm);
                break;
        }

        return true;
    }

    // Deep copy a table from source VM to destination VM
    bool DeepCopy::deepCopyTable(HSQUIRRELVM srcvm, HSQUIRRELVM dstvm, SQInteger srcidx) {
        // Create new table on destination VM
        sq_newtable(dstvm);

        // Push null for iteration start
        sq_pushnull(srcvm);

        while (SQ_SUCCEEDED(sq_next(srcvm, srcidx))) {
            // Stack now has: key, value
            // We need to copy both key and value to destination VM

            AV::ScriptUtils::_debugStack(srcvm);

            // Copy the key (at -2 relative to top)
            if (!deepCopyValue(srcvm, dstvm, -2)) {
                sq_pop(srcvm, 2); // pop key and value
                sq_pop(dstvm, 1); // pop incomplete table
                return false;
            }

            // Copy the value (at -1 relative to top)
            if (!deepCopyValue(srcvm, dstvm, -1)) {
                sq_pop(srcvm, 2); // pop key and value from source
                sq_pop(dstvm, 2); // pop key and incomplete table from dest
                return false;
            }

            AV::ScriptUtils::_debugStack(dstvm);
            // Set the key-value pair in destination table
            // Stack on dest VM: table, key, value
            if (SQ_FAILED(sq_newslot(dstvm, -3, false))) {
                sq_pop(srcvm, 2); // pop key and value from source
                sq_pop(dstvm, 1); // pop incomplete table from dest
                return false;
            }

            // Pop key and value from source VM for next iteration
            sq_pop(srcvm, 2);
        }

        // Pop the null iterator
        sq_pop(srcvm, 1);

        return true;
    }

    // Deep copy an array from source VM to destination VM
    bool DeepCopy::deepCopyArray(HSQUIRRELVM srcvm, HSQUIRRELVM dstvm, SQInteger srcidx) {
        // Get array size
        SQInteger size = sq_getsize(srcvm, srcidx);

        // Create new array on destination VM
        sq_newarray(dstvm, size);

        // Copy each element
        for (SQInteger i = 0; i < size; i++) {
            // Get element from source array
            sq_pushinteger(srcvm, i);
            if (SQ_FAILED(sq_get(srcvm, srcidx))) {
                sq_pop(dstvm, 1); // pop incomplete array
                return false;
            }

            // Copy the element value
            if (!deepCopyValue(srcvm, dstvm, -1)) {
                sq_pop(srcvm, 1); // pop element from source
                sq_pop(dstvm, 1); // pop incomplete array from dest
                return false;
            }

            // Set element in destination array
            sq_pushinteger(dstvm, i);
            sq_push(dstvm, -2); // push the copied value
            if (SQ_FAILED(sq_set(dstvm, -4))) { // set in array (which is at -4 now)
                sq_pop(srcvm, 1); // pop element from source
                sq_pop(dstvm, 3); // pop value, index, and incomplete array
                return false;
            }

            // Clean up
            sq_pop(srcvm, 1); // pop element from source
            sq_pop(dstvm, 1); // pop the copied value (it's now in the array)
        }

        return true;
    }

}
