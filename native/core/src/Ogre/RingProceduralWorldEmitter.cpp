/*
-----------------------------------------------------------------------------
Implementation of RingProceduralWorldEmitter
-----------------------------------------------------------------------------
*/
#include "RingProceduralWorldEmitter.h"

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
    RingProceduralWorldEmitter::RingProceduralWorldEmitter( ParticleSystem *psys )
        : RingEmitter( psys )
    {
        if( initDefaults( "RingProceduralWorld" ) )
        {
            // Add custom parameters
            ParamDictionary *pDict = getParamDictionary();

            pDict->addParameter( ParameterDef( "inner_width",
                                               "Parametric value describing the proportion of the "
                                               "shape which is hollow.",
                                               PT_REAL ),
                                 &msCmdInnerX );
            pDict->addParameter( ParameterDef( "inner_height",
                                               "Parametric value describing the proportion of the "
                                               "shape which is hollow.",
                                               PT_REAL ),
                                 &msCmdInnerY );
        }
        // default is half empty
        setInnerSize( 0.5, 0.5 );
    }
    //-----------------------------------------------------------------------
    void RingProceduralWorldEmitter::_initParticle( Particle *pParticle )
    {
        // Call parent implementation to get base particle setup
        RingEmitter::_initParticle( pParticle );

        // Query terrain height at the particle's XZ position
        ProceduralExplorationGameCore::ExplorationMapData* mapData = ProceduralExplorationGameCore::GameplayState::getMapData();
        if(mapData)
        {
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

            //Create world point and query height
            ProceduralExplorationGameCore::WorldPoint point = ProceduralExplorationGameCore::WRAP_WORLD_POINT(worldX, worldZ);
            const AV::uint8* heightPtr = ProceduralExplorationGameCore::VOX_PTR_FOR_COORD_CONST(mapData, point);
            AV::uint8 height = *heightPtr;

            const AV::uint32 WORLD_DEPTH = 20;
            const AV::uint32 ABOVE_GROUND = 0xFF - mapData->seaLevel;
            const float PROCEDURAL_WORLD_UNIT_MULTIPLIER = 0.4;
            //Set Y position based on terrain height minus sea level
            int yVal = static_cast<int>((static_cast<float>(height - mapData->seaLevel) / (float)ABOVE_GROUND) * (float)WORLD_DEPTH);
            yVal = yVal < 0 ? 0 : yVal;
            float finalY = 0.5 + (float)yVal * PROCEDURAL_WORLD_UNIT_MULTIPLIER;

            float parentOffset = (parentPos.y / parentScale.y);
            pParticle->mPosition.y = (finalY / (parentScale.y)) - parentOffset;
        }
    }

}  // namespace Ogre
