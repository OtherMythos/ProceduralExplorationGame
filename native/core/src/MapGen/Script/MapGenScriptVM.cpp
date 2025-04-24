#include "MapGenScriptVM.h"

#include "GameCoreLogger.h"

#include "MapGen/Script/MapGenNamespace.h"

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

    void MapGenScriptVM::setup(){
        mVM = sq_open(1024);

        sq_setprintfunc(mVM, printfunc, NULL);


        sq_pushroottable(mVM);
        setupNamespace("_mapGen", MapGenNamespace::setupNamespace);

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
