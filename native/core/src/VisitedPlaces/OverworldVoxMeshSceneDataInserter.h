#pragma once

#include <map>

#include "World/Slot/Recipe/AvScene/AvSceneParsedData.h"

#include "Animation/AnimationData.h"

namespace Ogre{
    class SceneNode;
    class SceneManager;
}

namespace ProceduralExplorationGameCore{

    /**
    A class to insert a parsed avScene file into a scene node.
    */
    class OverworldVoxMeshSceneDataInserter{
    public:
        OverworldVoxMeshSceneDataInserter(Ogre::SceneManager* sceneManager);
        ~OverworldVoxMeshSceneDataInserter();

        /**
        Insert a compiled scene into the specified node.
        */
        void insertSceneData(AV::ParsedSceneFile* data, Ogre::SceneNode* node);

        /**
        Insert a compiled scene into the specified node, while returning an animation data object.
        */
        AV::AnimationInfoBlockPtr insertSceneDataGetAnimInfo(AV::ParsedSceneFile* data, Ogre::SceneNode* node);

        /**
        Insert a user type object into the scene.
        */
        virtual bool insertUserObject(AV::uint8 idx, const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent);

    private:
        size_t _insertSceneData(size_t index, size_t& createdObjectCount, size_t parentCount, AV::ParsedSceneFile* data, Ogre::SceneNode* parent);
        Ogre::SceneNode* _createObject(const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, size_t parentCount, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent);

        Ogre::SceneManager* mSceneManager;

        AV::AnimationInfoEntry animInfo[AV::MAX_ANIMATION_INFO];
        AV::AnimationInfoTypeHash animHash;
        AV::uint8 animHighestIdx = 0;

        std::map<int,Ogre::SceneNode*> mOutNodes;

    public:
        const std::map<int,Ogre::SceneNode*>& getRegionNodes() const{
            return mOutNodes;
        }
    };
}
