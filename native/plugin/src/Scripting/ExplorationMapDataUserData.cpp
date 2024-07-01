#include "ExplorationMapDataUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGamePlugin{

    SQObject ExplorationMapDataUserData::ExplorationMapDataDelegateTableObject;

    void ExplorationMapDataUserData::ExplorationMapDataToUserData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapData* data){
        ProceduralExplorationGameCore::ExplorationMapData** pointer = (ProceduralExplorationGameCore::ExplorationMapData**)sq_newuserdata(vm, sizeof(ProceduralExplorationGameCore::ExplorationMapData*));
        *pointer = data;

        sq_pushobject(vm, ExplorationMapDataDelegateTableObject);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, ExplorationMapDataTypeTag);
        sq_setreleasehook(vm, -1, ExplorationMapDataObjectReleaseHook);
    }

    AV::UserDataGetResult ExplorationMapDataUserData::readExplorationMapDataFromUserData(HSQUIRRELVM vm, SQInteger stackInx, ProceduralExplorationGameCore::ExplorationMapData** outData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != ExplorationMapDataTypeTag){
            *outData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        *outData = *((ProceduralExplorationGameCore::ExplorationMapData**)pointer);

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger ExplorationMapDataUserData::ExplorationMapDataObjectReleaseHook(SQUserPointer p, SQInteger size){
        ProceduralExplorationGameCore::ExplorationMapData** ptr = static_cast<ProceduralExplorationGameCore::ExplorationMapData**>(p);
        delete *ptr;

        return 0;
    }

    SQInteger ExplorationMapDataUserData::setNamedConstant(HSQUIRRELVM vm){
        return 0;
    }

    void ExplorationMapDataUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, setNamedConstant, "setNamedConstant", 3, ".s i|f|b|u|x");

        sq_resetobject(&ExplorationMapDataDelegateTableObject);
        sq_getstackobj(vm, -1, &ExplorationMapDataDelegateTableObject);
        sq_addref(vm, &ExplorationMapDataDelegateTableObject);
        sq_pop(vm, 1);
    }
}
