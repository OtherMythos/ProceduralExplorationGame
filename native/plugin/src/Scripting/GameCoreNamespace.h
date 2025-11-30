#pragma once

#include <squirrel.h>

namespace ProceduralExplorationGameCore{
    class MapGen;
    class VisitedPlacesParser;
    class ExplorationMapInputData;
}

namespace ProceduralExplorationGamePlugin{


    class GameCoreNamespace{
    public:
        GameCoreNamespace() = delete;

        static void setupNamespace(HSQUIRRELVM vm);

    private:
        static SQInteger getGameCoreVersion(HSQUIRRELVM vm);
        static SQInteger fillBufferWithMapLean(HSQUIRRELVM vm);
        static SQInteger fillBufferWithMapComplex(HSQUIRRELVM vm);
        static SQInteger tableToExplorationMapInputData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapInputData* data);
        static SQInteger setRegionFound(HSQUIRRELVM vm);
        static SQInteger getRegionFound(HSQUIRRELVM vm);
        static SQInteger setNewMapData(HSQUIRRELVM vm);
        static SQInteger createTerrainFromMapData(HSQUIRRELVM vm);
        static SQInteger createCollisionDetectionWorld(HSQUIRRELVM vm);
        static SQInteger setHlmsFlagForDatablock(HSQUIRRELVM vm);
        static SQInteger writeFlagsToItem(HSQUIRRELVM vm);
        static SQInteger setCustomPassBufferValue(HSQUIRRELVM vm);
        static SQInteger setCameraForNode(HSQUIRRELVM vm);
        static SQInteger setPassBufferFogValue(HSQUIRRELVM vm);
        static SQInteger setPassBufferFogStartEnd(HSQUIRRELVM vm);

        static SQInteger disableShadows(HSQUIRRELVM vm);
        static SQInteger setupCompositorDefs(HSQUIRRELVM vm);

        static SQInteger createDataPointFileParser(HSQUIRRELVM vm);

        static SQInteger beginMapGen(HSQUIRRELVM vm);
        static SQInteger getMapGenStage(HSQUIRRELVM vm);
        static SQInteger checkClaimMapGen(HSQUIRRELVM vm);
        static SQInteger getTotalMapGenStages(HSQUIRRELVM vm);
        static SQInteger getNameForMapGenStage(HSQUIRRELVM vm);
        static SQInteger setupCollisionDataForWorld(HSQUIRRELVM vm);
        static SQInteger registerVoxel(HSQUIRRELVM vm);
        static SQInteger getDummyMapGen(HSQUIRRELVM vm);
        static SQInteger loadOverworld(HSQUIRRELVM vm);

        static SQInteger setMapsDirectory(HSQUIRRELVM vm);

        static SQInteger beginParseVisitedLocation(HSQUIRRELVM vm);
        static SQInteger checkClaimParsedVisitedLocation(HSQUIRRELVM vm);
        static SQInteger createVoxMeshItem(HSQUIRRELVM vm);
        static SQInteger registerMapGenClient(HSQUIRRELVM vm);
        static SQInteger recollectMapGenSteps(HSQUIRRELVM vm);
        static SQInteger destroyMapData(HSQUIRRELVM vm);

        static SQInteger deepCopyToMapGenVM(HSQUIRRELVM vm);

        static SQInteger voxeliseMeshForVoxelData(HSQUIRRELVM vm);

        static SQInteger insertParsedSceneFileVoxMeshGetAnimInfo(HSQUIRRELVM vm);
        static SQInteger insertParsedSceneFileVoxMeshGetAnimInfoOverworld(HSQUIRRELVM vm);

        static SQInteger dumpSceneToObj(HSQUIRRELVM vm);

        static SQInteger triggerLightHapticFeedback(HSQUIRRELVM vm);
        static SQInteger triggerMediumHapticFeedback(HSQUIRRELVM vm);
        static SQInteger triggerHeavyHapticFeedback(HSQUIRRELVM vm);
        static SQInteger triggerSelectionHapticFeedback(HSQUIRRELVM vm);
        static SQInteger triggerNotificationHapticFeedback(HSQUIRRELVM vm);

        static ProceduralExplorationGameCore::VisitedPlacesParser* currentVisitedPlacesParser;

        static SQInteger update(HSQUIRRELVM vm);
    };

};
