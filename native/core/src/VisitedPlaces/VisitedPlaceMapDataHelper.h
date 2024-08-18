#pragma once

#include "OgrePrerequisites.h"
#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData;

    class VisitedPlaceMapDataHelper{
    public:
        VisitedPlaceMapDataHelper(VisitedPlaceMapData* data);
        ~VisitedPlaceMapDataHelper();

        bool voxeliseToTerrainMeshes(const std::string& meshName, Ogre::MeshPtr* outMesh, AV::uint32 x, AV::uint32 y, AV::uint32 width, AV::uint32 height);

    private:
        VisitedPlaceMapData* mMapData;
    };

}
