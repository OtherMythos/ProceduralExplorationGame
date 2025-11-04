#include "OverworldVoxMeshSceneDataInserter.h"

#include <OgreSceneNode.h>
#include <OgreSceneManager.h>

#include "World/Slot/Recipe/AvScene/AvSceneFileParser.h"
#include "System/BaseSingleton.h"
#include "Animation/AnimationManager.h"
#include <regex>

#include "Ogre/OgreVoxMeshItem.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    OverworldVoxMeshSceneDataInserter::OverworldVoxMeshSceneDataInserter(Ogre::SceneManager* sceneManager)
        : mSceneManager(sceneManager) {

    }

    OverworldVoxMeshSceneDataInserter::~OverworldVoxMeshSceneDataInserter(){

    }

    //TODO in theory I could have a different data type which avoids the animation entries.
    AV::AnimationInfoBlockPtr OverworldVoxMeshSceneDataInserter::insertSceneDataGetAnimInfo(AV::ParsedSceneFile* data, Ogre::SceneNode* node){
        memset(&animInfo, 0, sizeof(animInfo));
        animHash = 0;

        size_t startIdx = 0;
        size_t createdObjectCount = 0;
        size_t parentCount = 0;
        size_t end = _insertSceneData(startIdx, createdObjectCount, parentCount, data, node);
        assert(end == data->objects.size());

        if(animHash == 0){
            return 0;
        }

        assert(animHighestIdx > 0);
        AV::AnimationInfoBlockPtr ptr = AV::BaseSingleton::getAnimationManager()->createAnimationInfoBlock(animInfo, animHighestIdx, animHash);

        return ptr;
    }

    void OverworldVoxMeshSceneDataInserter::insertSceneData(AV::ParsedSceneFile* data, Ogre::SceneNode* node){
        size_t startIdx = 0;
        size_t createdObjectCount = 0;
        size_t parentCount = 0;
        size_t end = _insertSceneData(startIdx, createdObjectCount, parentCount, data, node);
        assert(end == data->objects.size());
    }

    size_t OverworldVoxMeshSceneDataInserter::_insertSceneData(size_t index, size_t& createdObjectCount, size_t parentCount, AV::ParsedSceneFile* data, Ogre::SceneNode* parent){
        Ogre::SceneNode* previousNode = 0;

        size_t current = index;
        for(; current < data->objects.size(); current+=0){
            const AV::SceneObjectEntry& entry = data->objects[current];
            if(entry.type == AV::SceneObjectType::Child){
                assert(previousNode);
                current = _insertSceneData(current + 1, createdObjectCount, parentCount+1, data, previousNode);
                continue;
            }else if(entry.type == AV::SceneObjectType::Term){
                return current + 1;
            }else{
                const AV::SceneObjectData& sceneObjData = data->data[createdObjectCount];
                previousNode = _createObject(entry, sceneObjData, parentCount, data->strings, parent);
                createdObjectCount++;
                current++;
            }
        }

        return current;
    }

    bool extractRegionNumber(const std::string& input, int& number){
        std::regex pattern("^region-(\\d+)$");  // matches "region-" followed by one or more digits
        std::smatch match;

        if(std::regex_match(input, match, pattern)){
            number = std::stoi(match[1]);
            return true;
        }
        return false;
    }

    Ogre::SceneNode* OverworldVoxMeshSceneDataInserter::_createObject(const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, size_t parentCount, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent){
        Ogre::SceneNode* newNode = parent->createChildSceneNode();

        switch(e.type){
            case AV::SceneObjectType::Empty:{
                if(d.name >= 0 && parentCount == 0){
                    const std::string& name = strings[d.name];

                    int number = 0;
                    if(extractRegionNumber(name, number)){
                        mOutNodes[number] = newNode;
                    }
                }
                break;
            }
            case AV::SceneObjectType::Mesh:{
                const Ogre::String& meshName = strings[d.idx];
                Ogre::Item *item = mSceneManager->createItem(meshName, Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME, Ogre::SCENE_DYNAMIC);
                newNode->attachObject((Ogre::MovableObject*)item);
                break;
            }
            case AV::SceneObjectType::User0:{
                insertUserObject(0, e, d, strings, newNode);
                break;
            }
            case AV::SceneObjectType::User1:{
                insertUserObject(1, e, d, strings, newNode);
                break;
            }
            case AV::SceneObjectType::User2:{
                insertUserObject(2, e, d, strings, newNode);
                break;
            }
            default:{
                assert(false);
            }
        }

        newNode->setPosition(d.pos);
        newNode->setScale(d.scale);
        newNode->setOrientation(d.orientation);

        if(d.animIdx != AV::AVSceneFileParserInterface::NONE_ANIM_IDX){
            assert(d.animIdx < AV::MAX_ANIMATION_INFO);
            animInfo[d.animIdx].sceneNode = newNode;
            animHash |= AV::ANIM_INFO_SCENE_NODE << AV::MAX_ANIMATION_INFO_BITS*d.animIdx;
            //This doesn't check for holes but just keeps track of the highest index.
            if(d.animIdx+1 > animHighestIdx){
                animHighestIdx = d.animIdx+1;
            }
        }

        return newNode;
    }

    bool OverworldVoxMeshSceneDataInserter::insertUserObject(AV::uint8 idx, const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent){
        if(idx == 0){
            const Ogre::String& meshName = strings[d.idx];

            Ogre::NameValuePairList params;
            params["mesh"] = meshName;
            params["resourceGroup"] = Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME;
            Ogre::MovableObject *obj;
            Ogre::SceneManager* sceneManager = AV::BaseSingleton::getSceneManager();

            Ogre::SceneMemoryMgrTypes targetType = Ogre::SCENE_DYNAMIC;
            //WRAP_OGRE_ERROR(
                obj = sceneManager->createMovableObject(Ogre::VoxMeshItemFactory::FACTORY_TYPE_NAME, &(sceneManager->_getEntityMemoryManager(targetType)), &params);
            //)

            obj->setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
            parent->attachObject(obj);
        }

        return true;
    }
}
