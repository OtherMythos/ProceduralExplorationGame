#include "VoxMeshSceneDataInserter.h"

#include "Ogre.h"
#include "System/BaseSingleton.h"
#include "Ogre/OgreVoxMeshItem.h"
#include "Collision/CollisionDetectionWorld.h"

namespace ProceduralExplorationGameCore{

    VoxMeshSceneDataInserter::VoxMeshSceneDataInserter(Ogre::SceneManager* sceneManager, ProceduralExplorationGameCore::CollisionDetectionWorld* detectionWorld)
        : AV::AVSceneDataInserter(sceneManager),
        mCollisionWorld(detectionWorld) {

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

            parent->attachObject(obj);
        }
        else if(idx == 2){
            Ogre::Vector3 parentPos = parent->_getDerivedPositionUpdated();
            mCollisionWorld->addCollisionPoint(parentPos.x + d.pos.x, parentPos.z + d.pos.z, d.scale.x);
        }

        return true;
    }

}
