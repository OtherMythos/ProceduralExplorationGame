#include "DataPointFileUserData.h"

#include "ProceduralExplorationGameCorePluginScriptTypeTags.h"

#include <sqstdblob.h>
#include <vector>

#include "System/Util/PathUtils.h"

#include "VisitedPlaces/DataPointFileHandler.h"

#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Graphics/MeshUserData.h"
#include "Scripting/ScriptNamespace/Classes/Ogre/Scene/RayUserData.h"
#include "Scripting/ScriptNamespace/Classes/Vector3UserData.h"

namespace ProceduralExplorationGamePlugin{

    SQObject DataPointFileParserUserData::DataPointFileDelegateTableObject;

    void DataPointFileParserUserData::dataPointFileHandlerToUserData(HSQUIRRELVM vm, WrappedDataPointFile* data){
        WrappedDataPointFile** pointer = (WrappedDataPointFile**)sq_newuserdata(vm, sizeof(WrappedDataPointFile*));
        *pointer = data;

        sq_pushobject(vm, DataPointFileDelegateTableObject);
        sq_setdelegate(vm, -2); //This pops the pushed table
        sq_settypetag(vm, -1, DataPointFileTypeTag);
        sq_setreleasehook(vm, -1, DataPointFileHandlerReleaseHook);
    }

    AV::UserDataGetResult DataPointFileParserUserData::readDataPointFileHandlerFromUserData(HSQUIRRELVM vm, SQInteger stackInx, WrappedDataPointFile** outData){
        SQUserPointer pointer, typeTag;
        if(SQ_FAILED(sq_getuserdata(vm, stackInx, &pointer, &typeTag))) return AV::USER_DATA_GET_INCORRECT_TYPE;
        if(typeTag != DataPointFileTypeTag){
            *outData = 0;
            return AV::USER_DATA_GET_TYPE_MISMATCH;
        }

        WrappedDataPointFile** p = (WrappedDataPointFile**)pointer;
        *outData = *p;

        return AV::USER_DATA_GET_SUCCESS;
    }

    SQInteger DataPointFileParserUserData::DataPointFileHandlerReleaseHook(SQUserPointer p, SQInteger size){
        WrappedDataPointFile** ptr = static_cast<WrappedDataPointFile**>(p);
        delete *ptr;

        return 0;
    }

    SQInteger DataPointFileParserUserData::readFile(HSQUIRRELVM vm){
        WrappedDataPointFile* dataFile;
        SCRIPT_CHECK_RESULT(readDataPointFileHandlerFromUserData(vm, 1, &dataFile));

        const SQChar *path;
        sq_getstring(vm, 2, &path);

        std::string outPath;
        AV::formatResToPath(path, outPath);

        dataFile->file->readData(dataFile->data, outPath);

        return 1;
    }

    SQInteger DataPointFileParserUserData::getNumDataPoints(HSQUIRRELVM vm){
        WrappedDataPointFile* dataFile;
        SCRIPT_CHECK_RESULT(readDataPointFileHandlerFromUserData(vm, 1, &dataFile));

        SQInteger size = dataFile->data.size();
        sq_pushinteger(vm, size);

        return 1;
    }

    SQInteger DataPointFileParserUserData::getDataPointAt(HSQUIRRELVM vm){
        WrappedDataPointFile* dataFile;
        SCRIPT_CHECK_RESULT(readDataPointFileHandlerFromUserData(vm, 1, &dataFile));

        SQInteger idx = 0;
        sq_getinteger(vm, 2, &idx);

        if(sq_getsize(vm, -2) > 2) return sq_throwerror(vm, "The provided array was too small.");

        if(idx < 0 || idx >= dataFile->data.size()){
            return sq_throwerror(vm, "Invalid idx");
        }
        const ProceduralExplorationGameCore::DataPointData& e = dataFile->data[idx];
        sq_pushinteger(vm, 0);
        AV::Vector3UserData::vector3ToUserData(vm, Ogre::Vector3(e.x, e.y, e.z));
        sq_rawset(vm, 3);
        sq_pushinteger(vm, 1);
        sq_pushinteger(vm, e.wrapped);
        sq_rawset(vm, 3);

        return 0;
    }

    void DataPointFileParserUserData::setupDelegateTable(HSQUIRRELVM vm){
        sq_newtable(vm);

        AV::ScriptUtils::addFunction(vm, readFile, "readFile", 2, ".s");
        AV::ScriptUtils::addFunction(vm, getNumDataPoints, "getNumDataPoints");
        AV::ScriptUtils::addFunction(vm, getDataPointAt, "getDataPointAt", 3, ".ia");

        sq_resetobject(&DataPointFileDelegateTableObject);
        sq_getstackobj(vm, -1, &DataPointFileDelegateTableObject);
        sq_addref(vm, &DataPointFileDelegateTableObject);
        sq_pop(vm, 1);
    }
}
