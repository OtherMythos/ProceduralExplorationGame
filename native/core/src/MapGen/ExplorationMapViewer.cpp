#include "ExplorationMapViewer.h"

#include "OgreTextureBox.h"

#include "ExplorationMapDataPrerequisites.h"
#include "GameplayState.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    enum MapViewerColours{
        VOXEL_GROUP_GROUND,
        VOXEL_GROUP_GRASS,
        VOXEL_GROUP_ICE,
        VOXEL_GROUP_TREES,
        VOXEL_GROUP_CHERRY_BLOSSOM_TREE,

        OCEAN,
        FRESH_WATER,
        WATER_GROUPS,

        COLOUR_BLACK,
        COLOUR_MAGENTA,
        COLOUR_ORANGE,

        UNDISCOVRED_REGION,

        MAX
    };
    Ogre::ABGR valueColours[MapViewerColours::MAX];

    ExplorationMapViewer::ExplorationMapViewer(){
        const float OPACITY = 0.4;

        Ogre::ColourValue cols[MapViewerColours::MAX] = {
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
        for(int i = 0; i < MapViewerColours::MAX; i++){
            valueColours[i] = cols[i].getAsABGR();
        }
    }

    ExplorationMapViewer::~ExplorationMapViewer(){

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
                    (*texPtr++) = valueColours[MapViewerColours::OCEAN];
                    continue;
                }

                //TODO have some way to specify the found regions so this logic can be performed.
                if(!GameplayState::getFoundRegion(regionId)){
                    (*texPtr++) = valueColours[MapViewerColours::UNDISCOVRED_REGION];
                    continue;
                }

                Ogre::uint8 voxelMeta = ((vox >> 8) & 0xFF);
                if(voxelMeta & static_cast<Ogre::uint8>(MapVoxelTypes::RIVER)){
                    (*texPtr++) = valueColours[MapViewerColours::FRESH_WATER];
                }else{
                    (*texPtr++) = valueColours[voxelMeta & MAP_VOXEL_MASK];
                }

            }
        }

    }

}
