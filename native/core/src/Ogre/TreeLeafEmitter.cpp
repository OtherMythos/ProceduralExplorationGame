/*
-----------------------------------------------------------------------------
Implementation of TreeLeafEmitter
-----------------------------------------------------------------------------
*/
#include "TreeLeafEmitter.h"

#include "OgreException.h"
#include "GameplayState.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "PlacedItemManager.h"
#include "OgreMath.h"

#include "PluginBaseSingleton.h"

#include "OgreParticleSystem.h"
#include "OgreParticle.h"

namespace Ogre
{
    class ParticleWrapper : public Ogre::Particle{
    public:
        Ogre::ParticleSystem* getParentSystem(){
            return mParentSystem;
        }
    };

    //-----------------------------------------------------------------------
    TreeLeafEmitter::TreeLeafEmitter(ParticleSystem *psys)
        : AreaEmitter(psys)
    {
        if(initDefaults("TreeLeaf"))
        {
            // Add custom parameters if needed
            ParamDictionary *pDict = getParamDictionary();
        }
    }
    //-----------------------------------------------------------------------
    void TreeLeafEmitter::_initParticle(Particle *pParticle)
    {
        // Call parent implementation to get base particle setup
        AreaEmitter::_initParticle(pParticle);

        // Query terrain height at a random tree position
        ProceduralExplorationGameCore::ExplorationMapData* mapData = ProceduralExplorationGameCore::GameplayState::getMapData();
        ProceduralExplorationGameCore::PlacedItemManager* placedItemManager = ProceduralExplorationGameCore::PluginBaseSingleton::getPlacedItemManager();

        if(!mapData || !placedItemManager){
            return;
        }

        //Get a random placed item EID
        AV::uint64 randomTreeEid = placedItemManager->getRandomPlacedItem();
        if(randomTreeEid == 0){
            return;
        }

        //Get the placed item data
        const ProceduralExplorationGameCore::PlacedItemEntry* itemData = placedItemManager->getPlacedItem(randomTreeEid);
        if(!itemData){
            return;
        }

        //Decode the world point
        ProceduralExplorationGameCore::WorldCoord worldX = 0;
        ProceduralExplorationGameCore::WorldCoord worldZ = 0;
        ProceduralExplorationGameCore::READ_WORLD_POINT(itemData->worldPoint, worldX, worldZ);

        //Clamp to map bounds
        if(worldX >= mapData->width)
            worldX = mapData->width - 1;
        if(worldZ >= mapData->height)
            worldZ = mapData->height - 1;

        //Query height at this world position
        const AV::uint8* heightPtr = ProceduralExplorationGameCore::VOX_PTR_FOR_COORD_CONST(mapData, ProceduralExplorationGameCore::WRAP_WORLD_POINT(worldX, worldZ));
        AV::uint8 height = *heightPtr;

        const AV::uint32 WORLD_DEPTH = 20;
        const AV::uint32 ABOVE_GROUND = 0xFF - mapData->seaLevel;
        const float PROCEDURAL_WORLD_UNIT_MULTIPLIER = 0.4f;

        //Convert world height to Y position
        int yVal = static_cast<int>((static_cast<float>((int)height - (int)mapData->seaLevel) / (float)ABOVE_GROUND) * (float)WORLD_DEPTH);
        yVal = yVal < 0 ? 0 : yVal;
        float finalY = 1.5f + 0.5f + (float)yVal * PROCEDURAL_WORLD_UNIT_MULTIPLIER;

        //Get parent system transform
        ParticleWrapper* pw = reinterpret_cast<ParticleWrapper*>(pParticle);
        Ogre::Vector3 parentScale = pw->getParentSystem()->getParentSceneNode()->_getDerivedScaleUpdated();

        //Add random offset in x and z
        float randomX = (rand() / (float)RAND_MAX) * 2.0f - 1.0f;
        float randomZ = (rand() / (float)RAND_MAX) * 2.0f - 1.0f;

        pParticle->mPosition.x = ((float)worldX / parentScale.x) + randomX;
        pParticle->mPosition.y = (finalY / parentScale.y);
        pParticle->mPosition.z = -((float)worldZ / parentScale.z) + randomZ;

        // Generate complex data by reference
        genEmissionColour(pParticle->mColour);
        genEmissionDirection(pParticle->mPosition, pParticle->mDirection);
        genEmissionVelocity(pParticle->mDirection);

        // Generate simpler data
        pParticle->mTimeToLive = pParticle->mTotalTimeToLive = genEmissionTTL();
    }

}  // namespace Ogre
