#include "ExplorationMapViewer.h"

#include "OgreTextureBox.h"

#include "PluginBaseSingleton.h"
#include "MapGen/MapGen.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "ExplorationMapDataPrerequisites.h"
#include "GameplayState.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    #include "../../../../src/MapGen/Exploration/Viewer/ExplorationMapViewerConstants.h.nut"

    enum MapViewerColours{
        OCEAN,
        FRESH_WATER,
        WATER_GROUPS,

        COLOUR_BLACK,
        COLOUR_MAGENTA,
        COLOUR_ORANGE,

        UNDISCOVRED_REGION,

        MAX
    };

    Ogre::ABGR valueColours[(size_t)MapViewerColours::MAX];

    ExplorationMapViewer::ExplorationMapViewer(){
        const float OPACITY = 0.2;

        Ogre::ColourValue cols[(size_t)MapViewerColours::MAX];
        cols[(size_t)MapViewerColours::OCEAN] = Ogre::ColourValue(0, 0, 1.0, OPACITY);
        cols[(size_t)MapViewerColours::FRESH_WATER] = Ogre::ColourValue(0.15, 0.15, 1.0, OPACITY);
        cols[(size_t)MapViewerColours::WATER_GROUPS] = Ogre::ColourValue::Black;
        cols[(size_t)MapViewerColours::COLOUR_BLACK] = Ogre::ColourValue::Black;
        cols[(size_t)MapViewerColours::COLOUR_MAGENTA] = Ogre::ColourValue(1, 0, 1, 1);
        cols[(size_t)MapViewerColours::COLOUR_ORANGE] = Ogre::ColourValue(0.85, 0.63, 0.03, 1);
        cols[(size_t)MapViewerColours::UNDISCOVRED_REGION] = Ogre::ColourValue(0.1, 0.1, 0.1, 1);

        for(int i = 0; i < (size_t)MapViewerColours::MAX; i++){
            valueColours[i] = cols[i].getAsABGR();
        }
    }

    ExplorationMapViewer::~ExplorationMapViewer(){

    }

    AV::uint32 getColourForVox(AV::uint32 x, AV::uint32 y, AV::uint32 vox, AV::uint32 secondaryVox, AV::uint32 tertiaryVox, float blueNoise, ExplorationMapData* mapData, AV::uint32 drawOptions, const std::vector<MapGen::VoxelDef>& voxDefs){
        AV::uint8 altitude = static_cast<AV::uint8>(vox & 0xFF);
        RegionId regionId = static_cast<AV::uint8>((secondaryVox >> 8) & 0xFF);
        AV::uint8 regionDistance = static_cast<AV::uint8>((secondaryVox >> 16) & 0xFF);
        AV::uint8 voxelMeta = static_cast<AV::uint8>((vox >> 8));
        WaterId waterGroup = static_cast<AV::uint8>((vox >> 16) & 0xFF);

        static const float OPACITY = 1.0f;

        AV::uint32 drawVal = Ogre::ColourValue::Black.getAsABGR();

        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::GROUND_TYPE)){
            if(tertiaryVox & RIVER_VOXEL_FLAG){
                drawVal = valueColours[(size_t)MapViewerColours::FRESH_WATER];
            }else{
                drawVal = voxDefs[voxelMeta].colourABGR;
            }
        }else{
            //NOTE: Slight optimisation.
            //Most cases will have ground type enabled, so no point doing this check unless needed.
            float val = static_cast<float>(altitude) / static_cast<float>(0xFF);
            drawVal = Ogre::ColourValue(val, val, val, 1).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::WATER)){
            if(altitude < mapData->seaLevel){
                if(waterGroup == 0){
                    drawVal = valueColours[(size_t)MapViewerColours::OCEAN];
                }else{
                    drawVal = valueColours[(size_t)MapViewerColours::FRESH_WATER];
                }
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::WATER_GROUPS)){
            if(waterGroup == INVALID_WATER_ID){
                drawVal = valueColours[(size_t)MapViewerColours::COLOUR_BLACK];
            }else{
                float valGroup = static_cast<float>(waterGroup) / static_cast<float>(mapData->ptr<std::vector<FloodFillEntry*>>("waterData")->size());
                drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::MOISTURE_MAP)){
            float valGroup = static_cast<float>(secondaryVox & 0xFF) / static_cast<float>(0xFF);
            drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::VOXEL_DIFFUSE)){
            float valGroup = static_cast<float>(tertiaryVox & 0xFF) / static_cast<float>(0xFF);
            drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGIONS)){
            float valGroup = static_cast<float>((secondaryVox >> 8) & 0xFF) / static_cast<float>(mapData->ptr<std::vector<RegionData>>("regionData")->size());
            drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGION_DISTANCE)){
            float dist = static_cast<float>(regionDistance) / 254;
            drawVal = Ogre::ColourValue(dist, dist, dist, OPACITY).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGION_CONCAVITY)){
            const std::vector<RegionData>& regionData = *mapData->ptr<std::vector<RegionData>>("regionData");
            if(regionId >= regionData.size()){
                drawVal = Ogre::ColourValue(1, 1, 1, OPACITY).getAsABGR();
            }else{
                float dist = static_cast<float>(regionData[regionId].concavity) / 254;
                drawVal = Ogre::ColourValue(dist, dist, dist, OPACITY).getAsABGR();
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::BLUE_NOISE)){
            drawVal = Ogre::ColourValue(blueNoise, blueNoise, blueNoise, OPACITY).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::EDGE_VALS)){
            AV::uint32 edgeVox = (vox >> 8) & 0x80;
            if(edgeVox){
                drawVal = valueColours[(size_t)MapViewerColours::COLOUR_BLACK];
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::LAND_GROUPS)){
            LandId landGroup = (vox >> 24) & 0xFF;
            if(landGroup == INVALID_LAND_ID){
                drawVal = valueColours[(size_t)MapViewerColours::COLOUR_BLACK];
            }else{
                float valGroup = static_cast<float>(landGroup) / static_cast<float>(mapData->ptr<std::vector<FloodFillEntry*>>("landData")->size());
                drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::VOXEL_HIGHLIGHT_GROUPS)){
            AV::uint8 highlightGroup = VOXEL_HIGHLIGHT_GROUP_GET(mapData, WRAP_WORLD_POINT(x, y));
            if(highlightGroup == 0){
                drawVal = Ogre::ColourValue::Black.getAsABGR();
            }else{
                float valGroup = static_cast<float>(highlightGroup) / static_cast<float>(0xFF);
                drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
            }
        }

        return drawVal;
    }
    void ExplorationMapViewer::fillStagingTextureComplex(Ogre::TextureBox* tex, ExplorationMapData* mapData, AV::uint32 drawOptions){
        AV::uint32* texPtr = static_cast<AV::uint32*>(tex->data);
        AV::uint32* voxPtr = static_cast<AV::uint32*>(mapData->voxelBuffer);
        AV::uint32* voxSecondaryPtr = static_cast<AV::uint32*>(mapData->secondaryVoxelBuffer);
        AV::uint32* voxTertiaryPtr = static_cast<AV::uint32*>(mapData->tertiaryVoxelBuffer);
        float* blueNoisePtr = static_cast<float*>(mapData->blueNoiseBuffer);
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        MapGen* mapGen = PluginBaseSingleton::getMapGen();
        assert(mapGen);
        const std::vector<MapGen::VoxelDef>& voxDefs = mapGen->getVoxelDefs();

        for(Ogre::uint32 y = 0; y < tex->height; y++){
            for(Ogre::uint32 x = 0; x < tex->width; x++){

                AV::uint32 voxColour = getColourForVox(x, y, *voxPtr, *voxSecondaryPtr, *voxTertiaryPtr, *blueNoisePtr, mapData, drawOptions, voxDefs);
                (*texPtr++) = voxColour;

                voxPtr++;
                voxSecondaryPtr++;
                voxTertiaryPtr++;
                blueNoisePtr++;
            }
        }

        texPtr = static_cast<AV::uint32*>(tex->data);
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGION_SEEDS)){
            for(const RegionData& d : regionData){
                *(texPtr + ((int)d.seedX + (int)d.seedY * mapData->width)) =
                    d.meta == 0 ? valueColours[(size_t)MapViewerColours::COLOUR_BLACK] : valueColours[(size_t)MapViewerColours::COLOUR_ORANGE];
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGION_EDGES)){
            for(const RegionData& d : regionData){
                for(const WorldPoint& p : d.edges){
                    WorldCoord x, y;
                    READ_WORLD_POINT(p, x, y);
                    *(texPtr + (x + y * mapData->width)) = valueColours[(size_t)MapViewerColours::COLOUR_BLACK];
                }
            }
        }
    }

    void ExplorationMapViewer::fillStagingTexture(Ogre::TextureBox* tex, ExplorationMapData* mapData){
        AV::uint32* texPtr = static_cast<AV::uint32*>(tex->data);
        AV::uint32* voxPtr = static_cast<AV::uint32*>(mapData->voxelBuffer);
        AV::uint32* voxSecondaryPtr = static_cast<AV::uint32*>(mapData->secondaryVoxelBuffer);
        AV::uint32* voxTertiaryPtr = static_cast<AV::uint32*>(mapData->tertiaryVoxelBuffer);

        MapGen* mapGen = PluginBaseSingleton::getMapGen();
        assert(mapGen);
        const std::vector<MapGen::VoxelDef>& voxDefs = mapGen->getVoxelDefs();

        for(Ogre::uint32 y = 0; y < tex->height; y++){
            for(Ogre::uint32 x = 0; x < tex->width; x++){
                AV::uint32 vox = static_cast<AV::uint32>(*voxPtr);
                AV::uint32 voxSecondary = static_cast<AV::uint32>(*voxSecondaryPtr);
                AV::uint32 voxTertiary = static_cast<AV::uint32>(*voxTertiaryPtr);
                AV::uint8 altitude = static_cast<AV::uint8>(vox & 0xFF);
                AV::uint8 regionId = static_cast<AV::uint8>((voxSecondary >> 8) & 0xFF);
                voxPtr++;
                voxSecondaryPtr++;
                voxTertiaryPtr++;

                if(altitude < mapData->seaLevel){
                    (*texPtr++) = valueColours[(size_t)MapViewerColours::OCEAN];
                    continue;
                }

                if(!GameplayState::getFoundRegion(regionId)){
                    (*texPtr++) = valueColours[(size_t)MapViewerColours::UNDISCOVRED_REGION];
                    continue;
                }

                if(voxTertiary & RIVER_VOXEL_FLAG){
                    (*texPtr++) = valueColours[(size_t)MapViewerColours::FRESH_WATER];
                }else{
                    AV::uint8 voxelMeta = ((vox >> 8) & 0xFF);
                    (*texPtr++) = voxDefs[(size_t)voxelMeta].colourABGR;
                }

            }
        }

    }

}
