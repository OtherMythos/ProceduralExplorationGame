/*
-----------------------------------------------------------------------------
Custom Factory for AreaProceduralWorldEmitter
-----------------------------------------------------------------------------
*/
#ifndef __AreaProceduralWorldEmitterFactory_H__
#define __AreaProceduralWorldEmitterFactory_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreParticleEmitterFactory.h"
#include "AreaProceduralWorldEmitter.h"

namespace Ogre
{
    /** Factory class for particle emitter of type "AreaProceduralWorld".
    @remarks
        Creates instances of AreaProceduralWorldEmitter to be used in particle systems.
    */
    class AreaProceduralWorldEmitterFactory final : public ParticleEmitterFactory
    {
    protected:
    public:
        /** See ParticleEmitterFactory */
        String getName() const override{return "AreaProceduralWorld";}

        /** See ParticleEmitterFactory */
        ParticleEmitter *createEmitter(ParticleSystem *psys) override
        {
            ParticleEmitter *emit = OGRE_NEW AreaProceduralWorldEmitter(psys);
            mEmitters.push_back(emit);
            return emit;
        }
    };

}//namespace Ogre

#endif
