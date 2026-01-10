/*
-----------------------------------------------------------------------------
Custom Factory for GroundColourModifierEmitter
-----------------------------------------------------------------------------
*/
#ifndef __GroundColourModifierEmitterFactory_H__
#define __GroundColourModifierEmitterFactory_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreParticleEmitterFactory.h"
#include "GroundColourModifierEmitter.h"

namespace Ogre
{
    /** Factory class for particle emitter of type "GroundColourModifier".
    @remarks
        Creates instances of GroundColourModifierEmitter to be used in particle systems.
    */
    class GroundColourModifierEmitterFactory final : public ParticleEmitterFactory
    {
    protected:
    public:
        /** See ParticleEmitterFactory */
        String getName() const override{return "GroundColourModifier";}

        /** See ParticleEmitterFactory */
        ParticleEmitter *createEmitter(ParticleSystem *psys) override
        {
            ParticleEmitter *emit = OGRE_NEW GroundColourModifierEmitter(psys);
            return emit;
        }
    };

}  // namespace Ogre

#endif
