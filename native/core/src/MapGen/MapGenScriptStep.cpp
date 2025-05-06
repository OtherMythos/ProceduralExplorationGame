#include "MapGenScriptStep.h"

#include "Script/CallbackScript.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptStep::MapGenScriptStep(const std::string& stepName, CallbackScript* script) : MapGenStep(stepName), mScript(script){

    }

    MapGenScriptStep::~MapGenScriptStep(){

    }

    void MapGenScriptStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        mScript->call("processStep");
    }
}
