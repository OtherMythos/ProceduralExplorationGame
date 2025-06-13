#include "MapGenScriptStep.h"

#include "Script/CallbackScript.h"

#include "MapGen/Script/MapGenDataContainerUserData.h"
#include "MapGen/MapGenDataContainer.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptStep::MapGenScriptStep(const std::string& stepName, CallbackScript* script) : MapGenStep(stepName), mScript(script){

    }

    MapGenScriptStep::~MapGenScriptStep(){

    }

    static ExplorationMapData* populateMapData = 0;
    SQInteger populateProcessStep(HSQUIRRELVM vm){
        assert(populateMapData);

        //sq_pushinteger(vm, 1);
        MapGenDataContainer* container = dynamic_cast<MapGenDataContainer*>(populateMapData);
        MapGenDataContainerUserData::MapGenDataContainerToUserData(vm, container);

        populateMapData = 0;

        return 2;
    }

    void MapGenScriptStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        populateMapData = mapData;
        mScript->call("processStep", populateProcessStep);
    }
}
