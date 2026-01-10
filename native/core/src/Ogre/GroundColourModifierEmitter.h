#ifndef __GroundColourModifierEmitter_H__
#define __GroundColourModifierEmitter_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreBoxEmitter.h"
#include "OgreMath.h"

namespace Ogre
{
    /** Particle emitter which modifies particle colours based on ground properties.
    @remarks
        This particle emitter extends the standard AreaEmitter to modify particle
        colours based on the procedural world ground data.
    */
    class GroundColourModifierEmitter : public BoxEmitter
    {
    public:
        GroundColourModifierEmitter(ParticleSystem *psys);

        /// @see ParticleEmitter
        void _initParticle(Particle *pParticle) override;
    };

}  // namespace Ogre

#endif
