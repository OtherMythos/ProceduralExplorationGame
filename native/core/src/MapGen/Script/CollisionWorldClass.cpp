#include "CollisionWorldClass.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"

#include "System/Util/Collision/CollisionWorldObject.h"
#include "System/Util/Collision/CollisionWorldBruteForce.h"
#include "System/Util/Collision/CollisionWorldOctree.h"

#include "Scripting/ScriptObjectTypeTags.h"

namespace ProceduralExplorationGameCore{
    SQObject CollisionWorldClass::collisionWorldDelegateTableObject;

    void CollisionWorldClass::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtableex(vm, 1);

        AV::ScriptUtils::addFunction(vm, processCollision, "processCollision");
        AV::ScriptUtils::addFunction(vm, addCollisionPoint, "addCollisionPoint", -4, ".nnni");
        AV::ScriptUtils::addFunction(vm, addCollisionRectangle, "addCollisionRectangle", -4, ".nnnni");
        AV::ScriptUtils::addFunction(vm, addCollisionRotatedRectangle, "addCollisionRotatedRectangle", -5, ".nnnnni");
        AV::ScriptUtils::addFunction(vm, checkCollisionPoint, "checkCollisionPoint", 4, ".nnn");
        AV::ScriptUtils::addFunction(vm, removeCollisionPoint, "removeCollisionPoint", 2, ".i");
        AV::ScriptUtils::addFunction(vm, getNumCollisions, "getNumCollisions");
        AV::ScriptUtils::addFunction(vm, getCollisionPairForIdx, "getCollisionPairForIdx", 2, ".i");
        AV::ScriptUtils::addFunction(vm, setPositionForPoint, "setPositionForPoint", 4, ".inn");

        sq_resetobject(&collisionWorldDelegateTableObject);
        sq_getstackobj(vm, -1, &collisionWorldDelegateTableObject);
        sq_addref(vm, &collisionWorldDelegateTableObject);
        sq_pop(vm, 1);

        //Create the creation functions.
        sq_pushroottable(vm);

        {
            AV::ScriptUtils::addFunction(vm, createCollisionWorld, "CollisionWorld", -2, ".ii");
        }

    }

    void CollisionWorldClass::setupConstants(HSQUIRRELVM vm){
        AV::ScriptUtils::declareConstant(vm, "_COLLISION_WORLD_BRUTE_FORCE", (SQInteger)CollisionWorldType::WorldBruteForce);
        AV::ScriptUtils::declareConstant(vm, "_COLLISION_WORLD_OCTREE", (SQInteger)CollisionWorldType::WorldOctree);

        AV::ScriptUtils::declareConstant(vm, "_COLLISION_WORLD_ENTRY_EITHER", (SQInteger)AV::CollisionEntryType::either);
        AV::ScriptUtils::declareConstant(vm, "_COLLISION_WORLD_ENTRY_SENDER", (SQInteger)AV::CollisionEntryType::sender);
        AV::ScriptUtils::declareConstant(vm, "_COLLISION_WORLD_ENTRY_RECEIVER", (SQInteger)AV::CollisionEntryType::receiver);
    }

    SQInteger CollisionWorldClass::createCollisionWorld(HSQUIRRELVM vm){
        SQInteger worldType;
        sq_getinteger(vm, 2, &worldType);

        SQInteger worldId = -1;
        if(sq_gettop(vm) >= 3){
            sq_getinteger(vm, 3, &worldId);
        }

        AV::CollisionWorldObject* outWorld;
        if(worldType == CollisionWorldType::WorldBruteForce){
            AV::CollisionWorldBruteForce* bruteForce = new AV::CollisionWorldBruteForce(static_cast<int>(worldId));
            outWorld = dynamic_cast<AV::CollisionWorldObject*>(bruteForce);
        }else if(worldType == CollisionWorldType::WorldOctree){
            AV::CollisionWorldOctree* octree = new AV::CollisionWorldOctree(static_cast<int>(worldId));
            outWorld = dynamic_cast<AV::CollisionWorldObject*>(octree);
        }else{
            return sq_throwerror(vm, "Unknown collision world type requested.");
        }
        assert(outWorld);

        collisionWorldToUserData(vm, outWorld);

        return 1;
    }

    SQInteger CollisionWorldClass::checkCollisionPoint(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQFloat x, y, radius;

        sq_getfloat(vm, 2, &x);
        sq_getfloat(vm, 3, &y);
        sq_getfloat(vm, 4, &radius);

        bool result = outWorld->checkCollisionPoint(x, y, radius);

        sq_pushbool(vm, result);

        return 1;
    }

    SQInteger CollisionWorldClass::addCollisionPoint(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQFloat x, y, radius;

        sq_getfloat(vm, 2, &x);
        sq_getfloat(vm, 3, &y);
        sq_getfloat(vm, 4, &radius);

        AV::uint8 targetMask = 0xFF;
        if(sq_gettop(vm) >= 5){
            SQInteger outMask;
            sq_getinteger(vm, 5, &outMask);
            targetMask = static_cast<AV::uint8>(outMask);
        }
        AV::CollisionEntryType targetEntryType = AV::CollisionEntryType::either;
        if(sq_gettop(vm) >= 6){
            SQInteger outType;
            sq_getinteger(vm, 6, &outType);
            targetEntryType = static_cast<AV::CollisionEntryType>(outType);
        }

        AV::CollisionEntryId entryId = outWorld->addCollisionPoint(x, y, radius, targetMask, targetEntryType);

        sq_pushinteger(vm, static_cast<SQInteger>(entryId));

        return 1;
    }

    SQInteger CollisionWorldClass::addCollisionRectangle(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQFloat x, y, width, height;

        sq_getfloat(vm, 2, &x);
        sq_getfloat(vm, 3, &y);
        sq_getfloat(vm, 4, &width);
        sq_getfloat(vm, 5, &height);

        AV::uint8 targetMask = 0xFF;
        if(sq_gettop(vm) >= 6){
            SQInteger outMask;
            sq_getinteger(vm, 6, &outMask);
            targetMask = static_cast<AV::uint8>(outMask);
        }
        AV::CollisionEntryType targetEntryType = AV::CollisionEntryType::either;
        if(sq_gettop(vm) >= 7){
            SQInteger outType;
            sq_getinteger(vm, 7, &outType);
            targetEntryType = static_cast<AV::CollisionEntryType>(outType);
        }

        AV::CollisionEntryId entryId = outWorld->addCollisionRectangle(x, y, width, height, targetMask, targetEntryType);

        sq_pushinteger(vm, static_cast<SQInteger>(entryId));

        return 1;
    }

    SQInteger CollisionWorldClass::addCollisionRotatedRectangle(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQFloat x, y, width, height, rotation;

        sq_getfloat(vm, 2, &x);
        sq_getfloat(vm, 3, &y);
        sq_getfloat(vm, 4, &width);
        sq_getfloat(vm, 5, &height);
        sq_getfloat(vm, 6, &rotation);

        AV::uint8 targetMask = 0xFF;
        if(sq_gettop(vm) >= 7){
            SQInteger outMask;
            sq_getinteger(vm, 7, &outMask);
            targetMask = static_cast<AV::uint8>(outMask);
        }
        AV::CollisionEntryType targetEntryType = AV::CollisionEntryType::either;
        if(sq_gettop(vm) >= 8){
            SQInteger outType;
            sq_getinteger(vm, 8, &outType);
            targetEntryType = static_cast<AV::CollisionEntryType>(outType);
        }

        AV::CollisionEntryId entryId = outWorld->addCollisionRotatedRectangle(x, y, width, height, rotation, targetMask, targetEntryType);

        sq_pushinteger(vm, static_cast<SQInteger>(entryId));

        return 1;
    }

    SQInteger CollisionWorldClass::removeCollisionPoint(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQInteger entryId;

        sq_getinteger(vm, 2, &entryId);

        if(entryId < 0){
            return sq_throwerror(vm, "Provided value must be positive.");
        }

        outWorld->removeCollisionEntry(static_cast<AV::CollisionEntryId>(entryId));

        return 0;
    }

    SQInteger CollisionWorldClass::processCollision(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        outWorld->processCollision();

        return 0;
    }

    SQInteger CollisionWorldClass::getNumCollisions(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        int collisions = outWorld->getNumCollisions();
        sq_pushinteger(vm, collisions);

        return 1;
    }

    SQInteger CollisionWorldClass::getCollisionPairForIdx(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQInteger pairIdx;
        sq_getinteger(vm, 2, &pairIdx);

        AV::CollisionPackedResult result = outWorld->getCollisionPairForIdx(static_cast<int>(pairIdx));
        if(result == AV::COLLISION_PACKED_RESULT_INVALID){
            return sq_throwerror(vm, "Invalid collision id");
        }

        sq_pushinteger(vm, result);

        return 1;
    }

    SQInteger CollisionWorldClass::setPositionForPoint(HSQUIRRELVM vm){
        AV::CollisionWorldObject* outWorld = 0;
        SCRIPT_ASSERT_RESULT(readCollisionWorldFromUserData(vm, 1, &outWorld));

        SQInteger pairIdx;
        sq_getinteger(vm, 2, &pairIdx);

        SQFloat posX;
        SQFloat posY;
        sq_getfloat(vm, 3, &posX);
        sq_getfloat(vm, 4, &posY);

        outWorld->setPositionForPoint(static_cast<AV::CollisionEntryId>(pairIdx), posX, posY);

        return 0;
    }

    SQInteger CollisionWorldClass::collisionWorldReleaseHook(SQUserPointer p, SQInteger size){
        AV::CollisionWorldObject** outObj = static_cast<AV::CollisionWorldObject**>(p);

        delete *outObj;

        return 0;
    }

    void CollisionWorldClass::collisionWorldToUserData(HSQUIRRELVM vm, AV::CollisionWorldObject* world){
        AV::CollisionWorldObject** pointer = (AV::CollisionWorldObject**)sq_newuserdata(vm, sizeof(AV::CollisionWorldObject*));
        *pointer = world;

        sq_pushobject(vm, collisionWorldDelegateTableObject);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, AV::CollisionWorldTypeTag);
        sq_setreleasehook(vm, -1, collisionWorldReleaseHook);
    }

    AV::UserDataGetResult CollisionWorldClass::readCollisionWorldFromUserData(HSQUIRRELVM vm, SQInteger stackInx, AV::CollisionWorldObject** outWorld){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != AV::CollisionWorldTypeTag){
            *outWorld = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        *outWorld = *((AV::CollisionWorldObject**)pointer);

        return AV::USER_DATA_GET_SUCCESS;
    }
}
