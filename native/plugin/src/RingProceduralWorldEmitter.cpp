/*
-----------------------------------------------------------------------------
Implementation of RingProceduralWorldEmitter
-----------------------------------------------------------------------------
*/
#include "RingProceduralWorldEmitter.h"

#include "OgreException.h"
#include "OgreParticle.h"

namespace Ogre
{
    //-----------------------------------------------------------------------
    RingProceduralWorldEmitter::RingProceduralWorldEmitter( ParticleSystem *psys )
        : RingEmitter( psys )
    {
        if( initDefaults( "RingProceduralWorld" ) )
        {
            //any custom initialization can go here
        }
    }
    //-----------------------------------------------------------------------
    void RingProceduralWorldEmitter::_initParticle( Particle *pParticle )
    {
        // Call parent implementation to get base particle setup
        RingEmitter::_initParticle( pParticle );

        // Adjust Y position by world height (currently adding 10 for testing)
        pParticle->mPosition.y+= 10.0f;
    }

}  // namespace Ogre
