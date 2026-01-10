#include "GroundColourModifierEmitter.h"

#include "OgreException.h"
#include "GameplayState.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "OgreMath.h"

#include "OgreParticleSystem.h"
#include "OgreParticle.h"

#include "PluginBaseSingleton.h"
#include "MapGen/MapGen.h"

namespace Ogre
{
    class ParticleWrapper : public Ogre::Particle{
    public:
        Ogre::ParticleSystem* getParentSystem(){
            return mParentSystem;
        }
    };

    //-----------------------------------------------------------------------
    GroundColourModifierEmitter::GroundColourModifierEmitter(ParticleSystem *psys)
        : BoxEmitter(psys)
    {
        if(initDefaults("GroundColourModifier"))
        {
        }
    }
    //-----------------------------------------------------------------------
    void GroundColourModifierEmitter::_initParticle(Particle *pParticle)
    {
        // Call parent implementation to get base particle setup
        BoxEmitter::_initParticle(pParticle);

        // Query terrain voxel value at particle position
        ProceduralExplorationGameCore::ExplorationMapData* mapData = ProceduralExplorationGameCore::GameplayState::getMapData();

        if(mapData){
            // Get parent system transform
            ParticleWrapper* pw = reinterpret_cast<ParticleWrapper*>(pParticle);
            Ogre::Vector3 parentPos = pw->getParentSystem()->getParentSceneNode()->_getDerivedPositionUpdated();
            Ogre::Vector3 parentScale = pw->getParentSystem()->getParentSceneNode()->_getDerivedScaleUpdated();

            //Convert particle position to world coordinates
            int worldX = static_cast<int>(Math::Abs(parentPos.x + pParticle->mPosition.x * parentScale.x));
            int worldZ = static_cast<int>(Math::Abs(parentPos.z + pParticle->mPosition.z * parentScale.z));

            //Clamp to map bounds
            if(worldX >= static_cast<int>(mapData->width))
                worldX = mapData->width - 1;
            if(worldZ >= static_cast<int>(mapData->height))
                worldZ = mapData->height - 1;

            //Query voxel colour value at this world position
            const AV::uint8* colourPtr = ProceduralExplorationGameCore::VOX_VALUE_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(worldX, worldZ));
            AV::uint8 colourIndex = *colourPtr;

            ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
            assert(mapGen);
            const std::vector<ProceduralExplorationGameCore::MapGen::VoxelDef>& voxDefs = mapGen->getVoxelDefs();

            //Apply colour from palette
            const AV::uint32 colour = voxDefs[colourIndex].colourABGR;
            Ogre::ColourValue outCol;
            outCol.setAsABGR(colour);
            outCol *= 0.5;
            pParticle->mColour = outCol;
        }else{
            //Fallback colour if no map data available
            pParticle->mColour = Ogre::ColourValue(1.0f, 1.0f, 1.0f, 1.0f);
        }
    }

}  // namespace Ogre
