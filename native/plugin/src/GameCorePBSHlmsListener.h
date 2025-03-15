#pragma once

#include "OgreHlmsListener.h"

namespace ProceduralExplorationGamePlugin
{

    class GameCorePBSHlmsListener : public Ogre::HlmsListener{
    public:
        GameCorePBSHlmsListener();
        ~GameCorePBSHlmsListener();

        static float mTimeValue;

        virtual Ogre::uint32 getPassBufferSize(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager) const;

        virtual float* preparePassBuffer(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager, float *passBufferPtr);
    };
}
