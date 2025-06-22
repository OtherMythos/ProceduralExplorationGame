#include "MapGenDataContainerUserData.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    template void ProceduralExplorationGameCore::MapGenDataContainerUserData::setupDelegateTable<ProceduralExplorationGameCore::MapGenDataContainer const*, true>(HSQUIRRELVM);
    template void ProceduralExplorationGameCore::MapGenDataContainerUserData::setupDelegateTable<ProceduralExplorationGameCore::MapGenDataContainer*, false>(HSQUIRRELVM);

    template void MapGenDataContainerUserData::MapGenDataContainerToUserData<const MapGenDataContainer*, true>(SQVM*, const MapGenDataContainer*);
    template void MapGenDataContainerUserData::MapGenDataContainerToUserData<MapGenDataContainer*, false>(SQVM*, MapGenDataContainer*);

    SQObject MapGenDataContainerUserData::MapGenDataContainerDelegateTableObject;
    SQObject MapGenDataContainerUserData::MapGenDataContainerConstDelegateTableObject;

    //TODO properly define this somewhere else.
    static void* MapGenDataContainerUserDataTypeTag = reinterpret_cast<void*>(0xFF);
    static void* MapGenDataContainerConstUserDataTypeTag = reinterpret_cast<void*>(0xFF + 1);

    template <typename T, bool B>
    void MapGenDataContainerUserData::MapGenDataContainerToUserData(HSQUIRRELVM vm, T mapData){
        T* pointer = (T*)sq_newuserdata(vm, sizeof(T));
        *pointer = mapData;

        if(B){
            sq_pushobject(vm, MapGenDataContainerConstDelegateTableObject);
            sq_setdelegate(vm, -2);
            sq_settypetag(vm, -1, MapGenDataContainerConstUserDataTypeTag);
        }else{
            sq_pushobject(vm, MapGenDataContainerDelegateTableObject);
            sq_setdelegate(vm, -2);
            sq_settypetag(vm, -1, MapGenDataContainerUserDataTypeTag);
        }
    }

    template <typename T>
    AV::UserDataGetResult MapGenDataContainerUserData::readMapGenDataContainerFromUserData(HSQUIRRELVM vm, SQInteger stackInx, T* outMapData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != MapGenDataContainerUserDataTypeTag && typeTag != MapGenDataContainerConstUserDataTypeTag){
            *outMapData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        T* p = (T*)pointer;
        *outMapData = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger MapGenDataContainerUserData::setValueConst(HSQUIRRELVM vm){
        return sq_throwerror(vm, "This object is const and cannot be written to.");
    }

    SQInteger MapGenDataContainerUserData::setValue(HSQUIRRELVM vm){
        MapGenDataContainer* outMapData;
        SCRIPT_ASSERT_RESULT(readMapGenDataContainerFromUserData<MapGenDataContainer*>(vm, 1, &outMapData));

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

    template <typename T>
    SQInteger MapGenDataContainerUserData::getValue(HSQUIRRELVM vm){
        T outMapData;
        SCRIPT_ASSERT_RESULT(readMapGenDataContainerFromUserData<T>(vm, 1, &outMapData));

        const SQChar *key;
        sq_getstring(vm, 2, &key);

        MapDataEntry outEntry;
        MapDataReadResult result = outMapData->readEntry(key, &outEntry);
        if(result == MapDataReadResult::NOT_FOUND){
            std::string val = std::string("The requested value '") + key + "' was not found.";
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

    template <typename T>
    SQInteger MapGenDataContainerUserData::voxValueForCoord(HSQUIRRELVM vm){
        MapGenDataContainer* outMapData;
        SCRIPT_ASSERT_RESULT(readMapGenDataContainerFromUserData<MapGenDataContainer*>(vm, 1, &outMapData));

        ExplorationMapData* mapData = static_cast<ExplorationMapData*>(outMapData);

        SQInteger x, y;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);

        const AV::uint8* val = VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));

        AV::uint32 outVal = *(reinterpret_cast<const AV::uint32*>(val));
        sq_pushinteger(vm, static_cast<SQInteger>(outVal));

        return 1;
    }

    SQInteger MapGenDataContainerUserData::writeVoxValueForCoord(HSQUIRRELVM vm){
        MapGenDataContainer* outMapData;
        SCRIPT_ASSERT_RESULT(readMapGenDataContainerFromUserData<MapGenDataContainer*>(vm, 1, &outMapData));

        ExplorationMapData* mapData = static_cast<ExplorationMapData*>(outMapData);

        SQInteger x, y, val;
        sq_getinteger(vm, 2, &x);
        sq_getinteger(vm, 3, &y);
        sq_getinteger(vm, 4, &val);

        AV::uint8* ptr = VOX_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));

        AV::uint32 writeVal = static_cast<AV::uint32>(val);
        *(reinterpret_cast<AV::uint32*>(ptr)) = writeVal;

        return 0;
    }

    template <typename T>
    void MapGenDataContainerUserData::_defineBaseFunctions(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, getValue<T>, "_get");
        //AV::ScriptUtils::addFunction(vm, voxValueForCoord<T>, "voxValueForCoord", 3, ".ii");
    }

    template <typename T, bool B>
    void MapGenDataContainerUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        SQObject* targetTable = 0;

        if(B){
            targetTable = &MapGenDataContainerConstDelegateTableObject;

            _defineBaseFunctions<T>(vm);
            AV::ScriptUtils::addFunction(vm, setValueConst, "_set");
        }else{
            targetTable = &MapGenDataContainerDelegateTableObject;

            _defineBaseFunctions<T>(vm);
            AV::ScriptUtils::addFunction(vm, setValue, "_set");
            //AV::ScriptUtils::addFunction(vm, writeVoxValueForCoord, "writeVoxValueForCoord", 4, ".iii");
        }

        sq_resetobject(targetTable);
        sq_getstackobj(vm, -1, targetTable);
        sq_addref(vm, targetTable);
        sq_pop(vm, 1);
    }
}
