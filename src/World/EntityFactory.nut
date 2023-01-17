::EntityFactory <- {

    function createGoblinEnemy(pos){
        local e = _entity.createTracked(pos);
        if(!e.valid()) return;

        local parentNode = _scene.getRootSceneNode().createChildSceneNode();
        local createdItem = _scene.createItem("goblin.mesh");
        createdItem.setRenderQueueGroup(50);
        parentNode.attachObject(createdItem);
        _component.sceneNode.add(e, parentNode, true);



        local senderTable = {
            "func" : "receivePlayerSpotted",
            "path" : "res://src/World/Entities/WorldEnemyEntity.nut"
            "id" : 100,
            "type" : _COLLISION_PLAYER,
            "event" : _COLLISION_ENTER | _COLLISION_LEAVE | _COLLISION_INSIDE
        };

        local shape = _physics.getCubeShape(32, 8, 32);
        local collisionObject = _physics.collision[TRIGGER].createSender(senderTable, shape, pos);
        _physics.collision[TRIGGER].addObject(collisionObject);

        senderTable["func"] = "receivePlayerInner";
        local innerShape = _physics.getCubeShape(4, 4, 4);
        local innerCollisionObject = _physics.collision[TRIGGER].createSender(senderTable, innerShape, pos);
        _physics.collision[TRIGGER].addObject(innerCollisionObject);

        _component.collision.add(e, collisionObject, innerCollisionObject);




        _component.script.add(e, "res://src/World/Entities/WorldEnemyEntity.nut");

        local machine = WorldEnemyEntity();
        machine.entity = e;
        ::w.e.rawset(e.getId(), machine);

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


        local receiverInfo = {
            "type" : _COLLISION_PLAYER
        };
        local shape = _physics.getSphereShape(4);

        local collisionObject = _physics.collision[TRIGGER].createReceiver(receiverInfo, shape);
        _physics.collision[TRIGGER].addObject(collisionObject);

        _component.collision.add(e, collisionObject);

        return e;
    }

};