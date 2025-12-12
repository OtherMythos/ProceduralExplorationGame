#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace AV{
    class CollisionWorldObject;
}

namespace ProceduralExplorationGameCore{

    /**
    Abstracts a simple file interface for squirrel.
    */
    class CollisionWorldClass{
    public:
        CollisionWorldClass() = delete;

        static void setupDelegateTable(HSQUIRRELVM vm);
        static void setupConstants(HSQUIRRELVM vm);

        static void collisionWorldToUserData(HSQUIRRELVM vm, AV::CollisionWorldObject* world);
        static AV::UserDataGetResult readCollisionWorldFromUserData(HSQUIRRELVM vm, SQInteger stackInx, AV::CollisionWorldObject** outWorld);

    private:
        enum CollisionWorldType{
            WorldBruteForce,
            WorldOctree,
        };

        static SQObject collisionWorldDelegateTableObject;

        static SQInteger createCollisionWorld(HSQUIRRELVM vm);
        static SQInteger processCollision(HSQUIRRELVM vm);
        static SQInteger addCollisionPoint(HSQUIRRELVM vm);
        static SQInteger addCollisionRectangle(HSQUIRRELVM vm);
        static SQInteger addCollisionRotatedRectangle(HSQUIRRELVM vm);
        static SQInteger removeCollisionPoint(HSQUIRRELVM vm);
        static SQInteger getNumCollisions(HSQUIRRELVM vm);
        static SQInteger getCollisionPairForIdx(HSQUIRRELVM vm);
        static SQInteger setPositionForPoint(HSQUIRRELVM vm);
        static SQInteger checkCollisionPoint(HSQUIRRELVM vm);

        static SQInteger collisionWorldReleaseHook(SQUserPointer p, SQInteger size);

    };
}
