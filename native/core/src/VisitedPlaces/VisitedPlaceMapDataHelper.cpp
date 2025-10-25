#include "VisitedPlaceMapDataHelper.h"

#include "Voxeliser/Voxeliser.h"

#include "Ogre.h"

namespace ProceduralExplorationGameCore{

    VisitedPlaceMapDataHelper::VisitedPlaceMapDataHelper(VisitedPlaceMapData* data)
        : mMapData(data)
    {

    }

    VisitedPlaceMapDataHelper::~VisitedPlaceMapDataHelper(){

    }

    bool VisitedPlaceMapDataHelper::voxeliseToTerrainMeshes(const std::string& meshName, Ogre::MeshPtr* outMesh, AV::uint32 x, AV::uint32 y, AV::uint32 width, AV::uint32 height, bool alterValues, bool swapVoxelForMeta){
    //bool VisitedPlaceMapDataHelper::voxeliseToTerrainMeshes(AV::uint32 divisions, Ogre::MeshPtr* outMeshes, AV::uint32* outNumRegions){

        Voxeliser vox;
        if(alterValues){
            vox.createTerrainFromVisitedPlaceMapDataAlteredValues(meshName, mMapData, outMesh, x, y, width, height, swapVoxelForMeta);
        }else{
            vox.createTerrainFromVisitedPlaceMapData(meshName, mMapData, outMesh, x, y, width, height);
        }

        return true;
    }

}
