/*
-----------------------------------------------------------------------------
Custom Factory for RingProceduralWorldEmitter
-----------------------------------------------------------------------------
*/
#ifndef __RingProceduralWorldEmitterFactory_H__
#define __RingProceduralWorldEmitterFactory_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreParticleEmitterFactory.h"
#include "RingProceduralWorldEmitter.h"

namespace Ogre
{
    /** Factory class for particle emitter of type "RingProceduralWorld".
    @remarks
        Creates instances of RingProceduralWorldEmitter to be used in particle systems.
    */
    class RingProceduralWorldEmitterFactory final : public ParticleEmitterFactory
    {
    protected:
    public:
        /** See ParticleEmitterFactory */
        String getName() const override { return "RingProceduralWorld"; }

        /** See ParticleEmitterFactory */
        ParticleEmitter *createEmitter( ParticleSystem *psys ) override
        {
            ParticleEmitter *emit = OGRE_NEW RingProceduralWorldEmitter( psys );
            mEmitters.push_back( emit );
            return emit;
        }
    };

}  // namespace Ogre

#endif
