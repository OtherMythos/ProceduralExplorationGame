#include "GameCoreUnlitHlmsListener.h"

namespace ProceduralExplorationGamePlugin
{

    float GameCoreUnlitHlmsListener::mTimeValue = 0.0f;

    GameCoreUnlitHlmsListener::GameCoreUnlitHlmsListener(){

    }

    GameCoreUnlitHlmsListener::~GameCoreUnlitHlmsListener(){

    }

    Ogre::uint32 GameCoreUnlitHlmsListener::getPassBufferSize(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager) const {
        return sizeof(float);
    }

    float* GameCoreUnlitHlmsListener::preparePassBuffer(const Ogre::CompositorShadowNode *shadowNode, bool casterPass, bool dualParaboloid, Ogre::SceneManager *sceneManager, float *passBufferPtr){
        *passBufferPtr++ = mTimeValue;
        return passBufferPtr;
    }
}
