::EntityFactory <- {

    function createGoblinEnemy(pos){
        local e = _entity.createTracked(pos);
        if(!e.valid()) return;

        local parentNode = _scene.getRootSceneNode().createChildSceneNode();
        local createdItem = _scene.createItem("goblin.mesh");
        createdItem.setRenderQueueGroup(50);
        parentNode.attachObject(createdItem);
        _component.sceneNode.add(e, parentNode, true);

        return e;
    }

    function createPlayer(pos){
        local e = _entity.create(pos);
        if(!e.valid()) return;

        local parentNode = _scene.getRootSceneNode().createChildSceneNode();
        local createdItem = _scene.createItem("player.mesh");
        createdItem.setRenderQueueGroup(50);
        parentNode.attachObject(createdItem);
        _component.sceneNode.add(e, parentNode, true);

        return e;
    }

};