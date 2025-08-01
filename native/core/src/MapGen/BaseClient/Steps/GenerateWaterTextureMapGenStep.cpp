#include "GenerateWaterTextureMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>
#include <cstring>

namespace ProceduralExplorationGameCore{

    GenerateWaterTextureMapGenStep::GenerateWaterTextureMapGenStep() : MapGenStep("Generate Water Texture"){

    }

    GenerateWaterTextureMapGenStep::~GenerateWaterTextureMapGenStep(){

    }

    void GenerateWaterTextureMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        size_t bufSize = width * height * sizeof(float) * 4;
        float* buffer = static_cast<float*>(malloc(bufSize));
        memset(buffer, 0, bufSize);
        float* bufferMask = static_cast<float*>(malloc(bufSize));
        memset(bufferMask, 0, bufSize);

        int div = 4;
        int divWidth = width / div;
        int divHeight = height / div;
        for(int y = 0; y < div; y++){
            for(int x = 0; x < div; x++){
                GenerateWaterTextureMapGenJob job;
                job.processJob(mapData, buffer, bufferMask, x * divWidth, y * divHeight, x * divWidth + divWidth, y * divHeight + divHeight);
            }
        }

        mapData->voidPtr("waterTextureBuffer", buffer);
        mapData->voidPtr("waterTextureBufferMask", bufferMask);
    }

    GenerateWaterTextureMapGenJob::GenerateWaterTextureMapGenJob(){

    }

    GenerateWaterTextureMapGenJob::~GenerateWaterTextureMapGenJob(){

    }

    static void _writeToBuffer(float** buf, float r, float g, float b, float a=255.0){
        *((*buf)) = r / 255;
        (*buf)++;
        *((*buf)) = g / 255;
        (*buf)++;
        *((*buf)) = b / 255;
        (*buf)++;
        *((*buf)) = a / 255;
    }

    static void getBufferWriteForRegion(float** buf, RegionId regionId, AV::uint8 distance, ExplorationMapData* mapData){
        if(regionId == REGION_ID_WATER){
            _writeToBuffer(buf, 0, 0, 150);
            return;
        }

        //TODO move this elsewhere.
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));
        const Biome& b = Biome::getBiomeForId(regionData[regionId].type);

        Biome::WaterTextureColourFunction func = b.getWaterTextureColourFunction();
        assert(func != 0);

        Biome::BiomeColour texCol = (*func)(false, distance, mapData);
        _writeToBuffer(buf, texCol.r, texCol.g, texCol.b, texCol.a);
    }

    void GenerateWaterTextureMapGenJob::processJob(ExplorationMapData* mapData, float* buffer, float* bufferMask, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;
        const AV::uint32 seaLevel = mapData->uint32("seaLevel");

        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                int yy = y + 1;
                if(yy >= width) yy = width-1;
                const WorldPoint altitudePoint = WRAP_WORLD_POINT(x, yy);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, altitudePoint);
                const AV::uint8* waterGroup = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, altitudePoint);
                const AV::uint8* distPtr = REGION_DISTANCE_PTR_FOR_COORD(mapData, altitudePoint);

                /*
                if(*altitude >= mapData->seaLevel){
                    continue;
                }
                 */

                int reverseWidth = width - y - 1;
                if(reverseWidth >= width) continue;
                float* b = ((buffer) + ((x + reverseWidth * width) * 4));
                float* bMask = ((bufferMask) + ((x + reverseWidth * width) * 4));

                int seaLevelCutoff = 40;
                int seaLevelCutoffSecond = 8;

                if(*waterGroup == 0){
                    if(*altitude >= seaLevel - seaLevelCutoff && *altitude <  seaLevel - seaLevelCutoffSecond){
                        _writeToBuffer(&b, 113, 159, 177);
                    }
                    else if(*altitude >= seaLevel - seaLevelCutoffSecond && *altitude < seaLevel){
                        /*
                        AV::uint8 distVal = *distPtr >= 4 ? 4 : *distPtr;
                        float red = 143 - (distVal * 10);
                        float green = 189 - (distVal * 10);
                        float blue = 207 - (distVal * 10);
                        _writeToBuffer(&b, red, green, blue);
                         */
                        if(*distPtr < 4){
                            _writeToBuffer(&b, 143, 189, 207);
                        }else{
                            _writeToBuffer(&b, 113, 159, 177);
                        }
                    }
                    else{
                        _writeToBuffer(&b, 0, 102, 255);
                    }
                }else if(*waterGroup == INVALID_WATER_ID){
                    _writeToBuffer(&b, 143, 189, 207);
                }else{
                    RegionId regionId = *REGION_PTR_FOR_COORD_CONST(mapData, altitudePoint);
                    getBufferWriteForRegion(&b, regionId, *distPtr, mapData);
                }

                if(*waterGroup == 0 || *waterGroup == INVALID_WATER_ID){
                    if(*altitude < seaLevel - seaLevelCutoff){
                        _writeToBuffer(&bMask, 255, 0, 0, 0);
                    }
                    else if(*altitude > seaLevel - seaLevelCutoff && *altitude < seaLevel - seaLevelCutoffSecond){
                        _writeToBuffer(&bMask, 20, 0, 0, 0);
                    }
                    else{
                        _writeToBuffer(&bMask, 0, 0, 0, 0);
                    }
                }

                const AV::uint32* flags = FULL_PTR_FOR_COORD_SECONDARY(mapData, altitudePoint);
                if(*flags & SKIP_DRAW_TERRAIN_VOXEL_FLAG){
                    b -= 4;
                    _writeToBuffer(&b, 0, 0, 0, 0);
                }
            }
        }


        const std::vector<FloodFillEntry*>& waterData = (*mapData->ptr<std::vector<FloodFillEntry*>>("waterData"));
        //Write some pixels on the sides of fresh water, to help accomodate for vertex animations.
        //Start at 1 to skip the ocean.
        for(size_t i = 1; i < waterData.size(); i++){
            const FloodFillEntry* e = waterData[i];

            for(WorldPoint p : e->edges){
                WorldCoord xx, yy;
                READ_WORLD_POINT(p, xx, yy);

                for(int ya = -1; ya < 2; ya++){
                    for(int xa = -1; xa < 2; xa++){
                        int xxa = int(xx) + xa;
                        int yya = int(yy) + ya;
                        int reverseWidth = width - yya - 1;
                        float* b = ((buffer) + ((xxa + reverseWidth * width) * 4));

                        RegionId regionId = *REGION_PTR_FOR_COORD_CONST(mapData, p);
                        getBufferWriteForRegion(&b, regionId, 0, mapData);
                        //_writeToBuffer(&b, 0, 0, 150);
                    }
                }
            }
        }
    }

}
