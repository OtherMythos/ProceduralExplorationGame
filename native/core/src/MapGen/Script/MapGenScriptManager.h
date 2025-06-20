#pragma once

#include <string>

namespace AV{
    class CallbackScript;
}

namespace ProceduralExplorationGameCore{
    class MapGenScriptVM;
    class CallbackScript;

    /**
    A class to manage lifetimes for scripting state relating to MapGen.
    */
    class MapGenScriptManager{
    public:
        MapGenScriptManager();
        ~MapGenScriptManager();

        CallbackScript* loadScript(const std::string& scriptPath);

    private:
        MapGenScriptVM* mVM;

    public:
        MapGenScriptVM* getScriptVM() { return mVM; }
    };

}
