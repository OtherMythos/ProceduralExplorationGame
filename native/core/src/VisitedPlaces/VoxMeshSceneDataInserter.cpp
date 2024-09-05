#include "VoxMeshSceneDataInserter.h"

#include "Ogre.h"
#include "System/BaseSingleton.h"
#include "Ogre/OgreVoxMeshItem.h"

namespace ProceduralExplorationGameCore{

    VoxMeshSceneDataInserter::VoxMeshSceneDataInserter(Ogre::SceneManager* sceneManager)
        : AV::AVSceneDataInserter(sceneManager) {

    }

    VoxMeshSceneDataInserter::~VoxMeshSceneDataInserter(){

    }

    bool VoxMeshSceneDataInserter::insertUserObject(const AV::SceneObjectEntry& e, const AV::SceneObjectData& d, const std::vector<Ogre::String>& strings, Ogre::SceneNode* parent){
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

        return true;
    }

}
