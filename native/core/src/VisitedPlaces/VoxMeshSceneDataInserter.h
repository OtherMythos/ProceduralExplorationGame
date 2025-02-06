#pragma once

#include "VoxMeshSceneDataInserter.h"
#include "World/Slot/Recipe/AvScene/AvSceneDataInserter.h"

#include "Animation/AnimationData.h"

namespace ProceduralExplorationGameCore{

    class CollisionDetectionWorld;

    class VoxMeshSceneDataInserter : public AV::AVSceneDataInserter{
    public:
        VoxMeshSceneDataInserter(Ogre::SceneManager* sceneManager, ProceduralExplorationGameCore::CollisionDetectionWorld* detectionWorld);
        ~VoxMeshSceneDataInserter();

        /**
         Insert a single object into the scene. Can be overidden for custom objects.
         */
        virtual bool insertUserObject(AV::uint8 idx, const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent);
    private:
        CollisionDetectionWorld* mCollisionWorld;
    };
}
