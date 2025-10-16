#pragma once

#include "OgreHlmsListener.h"

namespace ProceduralExplorationGamePlugin
{

    class GameCorePBSHlmsListener : public Ogre::HlmsListener{
    public:
        GameCorePBSHlmsListener();
        ~GameCorePBSHlmsListener();

        static float mTimeValue;
        static Ogre::Vector3 mPlayerPosition;
        static Ogre::Vector3 mCustomValues;
        static Ogre::Vector3 mFogColour;
        static Ogre::Vector2 mFogStartEnd;

        virtual Ogre::uint32 getPassBufferSize(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager) const;

        virtual float* preparePassBuffer(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager, float *passBufferPtr);

        virtual void preparePassHash(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager, Ogre::Hlms *hlms);
    };
}
