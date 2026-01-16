/*
-----------------------------------------------------------------------------
DeflectorPlaneProceduralWorldAffector - Deflects particles based on procedural world terrain
-----------------------------------------------------------------------------
*/
#ifndef __DeflectorPlaneProceduralWorldAffector_H__
#define __DeflectorPlaneProceduralWorldAffector_H__

#include "OgreParticleAffector.h"
#include "OgreVector3.h"

namespace Ogre
{
    /** This class defines a ParticleAffector which deflects particles based on procedural world altitude.
    @remarks
        This affector queries the procedural world's altitude at each particle's XZ position
        and deflects particles using the calculated Y value as a deflection plane.
        All particles which hit the plane are reflected.
    */
    class DeflectorPlaneProceduralWorldAffector : public ParticleAffector
    {
    public:
        /** Command object for bounce (see ParamCommand).*/
        class CmdBounce final : public ParamCommand
        {
        public:
            String doGet(const void *target) const override;
            void   doSet(void *target, const String &val) override;
        };

        //Default constructor
        DeflectorPlaneProceduralWorldAffector(ParticleSystem *psys);

        /** See ParticleAffector. */
        void _affectParticles(ParticleSystem *pSystem, Real timeElapsed) override;

        /** Sets the bounce value of the deflection. */
        void setBounce(Real bounce);

        /** Gets the bounce value of the deflection. */
        Real getBounce() const;

        //Command objects
        static CmdBounce msBounceCmd;

    protected:
        //bounce factor (0.5 means 50 percent)
        Real mBounce;

    private:
        /** Helper function to calculate the world Y position from terrain height */
        float calculateWorldYFromHeight(Ogre::Vector3 parentPos, Ogre::Vector3 parentScale, Ogre::Vector3 particlePos);
    };

}  // namespace Ogre

#endif
