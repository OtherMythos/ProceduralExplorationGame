#include "GenerateWaterMeshMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/Mesh/WaterMeshGenerator.h"

namespace ProceduralExplorationGameCore{

    GenerateWaterMeshMapGenStep::GenerateWaterMeshMapGenStep() : MapGenStep("Generate Water Mesh"){

    }

    GenerateWaterMeshMapGenStep::~GenerateWaterMeshMapGenStep(){

    }

    bool GenerateWaterMeshMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

        WaterMeshGenerator gen;
        std::vector<WaterMeshGenerator::Hole> holes;

        if(mapData->hasEntry("holeX") && mapData->hasEntry("holeY")){
            holes.push_back(
                WaterMeshGenerator::Hole(Ogre::Vector2(float(mapData->uint32("holeX"))/600 * 100, (float(600-mapData->uint32("holeY"))/600 * 100)), float(mapData->uint32("holeRadius"))/600 * 100)
            );
        };
        WaterMeshGenerator::MeshData meshData = gen.generateMesh(100, 100, holes, mapData);

        WaterMeshGenerator::MeshData* data = new WaterMeshGenerator::MeshData();
        data->triangles = std::move(meshData.triangles);
        data->vertices = std::move(meshData.vertices);
        mapData->voidPtr("waterMeshData", reinterpret_cast<void*>(data));

        return true;
    }

}
