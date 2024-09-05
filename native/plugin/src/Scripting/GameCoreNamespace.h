#pragma once

#include <squirrel.h>

namespace ProceduralExplorationGameCore{
    class MapGen;
    class VisitedPlacesParser;
    struct ExplorationMapInputData;
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
        static SQInteger tableToExplorationMapData(HSQUIRRELVM vm);
        static SQInteger tableToExplorationMapInputData(HSQUIRRELVM vm, ProceduralExplorationGameCore::ExplorationMapInputData* data);
        static SQInteger setRegionFound(HSQUIRRELVM vm);
        static SQInteger setNewMapData(HSQUIRRELVM vm);
        static SQInteger createTerrainFromMapData(HSQUIRRELVM vm);

        static SQInteger beginMapGen(HSQUIRRELVM vm);
        static SQInteger getMapGenStage(HSQUIRRELVM vm);
        static SQInteger checkClaimMapGen(HSQUIRRELVM vm);
        static SQInteger getTotalMapGenStages(HSQUIRRELVM vm);
        static SQInteger getNameForMapGenStage(HSQUIRRELVM vm);

        static SQInteger setMapsDirectory(HSQUIRRELVM vm);

        static SQInteger beginParseVisitedLocation(HSQUIRRELVM vm);
        static SQInteger checkClaimParsedVisitedLocation(HSQUIRRELVM vm);
        static SQInteger createVoxMeshItem(HSQUIRRELVM vm);

        static SQInteger voxeliseMeshForVoxelData(HSQUIRRELVM vm);

        static SQInteger insertParsedSceneFileVoxMeshGetAnimInfo(HSQUIRRELVM vm);

        static ProceduralExplorationGameCore::MapGen* currentMapGen;
        static ProceduralExplorationGameCore::VisitedPlacesParser* currentVisitedPlacesParser;
    };

};
