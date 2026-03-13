#pragma once

#include "Ogre.h"
#include <vector>
#include <string>

namespace ProceduralExplorationGameCore{

    struct MeshParticle{
        Ogre::SceneNode* node;
        float velX, velY, velZ;
        int age;
        int maxAge;
        float startScale;
        float endScale;
        bool active;
    };

    class MeshParticleEmitter{
    public:
        MeshParticleEmitter(Ogre::SceneNode* parentNode, Ogre::SceneManager* sceneManager);
        ~MeshParticleEmitter();

        void addMeshVariant(const std::string& meshName);
        void setPoolSize(int size);
        void setGravity(float gravity);
        void setRenderQueueGroup(Ogre::uint32 group);

        void emit(float x, float y, float z,
                  float velX, float velY, float velZ,
                  int maxLifetime,
                  float startScale, float endScale,
                  float rotX, float rotY, float rotZ);

        void update();
        void clear();
        void destroy();

    private:
        void initPool_();
        int acquireSlot_();

        Ogre::SceneNode* mParentNode_;
        Ogre::SceneManager* mSceneManager_;
        std::vector<std::string> mMeshVariants_;
        std::vector<MeshParticle> mPool_;
        int mPoolSize_;
        int mNextFreeHint_;
        bool mPoolInitialised_;
        float mGravity_;
        Ogre::uint32 mRenderQueueGroup_;
        bool mDestroyed_;
    };

}
