/*
-----------------------------------------------------------------------------
Custom Emitter for Procedural Exploration Game

This emitter extends RingEmitter to take the height of the procedural world
into account when emitting particles.
-----------------------------------------------------------------------------
*/
#ifndef __RingProceduralWorldEmitter_H__
#define __RingProceduralWorldEmitter_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreRingEmitter.h"
#include "OgreMath.h"

namespace Ogre
{
    /** Particle emitter which emits particles from a ring, accounting for procedural world height.
    @remarks
        This particle emitter extends the standard RingEmitter to adjust particle
        positions based on the height of the procedural exploration world.
    */
    class _OgreParticleFXExport RingProceduralWorldEmitter : public RingEmitter
    {
    public:
        RingProceduralWorldEmitter( ParticleSystem *psys );

        /// @see ParticleEmitter
        void _initParticle( Particle *pParticle ) override;
    };

}  // namespace Ogre

#endif
