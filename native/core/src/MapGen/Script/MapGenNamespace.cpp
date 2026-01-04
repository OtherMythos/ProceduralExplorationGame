#include "MapGenNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"

#include "PluginBaseSingleton.h"
#include "MapGen/MapGen.h"
#include "System/Util/PathUtils.h"
#include "System/Util/FileSystemHelper.h"

#include "rapidjson/filereadstream.h"
#include "rapidjson/error/en.h"

#include "MapGen/MapGenScriptStep.h"
#include "MapGen/MapGenScriptClient.h"
#include "MapGen/Script/MapGenScriptManager.h"

#include "GameCoreLogger.h"

namespace ProceduralExplorationGameCore{

    SQInteger MapGenNamespace::registerStep(HSQUIRRELVM vm){
        const SQChar *stepName;
        sq_getstring(vm, 3, &stepName);

        std::string outPath;
        const SQChar *scriptPath;
        sq_getstring(vm, 4, &scriptPath);
        AV::formatResToPath(scriptPath, outPath);

        MapGen* mapGen = PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();
        ProceduralExplorationGameCore::CallbackScript* script = manager->loadScript(outPath);
        if(!script){
            std::string e = std::string("Error parsing script at path ") + outPath;
            return sq_throwerror(vm, e.c_str());
        }

        MapGenClient* client = mapGen->getCurrentCollectingMapGenClient();
        MapGenScriptClient* scriptClient = dynamic_cast<MapGenScriptClient*>(client);
        MapGenScriptStep* step = new MapGenScriptStep(stepName, scriptClient, script);

        int finalIdx = 0;
        if(sq_gettype(vm, 2) == OT_STRING){
            const SQChar *markerName;
            sq_getstring(vm, 2, &markerName);
            finalIdx = mapGen->registerStep(markerName, step);
        }else{
            SQInteger idx;
            sq_getinteger(vm, 2, &idx);
            finalIdx = static_cast<int>(idx);
            mapGen->registerStep(finalIdx, step);
        }

        GAME_CORE_INFO("Succesfully registered MapGen step '{}' at idx {}", stepName, finalIdx);

        return 0;
    }

    void MapGenNamespace::_readJsonValue(HSQUIRRELVM vm, const rapidjson::Value& value){
        using namespace rapidjson;
        Type t=value.GetType();
        switch(t){
            case kNullType: sq_pushnull(vm); break;
            case kFalseType: sq_pushbool(vm, false); break;
            case kTrueType: sq_pushbool(vm, true); break;
            case kNumberType:{
                if(value.IsInt()){
                    sq_pushinteger(vm, value.GetInt());
                }
                else if(value.IsDouble()){
                    sq_pushfloat(vm, value.GetDouble());
                }
                break;
            }
            case kStringType:{
                sq_pushstring(vm, value.GetString(), value.GetStringLength());
                break;
            }
            case kObjectType:{
                sq_newtable(vm);
                for(Value::ConstMemberIterator memItr=value.MemberBegin(); memItr!=value.MemberEnd(); ++memItr){
                    const GenericMember<UTF8<>, MemoryPoolAllocator<>>& member=*memItr;
                    _readJsonObject(vm, member);
                }
                break;
            }
            case kArrayType:{
                sq_newarray(vm, 0);
                int count=0;
                for(Value::ConstValueIterator memItr=value.Begin(); memItr!=value.End(); ++memItr){
                    _readJsonValue(vm, *memItr);
                    sq_arrayappend(vm, -2);
                    count++;
                }
                break;
            }
            default:{
                assert(false);
            }
        }
    }

    void MapGenNamespace::_readJsonObject(HSQUIRRELVM vm, const rapidjson::GenericMember<rapidjson::UTF8<>, rapidjson::MemoryPoolAllocator<>>& value){
        using namespace rapidjson;

        sq_pushstring(vm, value.name.GetString(), value.name.GetStringLength());
        _readJsonValue(vm, value.value);
        sq_newslot(vm, -3, SQFalse);
    }

    SQInteger MapGenNamespace::readJSONAsTable(HSQUIRRELVM vm){
        const SQChar *path;
        sq_getstring(vm, 2, &path);

        std::string outString;
        AV::formatResToPath(path, outString);

        using namespace rapidjson;

        Document d;
        if(!AV::FileSystemHelper::setupRapidJsonDocument(outString, &d)){
            return sq_throwerror(vm, "Unable to parse json file.");
        }

        if(d.IsArray()){
            //Handle array root
            sq_newarray(vm, 0);
            for(Value::ConstValueIterator arrayItr=d.Begin(); arrayItr!=d.End(); ++arrayItr){
                _readJsonValue(vm, *arrayItr);
                sq_arrayappend(vm, -2);
            }
        }else if(d.IsObject()){
            //Handle object root
            sq_newtable(vm);
            for(Value::ConstMemberIterator memItr=d.MemberBegin(); memItr!=d.MemberEnd(); ++memItr){
                const GenericMember<UTF8<>, MemoryPoolAllocator<>>& member=*memItr;

                _readJsonObject(vm, member);
            }
        }else{
            return sq_throwerror(vm, "JSON root must be an object or array.");
        }

        return 1;
    }

    SQInteger MapGenNamespace::pathExists(HSQUIRRELVM vm){
        const SQChar *path;
        sq_getstring(vm, 2, &path);

        std::string outString;
        AV::formatResToPath(path, outString);

        bool exists = AV::fileExists(outString);
        sq_pushbool(vm, exists);

        return 1;
    }

    void MapGenNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, registerStep, "registerStep", 4, ".i|sss");
        AV::ScriptUtils::addFunction(vm, readJSONAsTable, "readJSONAsTable", 2, ".s");
        AV::ScriptUtils::addFunction(vm, pathExists, "exists", 2, ".s");
    }

}
