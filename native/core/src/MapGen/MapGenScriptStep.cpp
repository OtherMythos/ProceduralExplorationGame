#include "MapGenScriptStep.h"

#include "Script/CallbackScript.h"

#include "MapGen/Script/MapGenDataContainerUserData.h"
#include "MapGen/MapGenScriptClient.h"
#include "MapGen/MapGenDataContainer.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

//TODO this should not be here
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptStep::MapGenScriptStep(const std::string& stepName, MapGenScriptClient* parentClient, CallbackScript* script) : MapGenStep(stepName), mParentClient(parentClient), mScript(script){

    }

    MapGenScriptStep::~MapGenScriptStep(){

    }

    static ExplorationMapData* populateMapData = 0;
    static const ExplorationMapInputData* populateMapInputData = 0;
    static SQObject clientTable;
    SQInteger populateProcessStep(HSQUIRRELVM vm){
        assert(populateMapData);
        assert(populateMapInputData);

        const MapGenDataContainer* inputContainer = dynamic_cast<const MapGenDataContainer*>(populateMapInputData);
        MapGenDataContainerUserData::MapGenDataContainerToUserData<const MapGenDataContainer*, true>(vm, inputContainer);

        //sq_pushinteger(vm, 1);
        MapGenDataContainer* container = dynamic_cast<MapGenDataContainer*>(populateMapData);
        MapGenDataContainerUserData::MapGenDataContainerToUserData<MapGenDataContainer*, false>(vm, container);

        sq_pushobject(vm, clientTable);

        populateMapData = 0;
        populateMapInputData = 0;
        sq_resetobject(&clientTable);

        return 4;
    }

    void MapGenScriptStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        populateMapData = mapData;
        populateMapInputData = input;
        clientTable = mParentClient->getClientTable();
        mScript->call("processStep", populateProcessStep);
    }
}
