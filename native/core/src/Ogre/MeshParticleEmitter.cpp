#include "MeshParticleEmitter.h"

#include "OgreVoxMeshItem.h"
#include "OgreVoxMeshManager.h"

namespace ProceduralExplorationGameCore{

    MeshParticleEmitter::MeshParticleEmitter(Ogre::SceneNode* parentNode, Ogre::SceneManager* sceneManager)
        : mParentNode_(parentNode),
          mSceneManager_(sceneManager),
          mPoolSize_(0),
          mNextFreeHint_(0),
          mPoolInitialised_(false),
          mGravity_(0.0f),
          mRenderQueueGroup_(0),
          mDestroyed_(false)
    {
    }

    MeshParticleEmitter::~MeshParticleEmitter(){
        if(!mDestroyed_){
            destroy();
        }
    }

    void MeshParticleEmitter::addMeshVariant(const std::string& meshName){
        mMeshVariants_.push_back(meshName);
        if(mPoolSize_ > 0 && !mPoolInitialised_){
            initPool_();
        }
    }

    void MeshParticleEmitter::setPoolSize(int size){
        mPoolSize_ = size;
        if(!mMeshVariants_.empty() && !mPoolInitialised_){
            initPool_();
        }
    }

    void MeshParticleEmitter::setGravity(float gravity){
        mGravity_ = gravity;
    }

    void MeshParticleEmitter::setRenderQueueGroup(Ogre::uint32 group){
        mRenderQueueGroup_ = group;
    }

    void MeshParticleEmitter::initPool_(){
        if(mPoolInitialised_ || mMeshVariants_.empty() || mPoolSize_ <= 0) return;
        mPoolInitialised_ = true;

        mPool_.resize(mPoolSize_);
        size_t numVariants = mMeshVariants_.size();

        for(int i = 0; i < mPoolSize_; i++){
            Ogre::SceneNode* node = mParentNode_->createChildSceneNode();
            node->setVisible(false);
            node->setScale(Ogre::Vector3::ZERO);

            const std::string& meshName = mMeshVariants_[i % numVariants];

            Ogre::NameValuePairList params;
            params["mesh"] = meshName;
            params["resourceGroup"] = Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME;

            Ogre::MovableObject* obj = mSceneManager_->createMovableObject(
                Ogre::VoxMeshItemFactory::FACTORY_TYPE_NAME,
                &(mSceneManager_->_getEntityMemoryManager(Ogre::SCENE_DYNAMIC)),
                &params
            );

            if(mRenderQueueGroup_ > 0){
                obj->setRenderQueueGroup(mRenderQueueGroup_);
            }
            node->attachObject(obj);

            MeshParticle particle;
            particle.node = node;
            particle.velX = 0.0f;
            particle.velY = 0.0f;
            particle.velZ = 0.0f;
            particle.age = 0;
            particle.maxAge = 0;
            particle.startScale = 1.0f;
            particle.endScale = 0.0f;
            particle.active = false;

            mPool_[i] = particle;
        }
    }

    int MeshParticleEmitter::acquireSlot_(){
        int poolSize = static_cast<int>(mPool_.size());
        for(int i = 0; i < poolSize; i++){
            int idx = (mNextFreeHint_ + i) % poolSize;
            if(!mPool_[idx].active){
                mNextFreeHint_ = (idx + 1) % poolSize;
                return idx;
            }
        }
        //Pool exhausted — no slot available
        return -1;
    }

    void MeshParticleEmitter::emit(float x, float y, float z,
                                   float velX, float velY, float velZ,
                                   int maxLifetime,
                                   float startScale, float endScale,
                                   float rotX, float rotY, float rotZ){
        if(!mPoolInitialised_) return;

        int slot = acquireSlot_();
        if(slot < 0) return;

        MeshParticle& p = mPool_[slot];
        p.velX = velX;
        p.velY = velY;
        p.velZ = velZ;
        p.age = 0;
        p.maxAge = maxLifetime;
        p.startScale = startScale;
        p.endScale = endScale;
        p.active = true;

        p.node->setPosition(x, y, z);
        p.node->setScale(startScale, startScale, startScale);

        Ogre::Quaternion quat =
            Ogre::Quaternion(Ogre::Radian(rotX), Ogre::Vector3::UNIT_X) *
            Ogre::Quaternion(Ogre::Radian(rotY), Ogre::Vector3::UNIT_Y) *
            Ogre::Quaternion(Ogre::Radian(rotZ), Ogre::Vector3::UNIT_Z);
        p.node->setOrientation(quat);

        p.node->setVisible(true);
    }

    void MeshParticleEmitter::update(){
        if(!mPoolInitialised_) return;

        int poolSize = static_cast<int>(mPool_.size());
        for(int i = 0; i < poolSize; i++){
            MeshParticle& p = mPool_[i];
            if(!p.active) continue;

            p.age++;
            p.velY -= mGravity_;

            Ogre::Vector3 pos = p.node->getPosition();
            pos.x += p.velX;
            pos.y += p.velY;
            pos.z += p.velZ;
            p.node->setPosition(pos);

            float lifetimeRatio = 1.0f - (static_cast<float>(p.age) / static_cast<float>(p.maxAge));
            float scale = p.endScale + (p.startScale - p.endScale) * lifetimeRatio;
            p.node->setScale(scale, scale, scale);

            if(p.age >= p.maxAge || pos.y < -10.0f){
                p.active = false;
                p.node->setVisible(false);
            }
        }
    }

    void MeshParticleEmitter::clear(){
        for(size_t i = 0; i < mPool_.size(); i++){
            if(mPool_[i].active){
                mPool_[i].active = false;
                mPool_[i].node->setVisible(false);
            }
        }
        mNextFreeHint_ = 0;
    }

    void MeshParticleEmitter::destroy(){
        if(mDestroyed_) return;
        mDestroyed_ = true;

        for(size_t i = 0; i < mPool_.size(); i++){
            if(mPool_[i].node){
                //Destroy all attached movable objects
                Ogre::SceneNode::ObjectIterator it = mPool_[i].node->getAttachedObjectIterator();
                while(it.hasMoreElements()){
                    Ogre::MovableObject* obj = it.getNext();
                    mSceneManager_->destroyMovableObject(obj);
                }
                mPool_[i].node->detachAllObjects();
                mPool_[i].node->removeAndDestroyAllChildren();
                mSceneManager_->destroySceneNode(mPool_[i].node);
                mPool_[i].node = nullptr;
            }
        }
        mPool_.clear();
    }

}
