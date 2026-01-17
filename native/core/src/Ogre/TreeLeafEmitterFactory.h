/*
-----------------------------------------------------------------------------
Custom Factory for TreeLeafEmitter
-----------------------------------------------------------------------------
*/
#ifndef __TreeLeafEmitterFactory_H__
#define __TreeLeafEmitterFactory_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreParticleEmitterFactory.h"
#include "TreeLeafEmitter.h"

namespace Ogre
{
    /** Factory class for particle emitter of type "TreeLeaf".
    @remarks
        Creates instances of TreeLeafEmitter to be used in particle systems.
    */
    class TreeLeafEmitterFactory final : public ParticleEmitterFactory
    {
    protected:
    public:
        /** See ParticleEmitterFactory */
        String getName() const override{return "TreeLeaf";}

        /** See ParticleEmitterFactory */
        ParticleEmitter *createEmitter(ParticleSystem *psys) override
        {
            ParticleEmitter *emit = OGRE_NEW TreeLeafEmitter(psys);
            mEmitters.push_back(emit);
            return emit;
        }
    };

}//namespace Ogre

#endif
