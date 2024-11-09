#include "ExplorationMapViewer.h"

#include "OgreTextureBox.h"

#include "ExplorationMapDataPrerequisites.h"
#include "GameplayState.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    #include "../../../../src/MapGen/Exploration/Viewer/ExplorationMapViewerConstants.h.nut"

    Ogre::ABGR valueColours[(size_t)MapViewerColours::MAX];

    ExplorationMapViewer::ExplorationMapViewer(){
        const float OPACITY = 0.4;

        Ogre::ColourValue cols[(size_t)MapViewerColours::MAX] = {
            Ogre::ColourValue(0.84, 0.87, 0.29, 1),
            Ogre::ColourValue(0.33, 0.92, 0.27, 1),
            Ogre::ColourValue(0.84, 0.88, 0.84, 1),
            Ogre::ColourValue(0.33, 0.66, 0.005, 1),
            Ogre::ColourValue(0.94, 0.44, 0.91, 1),
            Ogre::ColourValue(0, 0, 1.0, OPACITY),
            Ogre::ColourValue(0.15, 0.15, 1.0, OPACITY),
            Ogre::ColourValue::Black,
            Ogre::ColourValue::Black,
            Ogre::ColourValue(1, 0, 1, 1),
            Ogre::ColourValue(0.85, 0.63, 0.03, 1),
            Ogre::ColourValue(0.1, 0.1, 0.1, 1),
        };
        //TODO switch this conversion to be performed statically.
        for(int i = 0; i < (size_t)MapViewerColours::MAX; i++){
            valueColours[i] = cols[i].getAsABGR();
        }
    }

    ExplorationMapViewer::~ExplorationMapViewer(){

    }

    AV::uint32 ExplorationMapViewer::getColourForVox(AV::uint32 x, AV::uint32 y, AV::uint32 vox, AV::uint32 secondaryVox, float blueNoise, ExplorationMapData* mapData, AV::uint32 drawOptions){
        AV::uint8 altitude = static_cast<AV::uint8>(vox & 0xFF);
        RegionId regionId = static_cast<AV::uint8>((secondaryVox >> 8) & 0xFF);
        AV::uint8 voxelMeta = static_cast<AV::uint8>((vox >> 8) & MAP_VOXEL_MASK);
        WaterId waterGroup = static_cast<AV::uint8>((vox >> 16) & 0xFF);

        static const float OPACITY = 1.0f;

        AV::uint32 drawVal = Ogre::ColourValue::Black.getAsABGR();

        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::GROUND_TYPE)){
            if((vox >> 8) & (size_t)MapVoxelTypes::RIVER){
                drawVal = valueColours[(size_t)MapViewerColours::FRESH_WATER];
            }else{
                drawVal = valueColours[voxelMeta];
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
                float valGroup = static_cast<float>(waterGroup) / static_cast<float>(mapData->waterData.size());
                drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
            }
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::MOISTURE_MAP)){
            float valGroup = static_cast<float>(secondaryVox & 0xFF) / static_cast<float>(0xFF);
            drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
        }
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGIONS)){
            float valGroup = static_cast<float>((secondaryVox >> 8) & 0xFF) / static_cast<float>(mapData->regionData.size());
            drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
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
                float valGroup = static_cast<float>(landGroup) / static_cast<float>(mapData->landData.size());
                drawVal = Ogre::ColourValue(valGroup, valGroup, valGroup, OPACITY).getAsABGR();
            }
        }

        return drawVal;
    }
    void ExplorationMapViewer::fillStagingTextureComplex(Ogre::TextureBox* tex, ExplorationMapData* mapData, AV::uint32 drawOptions){
        AV::uint32* texPtr = static_cast<AV::uint32*>(tex->data);
        AV::uint32* voxPtr = static_cast<AV::uint32*>(mapData->voxelBuffer);
        AV::uint32* voxSecondaryPtr = static_cast<AV::uint32*>(mapData->secondaryVoxelBuffer);
        float* blueNoisePtr = static_cast<float*>(mapData->blueNoiseBuffer);
        for(Ogre::uint32 y = 0; y < tex->height; y++){
            for(Ogre::uint32 x = 0; x < tex->width; x++){

                AV::uint32 voxColour = ExplorationMapViewer::getColourForVox(x, y, *voxPtr, *voxSecondaryPtr, *blueNoisePtr, mapData, drawOptions);
                (*texPtr++) = voxColour;

                voxPtr++;
                voxSecondaryPtr++;
                blueNoisePtr++;
            }
        }

        texPtr = static_cast<AV::uint32*>(tex->data);
        if(drawOptions & (1 << (size_t)MapViewerDrawOptions::REGION_SEEDS)){
            for(const RegionData& d : mapData->regionData){
                *(texPtr + ((int)d.seedX + (int)d.seedY * mapData->width)) =
                    d.meta == 0 ? valueColours[(size_t)MapViewerColours::COLOUR_BLACK] : valueColours[(size_t)MapViewerColours::COLOUR_ORANGE];
            }
        }
    }

    void ExplorationMapViewer::fillStagingTexture(Ogre::TextureBox* tex, ExplorationMapData* mapData){
        AV::uint32* texPtr = static_cast<AV::uint32*>(tex->data);
        AV::uint32* voxPtr = static_cast<AV::uint32*>(mapData->voxelBuffer);
        AV::uint32* voxSecondaryPtr = static_cast<AV::uint32*>(mapData->secondaryVoxelBuffer);
        for(Ogre::uint32 y = 0; y < tex->height; y++){
            for(Ogre::uint32 x = 0; x < tex->width; x++){
                AV::uint32 vox = static_cast<AV::uint32>(*voxPtr);
                AV::uint32 voxSecondary = static_cast<AV::uint32>(*voxSecondaryPtr);
                AV::uint8 altitude = static_cast<AV::uint8>(vox & 0xFF);
                AV::uint8 regionId = static_cast<AV::uint8>((voxSecondary >> 8) & 0xFF);
                voxPtr++;
                voxSecondaryPtr++;

                if(altitude < mapData->seaLevel){
                    (*texPtr++) = valueColours[(size_t)MapViewerColours::OCEAN];
                    continue;
                }

                if(!GameplayState::getFoundRegion(regionId)){
                    (*texPtr++) = valueColours[(size_t)MapViewerColours::UNDISCOVRED_REGION];
                    continue;
                }

                AV::uint8 voxelMeta = ((vox >> 8) & 0xFF);
                if(voxelMeta & static_cast<AV::uint8>(MapVoxelTypes::RIVER)){
                    (*texPtr++) = valueColours[(size_t)MapViewerColours::FRESH_WATER];
                }else{
                    (*texPtr++) = valueColours[(size_t)voxelMeta & MAP_VOXEL_MASK];
                }

            }
        }

    }

}
