#pragma once

#include "Scripting/Script/BaseScript.h"
#include <map>
#include <vector>
#include <string>
#include "System/EnginePrerequisites.h"
#include "MapGenScriptVM.h"

namespace ProceduralExplorationGameCore{
    class EntityCallbackScript;
    class ScriptManager;

    typedef SQInteger(*PopulateFunction)(HSQUIRRELVM vm);
    typedef SQInteger(*ReturnFunction)(HSQUIRRELVM vm);

    /**
     A class to encapsulate callback functionality of scripts.
     Callback scripts are intended to simply contain a list of functions which can be executed individually by this class.
     It allows precise control over how these functions are called, and what parameters are passed to them.

     Generally callback scripts should be created using the ScriptManager class, as this allows automatic managing on script instance lifetime.
     */
    class CallbackScript : public AV::BaseScript{
        friend EntityCallbackScript;

    public:
        CallbackScript(HSQUIRRELVM vm);
        CallbackScript();
        ~CallbackScript();

        /**
         Setup the script by specifying a path to a squirrel file.
         This function is responsible for parsing the contents of the file, and preparing the closures for execution.
         The script must first be initalised before this can be called.

         This function will resolve the res path of the script.

         @param path
         A res path to the script that should be processed.
         @return
         Whether or not the preparation work was successful.
         */
        bool prepare(const std::string& path);
        /**
        Similar to the prepare function, although this function does not resolve the res path.
        Use this function as an optimisation if the path has been resolved elsewhere.
        */
        bool prepareRaw(const std::string& path);
        /**
         Initialise this script with a vm. Either this or the vm constructor needs to be called before the script can be used.
         */
        void initialise(MapGenScriptVM* vm);

        /**
         Call a callback function.
         This function expects the script to have been prepared and initialised before this will work.

         @param functionName
         The name of the callback that should be executed.
         @param func
         A stack populating function.
         During part of the call procedure the squirrel stack needs to be prepared with the appropriate parameter variables.
         However these variables are often very specific.
         So this function pointer is used to populate the stack however the user needs, meaning any sort of variables can be passed in.
         If the called function takes no parameters then this can just be left as a null pointer.
         @return
         Whether or not this call was successful.
         */
        bool call(const std::string& functionName, PopulateFunction func = 0, ReturnFunction retFunc = 0);

        bool call(int closureId, PopulateFunction func = 0, ReturnFunction retFunc = 0);

        /**
         Get the int id of a callback.
         This id can later be used for more efficient calling.

         @return
         A positive number if a callback with that name was found. -1 if not.
         */
        int getCallbackId(const std::string& functionName);

        /**
        Retrieve the number of parameters associated with a closure.
        This value includes the invisible 'this' parameter.
        */
        AV::uint8 getParamsForCallback(int closureId) const;

        /**
         Release this script and all the resources held by it.
         */
        void release();

        ScriptManager* mCreatorClass = 0;
        unsigned int mScriptId = 0;

    private:
        HSQUIRRELVM mVm;
        MapGenScriptVM* mVMObject;
        HSQOBJECT mMainClosure;
        HSQOBJECT mMainTable;

        bool _compileMainClosure(const std::string& path);
        bool _createMainTable();
        bool _callMainClosure();
        bool _parseClosureTable();

        bool _call(int closureId, PopulateFunction func, ReturnFunction retFunc);

        bool mPrepared = false;
        bool mInitialised = false;

        //Closure and the number of parameters it contains.
        typedef std::pair<HSQOBJECT, AV::uint8> ClosureEntry;
        std::vector<ClosureEntry> mClosures;
        #ifdef DEBUGGING_TOOLS
            std::vector<std::string> mClosureNames;
        #endif
        std::map<std::string, int> mClosureMap;
    };
}
