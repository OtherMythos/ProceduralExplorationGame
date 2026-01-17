/*
-----------------------------------------------------------------------------
Custom Emitter for Tree Leaf Particles

This emitter emits particles from placed trees in the procedural world.
-----------------------------------------------------------------------------
*/
#ifndef __TreeLeafEmitter_H__
#define __TreeLeafEmitter_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreAreaEmitter.h"
#include "OgreMath.h"
#include <vector>

namespace Ogre
{
    /** Particle emitter which emits particles from tree positions.
    @remarks
        This particle emitter emits leaf particles from each tree position
        in the procedural exploration world.
    */
    class TreeLeafEmitter : public AreaEmitter
    {
    public:
        TreeLeafEmitter(ParticleSystem *psys);

        /// @see ParticleEmitter
        void _initParticle(Particle *pParticle) override;

    private:
    };

}  // namespace Ogre

#endif

