/*
-----------------------------------------------------------------------------
Custom Emitter for Procedural Exploration Game

This emitter extends AreaEmitter to emit particles from specific world
coordinates, accounting for the height of the procedural world.
-----------------------------------------------------------------------------
*/
#ifndef __AreaProceduralWorldEmitter_H__
#define __AreaProceduralWorldEmitter_H__

#include "OgreParticleFXPrerequisites.h"

#include "OgreAreaEmitter.h"
#include "OgreMath.h"
#include <vector>

namespace Ogre
{
    /** Particle emitter which emits particles from world coordinates, accounting for procedural world height.
    @remarks
        This particle emitter extends the standard AreaEmitter to emit particles
        from specific world positions, adjusting their Y coordinate based on the
        height of the procedural exploration world.
    */
    class AreaProceduralWorldEmitter : public AreaEmitter
    {
    public:
        AreaProceduralWorldEmitter(ParticleSystem *psys);

        /// @see ParticleEmitter
        void _initParticle(Particle *pParticle) override;

        ///@param points Vector of world points where particles will be emitted
        void setEmissionPoints(const std::vector<uint32_t>& points);

    private:
        size_t mCurrentCoordinateIndex_;
        std::vector<uint32_t> mEmissionPoints_;
        bool mUsingCustomPoints_;
    };

}  // namespace Ogre

#endif
