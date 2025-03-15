#include "GameCorePBSHlmsListener.h"

#include "OgreHlmsPbs.h"
#include "OgreHlmsManager.h"
#include "OgreRoot.h"

namespace ProceduralExplorationGamePlugin
{

    float GameCorePBSHlmsListener::mTimeValue = 0.0f;

    GameCorePBSHlmsListener::GameCorePBSHlmsListener(){

    }

    GameCorePBSHlmsListener::~GameCorePBSHlmsListener(){

    }

    Ogre::uint32 GameCorePBSHlmsListener::getPassBufferSize(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager) const {
        return sizeof(float);
    }

    float* GameCorePBSHlmsListener::preparePassBuffer(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager, float *passBufferPtr){
        *passBufferPtr++ = mTimeValue;

        return passBufferPtr;
    }
}
