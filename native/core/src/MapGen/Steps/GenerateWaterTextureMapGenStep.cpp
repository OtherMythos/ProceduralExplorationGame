#include "GenerateWaterTextureMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>
#include <cstring>

namespace ProceduralExplorationGameCore{

    GenerateWaterTextureMapGenStep::GenerateWaterTextureMapGenStep(){

    }

    GenerateWaterTextureMapGenStep::~GenerateWaterTextureMapGenStep(){

    }

    void GenerateWaterTextureMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

        size_t bufSize = input->width * input->height * sizeof(float) * 4;
        AV::uint32* buffer = static_cast<AV::uint32*>(malloc(bufSize));
        memset(buffer, 0, bufSize);
        AV::uint32* bufferMask = static_cast<AV::uint32*>(malloc(bufSize));
        memset(bufferMask, 0, bufSize);

        int div = 4;
        int divWidth = input->width / div;
        int divHeight = input->height / div;
        for(int y = 0; y < div; y++){
            for(int x = 0; x < div; x++){
                GenerateWaterTextureMapGenJob job;
                job.processJob(mapData, buffer, bufferMask, x * divWidth, y * divHeight, x * divWidth + divWidth, y * divHeight + divHeight);
            }
        }

        mapData->waterTextureBuffer = buffer;
        mapData->waterTextureBufferMask = bufferMask;
    }

    GenerateWaterTextureMapGenJob::GenerateWaterTextureMapGenJob(){

    }

    GenerateWaterTextureMapGenJob::~GenerateWaterTextureMapGenJob(){

    }

    static void _writeToBuffer(float** buf, float r, float g, float b){
        *((*buf)) = r / 255;
        (*buf)++;
        *((*buf)) = g / 255;
        (*buf)++;
        *((*buf)) = b / 255;
        (*buf)++;
        *((*buf)) = 0xFF;
    }

    void GenerateWaterTextureMapGenJob::processJob(ExplorationMapData* mapData, AV::uint32* buffer, AV::uint32* bufferMask, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                const WorldPoint altitudePoint = WRAP_WORLD_POINT(x, y);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, altitudePoint);
                const AV::uint8* waterGroup = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, altitudePoint);

                /*
                if(*altitude >= mapData->seaLevel){
                    continue;
                }
                 */

                float* b = reinterpret_cast<float*>((buffer) + (x + (mapData->height - y ) * mapData->width) * 4);
                float* bMask = reinterpret_cast<float*>((bufferMask) + (x + (mapData->height - y ) * mapData->width) * 4);

                int seaLevelCutoff = 40;
                int seaLevelCutoffSecond = 8;

                if(*waterGroup == 0){
                    if(*altitude >= mapData->seaLevel - seaLevelCutoff && *altitude <  mapData->seaLevel - seaLevelCutoffSecond){
                        _writeToBuffer(&b, 113, 159, 177);
                    }
                    else if(*altitude >= mapData->seaLevel - seaLevelCutoffSecond && *altitude < mapData->seaLevel){
                        _writeToBuffer(&b, 143, 189, 207);
                    }
                    else{
                        _writeToBuffer(&b, 0, 102, 255);
                    }
                }else if(*waterGroup == INVALID_WATER_ID){
                    _writeToBuffer(&b, 143, 189, 207);
                }else{
                    _writeToBuffer(&b, 0, 0, 150);
                }

                if(*waterGroup == 0 || *waterGroup == INVALID_WATER_ID){
                    if(*altitude < mapData->seaLevel - seaLevelCutoff){
                        _writeToBuffer(&bMask, 255, 0, 0);
                    }
                    else if(*altitude > mapData->seaLevel - seaLevelCutoff && *altitude < mapData->seaLevel - seaLevelCutoffSecond){
                        _writeToBuffer(&bMask, 20, 0, 0);
                    }
                    else{
                        _writeToBuffer(&bMask, 0, 0, 0);
                    }
                }
            }
        }
    }

}
