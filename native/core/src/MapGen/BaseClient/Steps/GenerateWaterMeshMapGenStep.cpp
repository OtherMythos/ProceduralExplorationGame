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

        uint32_t holeCount = 0;
        if(mapData->hasEntry("holeCount")){
            holeCount = mapData->uint32("holeCount");
        }

        for(uint32_t i = 0; i < holeCount; i++){
            std::string posKey = "holePos_" + std::to_string(i);
            std::string radiusKey = "holeRadius_" + std::to_string(i);

            if(mapData->hasEntry(posKey) && mapData->hasEntry(radiusKey)){
                uint32_t packedPos = mapData->uint32(posKey);
                uint32_t radiusVal = mapData->uint32(radiusKey);

                uint16_t originX = (packedPos >> 16) & 0xFFFF;
                uint16_t originY = packedPos & 0xFFFF;

                holes.push_back(
                    WaterMeshGenerator::Hole(Ogre::Vector2(float(originX)/600 * 100, (float(600-originY)/600 * 100)), float(radiusVal)/600 * 100)
                );
            }
        }

        WaterMeshGenerator::MeshData meshData = gen.generateMesh(100, 100, holes, mapData);

        WaterMeshGenerator::MeshData* data = new WaterMeshGenerator::MeshData();
        data->triangles = std::move(meshData.triangles);
        data->vertices = std::move(meshData.vertices);
        mapData->voidPtr("waterMeshData", reinterpret_cast<void*>(data));

        return true;
    }

}
