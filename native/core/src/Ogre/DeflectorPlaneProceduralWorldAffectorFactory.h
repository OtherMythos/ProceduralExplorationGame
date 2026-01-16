/*
-----------------------------------------------------------------------------
DeflectorPlaneProceduralWorldAffectorFactory
-----------------------------------------------------------------------------
*/
#ifndef __DeflectorPlaneProceduralWorldAffectorFactory_H__
#define __DeflectorPlaneProceduralWorldAffectorFactory_H__

#include "DeflectorPlaneProceduralWorldAffector.h"
#include "OgreParticleAffectorFactory.h"

namespace Ogre
{
    /** Factory class for DeflectorPlaneProceduralWorldAffector. */
    class DeflectorPlaneProceduralWorldAffectorFactory final : public ParticleAffectorFactory
    {
        /** See ParticleAffectorFactory */
        String getName() const override { return "DeflectorPlaneProceduralWorld"; }

        /** See ParticleAffectorFactory */
        ParticleAffector *createAffector(ParticleSystem *psys) override
        {
            ParticleAffector *p = OGRE_NEW DeflectorPlaneProceduralWorldAffector(psys);
            mAffectors.push_back(p);
            return p;
        }
    };

}  // namespace Ogre

#endif
