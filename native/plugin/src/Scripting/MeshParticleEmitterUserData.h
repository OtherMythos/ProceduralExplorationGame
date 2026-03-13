#pragma once

#include "Scripting/ScriptNamespace/ScriptUtils.h"

namespace ProceduralExplorationGameCore{
    class MeshParticleEmitter;
}

namespace ProceduralExplorationGamePlugin{
    class MeshParticleEmitterUserData{
    public:
        MeshParticleEmitterUserData() = delete;
        ~MeshParticleEmitterUserData() = delete;

        static void setupDelegateTable(HSQUIRRELVM vm);

        static void meshParticleEmitterToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::MeshParticleEmitter* emitter);

        static AV::UserDataGetResult readMeshParticleEmitterFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::MeshParticleEmitter** outEmitter);

    private:
        static SQObject MeshParticleEmitterDelegateTableObject;

        static SQInteger addMeshVariant(HSQUIRRELVM vm);
        static SQInteger setPoolSize(HSQUIRRELVM vm);
        static SQInteger setGravity(HSQUIRRELVM vm);
        static SQInteger setRenderQueueGroup(HSQUIRRELVM vm);
        static SQInteger emit(HSQUIRRELVM vm);
        static SQInteger update(HSQUIRRELVM vm);
        static SQInteger clear(HSQUIRRELVM vm);
        static SQInteger destroy(HSQUIRRELVM vm);

        static SQInteger meshParticleEmitterObjectReleaseHook(SQUserPointer p, SQInteger size);
    };
}
