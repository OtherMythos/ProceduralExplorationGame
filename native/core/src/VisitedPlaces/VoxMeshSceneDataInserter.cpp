#include "VoxMeshSceneDataInserter.h"

#include "Ogre.h"
#include "System/BaseSingleton.h"
#include "Ogre/OgreVoxMeshItem.h"
#include "Collision/CollisionDetectionWorld.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    VoxMeshSceneDataInserter::VoxMeshSceneDataInserter(Ogre::SceneManager* sceneManager, ProceduralExplorationGameCore::CollisionDetectionWorld* detectionWorld, const Ogre::Vector3& offset)
        : AV::AVSceneDataInserter(sceneManager),
        mCollisionWorld(detectionWorld),
        mOffset(offset) {

    }

    VoxMeshSceneDataInserter::~VoxMeshSceneDataInserter(){

    }

    bool VoxMeshSceneDataInserter::insertUserObject(AV::uint8 idx, const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent){
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
        else if(idx == 2){
            Ogre::Vector3 parentPos = parent->_getDerivedPositionUpdated();
            Ogre::Vector3 parentScale = parent->_getDerivedScaleUpdated();

            const std::string& v = strings[d.idx];
            const Ogre::Vector2 targetPos(parentPos.x + mOffset.x, parentPos.z + mOffset.z);
            //const Ogre::Vector3 targetScale(parentScale * d.scale);
            const Ogre::Vector3 targetScale(parentScale * d.scale);
            if(v == "0"){
                mCollisionWorld->addCollisionPoint(targetPos.x, targetPos.y, targetScale.x);
            }
            else if(v == "1"){
                mCollisionWorld->addCollisionRectangle(targetPos.x - targetScale.x / 2, targetPos.y - targetScale.y / 2, targetScale.x*2, targetScale.z*2);
            }
        }

        return true;
    }

}
