/*
-----------------------------------------------------------------------------
Implementation of AreaProceduralWorldEmitter
-----------------------------------------------------------------------------
*/
#include "AreaProceduralWorldEmitter.h"

#include "OgreException.h"
#include "GameplayState.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "OgreMath.h"

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
    AreaProceduralWorldEmitter::AreaProceduralWorldEmitter(ParticleSystem *psys)
        : AreaEmitter(psys), mCurrentCoordinateIndex_(0), mUsingCustomPoints_(false)
    {
        if(initDefaults("AreaProceduralWorld"))
        {
            // Add custom parameters if needed
            ParamDictionary *pDict = getParamDictionary();
        }
    }
    //-----------------------------------------------------------------------
    void AreaProceduralWorldEmitter::setEmissionPoints(const std::vector<uint32_t>& points){
        mEmissionPoints_ = points;
        mUsingCustomPoints_ = !points.empty();
    }
    //-----------------------------------------------------------------------
    void AreaProceduralWorldEmitter::_initParticle(Particle *pParticle)
    {
        // Call parent implementation to get base particle setup
        AreaEmitter::_initParticle(pParticle);

        // Query terrain height at the current world coordinate
        ProceduralExplorationGameCore::ExplorationMapData* mapData = ProceduralExplorationGameCore::GameplayState::getMapData();

        ProceduralExplorationGameCore::WorldCoord worldX = 0;
        ProceduralExplorationGameCore::WorldCoord worldZ = 0;
        float finalY = 0.0f;

        if(mUsingCustomPoints_ && !mEmissionPoints_.empty() && mapData){
            //Select a random point from the custom emission points
            size_t randomIndex = rand() % mEmissionPoints_.size();
            uint32_t worldPoint = mEmissionPoints_[randomIndex];
            worldZ = worldPoint & 0xFFFF;
            worldX = (worldPoint >> 16) & 0xFFFF;

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
            finalY = 0.5f + (float)yVal * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
        }

        //Get parent system transform
        ParticleWrapper* pw = reinterpret_cast<ParticleWrapper*>(pParticle);
        Ogre::Vector3 parentPos = pw->getParentSystem()->getParentSceneNode()->_getDerivedPositionUpdated();
        Ogre::Vector3 parentScale = pw->getParentSystem()->getParentSceneNode()->_getDerivedScaleUpdated();

        pParticle->mPosition.x = ((float)worldX / parentScale.x);
        pParticle->mPosition.y = (finalY / parentScale.y);
        pParticle->mPosition.z = -((float)worldZ / parentScale.z);

        // Generate complex data by reference
        genEmissionColour( pParticle->mColour );
        genEmissionDirection( pParticle->mPosition, pParticle->mDirection );
        genEmissionVelocity( pParticle->mDirection );

        // Generate simpler data
        pParticle->mTimeToLive = pParticle->mTotalTimeToLive = genEmissionTTL();
    }

}  // namespace Ogre
