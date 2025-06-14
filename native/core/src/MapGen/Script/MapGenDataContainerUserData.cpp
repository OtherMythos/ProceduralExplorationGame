#include "MapGenDataContainerUserData.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    SQObject MapGenDataContainerUserData::MapGenDataContainerDelegateTableObject;

    //TODO properly define this somewhere else.
    static void* MapGenDataContainerUserDataTypeTag = reinterpret_cast<void*>(0xFF);

    void MapGenDataContainerUserData::MapGenDataContainerToUserData(HSQUIRRELVM vm, MapGenDataContainer* mapData){
        MapGenDataContainer** pointer = (MapGenDataContainer**)sq_newuserdata(vm, sizeof(MapGenDataContainer*));
        *pointer = mapData;

        sq_pushobject(vm, MapGenDataContainerDelegateTableObject);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, MapGenDataContainerUserDataTypeTag);
    }

    AV::UserDataGetResult MapGenDataContainerUserData::readMapGenDataContainerFromUserData(HSQUIRRELVM vm, SQInteger stackInx, MapGenDataContainer** outMapData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != MapGenDataContainerUserDataTypeTag){
            *outMapData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        MapGenDataContainer** p = (MapGenDataContainer**)pointer;
        *outMapData = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger MapGenDataContainerUserData::setValue(HSQUIRRELVM vm){
        MapGenDataContainer* outMapData;
        SCRIPT_ASSERT_RESULT(readMapGenDataContainerFromUserData(vm, 1, &outMapData));

        const SQChar *key;
        sq_getstring(vm, 2, &key);

        MapDataEntry entry;

        SQObjectType t = sq_gettype(vm, 3);
        if(t == OT_INTEGER){
            SQInteger val;
            sq_getinteger(vm, 3, &val);
            AV::uint32 v = static_cast<AV::uint32>(val);
            entry.value.uint32 = v;
            entry.type = MapDataEntryType::UINT32;

            outMapData->setEntry(key, entry);
        }else{
            assert(false);
        }

        return 0;
    }

    SQInteger MapGenDataContainerUserData::getValue(HSQUIRRELVM vm){
        MapGenDataContainer* outMapData;
        SCRIPT_ASSERT_RESULT(readMapGenDataContainerFromUserData(vm, 1, &outMapData));

        const SQChar *key;
        sq_getstring(vm, 2, &key);

        MapDataEntry outEntry;
        MapDataReadResult result = outMapData->readEntry(key, &outEntry);
        if(result == MapDataReadResult::NOT_FOUND){
            std::string val = std::string("The requested value '") + key + "' was not found.'";
            return sq_throwerror(vm, val.c_str());
        }


        if(outEntry.type == MapDataEntryType::UINT32){
            sq_pushinteger(vm, outEntry.value.uint32);
        }
        else if(outEntry.type == MapDataEntryType::WORLD_POINT){
            sq_pushinteger(vm, outEntry.value.worldPoint);
        }
        else if(outEntry.type == MapDataEntryType::VOID_PTR){
            assert(false);
        }
        else if(outEntry.type == MapDataEntryType::SIZE_TYPE){
            sq_pushinteger(vm, outEntry.value.size);
        }
        else{
            assert(false);
        }

        return 1;
    }

    void MapGenDataContainerUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, getValue, "_get");
        AV::ScriptUtils::addFunction(vm, setValue, "_set");

        sq_resetobject(&MapGenDataContainerDelegateTableObject);
        sq_getstackobj(vm, -1, &MapGenDataContainerDelegateTableObject);
        sq_addref(vm, &MapGenDataContainerDelegateTableObject);
        sq_pop(vm, 1);
    }
}
