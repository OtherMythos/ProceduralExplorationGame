#include "MeshParticleEmitterUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"
#include "Ogre/MeshParticleEmitter.h"

namespace ProceduralExplorationGamePlugin{

    SQObject MeshParticleEmitterUserData::MeshParticleEmitterDelegateTableObject;

    void MeshParticleEmitterUserData::meshParticleEmitterToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::MeshParticleEmitter* emitter){
        ProceduralExplorationGameCore::MeshParticleEmitter** pointer = (ProceduralExplorationGameCore::MeshParticleEmitter**)sq_newuserdata(vm, sizeof(ProceduralExplorationGameCore::MeshParticleEmitter*));
        *pointer = emitter;

        sq_pushobject(vm, MeshParticleEmitterDelegateTableObject);
        sq_setdelegate(vm, -2);
        sq_settypetag(vm, -1, MeshParticleEmitterTypeTag);
        sq_setreleasehook(vm, -1, meshParticleEmitterObjectReleaseHook);
    }

    AV::UserDataGetResult MeshParticleEmitterUserData::readMeshParticleEmitterFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::MeshParticleEmitter** outEmitter){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != MeshParticleEmitterTypeTag){
            *outEmitter = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        ProceduralExplorationGameCore::MeshParticleEmitter** p = (ProceduralExplorationGameCore::MeshParticleEmitter**)pointer;
        *outEmitter = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger MeshParticleEmitterUserData::meshParticleEmitterObjectReleaseHook(SQUserPointer p, SQInteger size){
        ProceduralExplorationGameCore::MeshParticleEmitter** ptr = static_cast<ProceduralExplorationGameCore::MeshParticleEmitter**>(p);
        delete *ptr;

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::addMeshVariant(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        const SQChar* meshName;
        sq_getstring(vm, 2, &meshName);

        emitter->addMeshVariant(meshName);

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::setPoolSize(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        SQInteger poolSize;
        sq_getinteger(vm, 2, &poolSize);

        emitter->setPoolSize(static_cast<int>(poolSize));

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::setGravity(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        SQFloat gravity;
        sq_getfloat(vm, 2, &gravity);

        emitter->setGravity(static_cast<float>(gravity));

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::setRenderQueueGroup(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        SQInteger group;
        sq_getinteger(vm, 2, &group);

        emitter->setRenderQueueGroup(static_cast<Ogre::uint32>(group));

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::emit(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        SQFloat x, y, z, velX, velY, velZ, startScale, endScale;
        SQInteger maxLifetime;
        sq_getfloat(vm, 2, &x);
        sq_getfloat(vm, 3, &y);
        sq_getfloat(vm, 4, &z);
        sq_getfloat(vm, 5, &velX);
        sq_getfloat(vm, 6, &velY);
        sq_getfloat(vm, 7, &velZ);
        sq_getinteger(vm, 8, &maxLifetime);
        sq_getfloat(vm, 9, &startScale);
        sq_getfloat(vm, 10, &endScale);

        //Optional rotation parameters (default to 0)
        SQFloat rotX = 0.0f, rotY = 0.0f, rotZ = 0.0f;
        SQInteger top = sq_gettop(vm);
        if(top >= 11) sq_getfloat(vm, 11, &rotX);
        if(top >= 12) sq_getfloat(vm, 12, &rotY);
        if(top >= 13) sq_getfloat(vm, 13, &rotZ);

        emitter->emit(
            static_cast<float>(x), static_cast<float>(y), static_cast<float>(z),
            static_cast<float>(velX), static_cast<float>(velY), static_cast<float>(velZ),
            static_cast<int>(maxLifetime),
            static_cast<float>(startScale), static_cast<float>(endScale),
            static_cast<float>(rotX), static_cast<float>(rotY), static_cast<float>(rotZ)
        );

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::update(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        emitter->update();

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::clear(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        emitter->clear();

        return 0;
    }

    SQInteger MeshParticleEmitterUserData::destroy(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MeshParticleEmitter* emitter;
        SCRIPT_ASSERT_RESULT(readMeshParticleEmitterFromUserData(vm, 1, &emitter));

        emitter->destroy();

        return 0;
    }

    void MeshParticleEmitterUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, addMeshVariant, "addMeshVariant", 2, ".s");
        AV::ScriptUtils::addFunction(vm, setPoolSize, "setPoolSize", 2, ".i");
        AV::ScriptUtils::addFunction(vm, setGravity, "setGravity", 2, ".n");
        AV::ScriptUtils::addFunction(vm, setRenderQueueGroup, "setRenderQueueGroup", 2, ".i");
        AV::ScriptUtils::addFunction(vm, emit, "emit", -10, ".nnnnnnnnn");
        AV::ScriptUtils::addFunction(vm, update, "update");
        AV::ScriptUtils::addFunction(vm, clear, "clear");
        AV::ScriptUtils::addFunction(vm, destroy, "destroy");

        sq_resetobject(&MeshParticleEmitterDelegateTableObject);
        sq_getstackobj(vm, -1, &MeshParticleEmitterDelegateTableObject);
        sq_addref(vm, &MeshParticleEmitterDelegateTableObject);
        sq_pop(vm, 1);
    }

}
