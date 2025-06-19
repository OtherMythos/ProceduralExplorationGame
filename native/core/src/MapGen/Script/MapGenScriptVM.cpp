#include "MapGenScriptVM.h"

#include "GameCoreLogger.h"

#include "MapGen/Script/MapGenNamespace.h"
#include "MapGen/Script/MapGenDataContainerUserData.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptVM::MapGenScriptVM(){

    }

    MapGenScriptVM::~MapGenScriptVM(){

    }

    void printfunc(HSQUIRRELVM v, const SQChar *s, ...){
        char buffer[256];
        va_list args;
        va_start (args, s);
        vsnprintf (buffer, 256, s, args);
        va_end (args);

        GAME_CORE_INFO("{}", buffer);
    }

    SQInteger errorHandler(HSQUIRRELVM vm){
        const SQChar* sqErr;
        sq_getlasterror(vm);
        sq_tostring(vm, -1);
        sq_getstring(vm, -1, &sqErr);
        sq_pop(vm, 1);

        SQStackInfos si;
        sq_stackinfos(vm, 1, &si);

        static const std::string separator(10, '=');

        GAME_CORE_ERROR(separator);

        GAME_CORE_ERROR("Error during script execution.");
        GAME_CORE_ERROR(sqErr);
        GAME_CORE_ERROR("In file {}", si.source);
        GAME_CORE_ERROR("    on line {}", si.line);
        GAME_CORE_ERROR("of function {}", si.funcname);

        GAME_CORE_ERROR(separator);

        return 0;
    }

    void MapGenScriptVM::setup(){
        mVM = sq_open(1024);

        sq_setprintfunc(mVM, printfunc, NULL);

        sq_newclosure(mVM, errorHandler, 0);
        sq_seterrorhandler(mVM);

        sq_pushroottable(mVM);
        setupNamespace("_mapGen", MapGenNamespace::setupNamespace);

        MapGenDataContainerUserData::setupDelegateTable<const MapGenDataContainer*, true>(mVM);
        MapGenDataContainerUserData::setupDelegateTable<MapGenDataContainer*, false>(mVM);

    }

    void MapGenScriptVM::setupNamespace(const char* namespaceName, NamespaceSetupFunction setupFunc){
        sq_pushstring(mVM, _SC(namespaceName), -1);
        sq_newtable(mVM);

        setupFunc(mVM);

        sq_newslot(mVM, -3 , false);
    }

    HSQUIRRELVM MapGenScriptVM::getVM(){
        return mVM;
    }

    bool MapGenScriptVM::callClosure(HSQOBJECT closure, const HSQOBJECT* context, PopulateFunction func, ReturnFunction retFunc){
        sq_pushobject(mVM, closure);
        if(context){
            sq_pushobject(mVM, *context);
        }else{
            sq_pushroottable(mVM);
        }

        SQInteger paramCount = 1;
        if(func){
            paramCount = (func)(mVM);
        }

        if(SQ_FAILED(sq_call(mVM, paramCount, true, true))){
            return false;
        }

        if(retFunc){
            (retFunc)(mVM);
        }else{
            sq_poptop(mVM);
        }

        sq_pop(mVM, 1);

        return true;
    }
}
