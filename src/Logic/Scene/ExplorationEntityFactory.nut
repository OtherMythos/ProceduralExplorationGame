::ExplorationEntityFactory <- {
    mBaseSceneNode_ = null,
    mMobScale_ = Vec3(0.2, 0.2, 0.2),

    function getZForPos(pos){
        return ::Base.mExplorationLogic.mSceneLogic_.getZForPos(pos);
    }

    function constructPlayer(){
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local playerEntry = ::ExplorationLogic.ActiveEnemyEntry(Enemy.NONE, Vec2(0, 0), en);

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerItem = _scene.createItem("player.mesh");
        playerItem.setRenderQueueGroup(30);
        playerNode.attachObject(playerItem);
        playerNode.setScale(mMobScale_);
        _component.sceneNode.add(en, playerNode, true);

        local receiverInfo = {
            "type" : _COLLISION_PLAYER
        };
        local shape = _physics.getSphereShape(2);

        local collisionObject = _physics.collision[TRIGGER].createReceiver(receiverInfo, shape);
        _physics.collision[TRIGGER].addObject(collisionObject);

        playerEntry.setId(-1);

        //
            local senderTable = {
                "func" : "baseDamage",
                "path" : "res://src/Logic/Scene/ExplorationDamageCallback.nut"
                "type" : _COLLISION_ENEMY,
                "event" : _COLLISION_ENTER
            };
            local shape = _physics.getCubeShape(1, 1, 1);
            local damageSender = _physics.collision[DAMAGE].createSender(senderTable, shape);
            _physics.collision[DAMAGE].addObject(damageSender);
        //

        _component.collision.add(en, collisionObject, damageSender);

        return playerEntry;
    }

    function constructEnemy(enemyId, enemyType, pos){
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local entry = ::ExplorationLogic.ActiveEnemyEntry(enemyType, targetPos, en);

        local enemyNode = mBaseSceneNode_.createChildSceneNode();
        local enemyItem = _scene.createItem("goblin.mesh");
        enemyItem.setRenderQueueGroup(30);
        enemyNode.attachObject(enemyItem);
        enemyNode.setScale(mMobScale_);
        _component.sceneNode.add(en, enemyNode, true);

        local senderTable = {
            "func" : "receivePlayerSpotted",
            "path" : "res://src/Logic/Scene/ExplorationSceneEntityScript.nut",
            "id" : enemyId,
            "type" : _COLLISION_PLAYER,
            "event" : _COLLISION_ENTER | _COLLISION_LEAVE | _COLLISION_INSIDE
        };
        local shape = _physics.getCubeShape(8, 4, 8);
        local collisionObject = _physics.collision[TRIGGER].createSender(senderTable, shape, pos);
        _physics.collision[TRIGGER].addObject(collisionObject);

        senderTable["func"] = "receivePlayerInner";
        local innerShape = _physics.getCubeShape(1, 1, 1);
        local innerCollisionObject = _physics.collision[TRIGGER].createSender(senderTable, innerShape, pos);
        _physics.collision[TRIGGER].addObject(innerCollisionObject);

        //
            local receiverInfo = {
                "type" : _COLLISION_ENEMY
            };
            local shape = _physics.getSphereShape(2);

            local damageReceiver = _physics.collision[DAMAGE].createReceiver(receiverInfo, shape, pos);
            _physics.collision[DAMAGE].addObject(damageReceiver);
        //

        _component.collision.add(en, collisionObject, innerCollisionObject, damageReceiver);

        entry.setPosition(targetPos);

        _component.user[Component.HEALTH].add(en);
        _component.user[Component.HEALTH].set(en, 0, 10);

        return entry;
    }

    function constructPlace(placeData, idx){
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local targetPos = Vec3(placeData.originX, 0, -placeData.originY);
        targetPos.y = getZForPos(targetPos);

        local entry = ::ExplorationLogic.ActiveEnemyEntry(placeData.placeId, targetPos, en);

        local placeNode = mBaseSceneNode_.createChildSceneNode();
        local placeType = ::Places[placeData.placeId].getType();
        local meshTarget = "overworldVillage.mesh";
        if(placeType == PlaceType.TOWN && placeType == PlaceType.CITY) meshTarget = "overworldTown.mesh";
        else if(placeType == PlaceType.GATEWAY) meshTarget = "overworldGateway.mesh";

        placeNode.setPosition(targetPos);
        local item = _scene.createItem(meshTarget);
        item.setRenderQueueGroup(30);
        placeNode.attachObject(item);
        placeNode.setScale(0.3, 0.3, 0.3);
        _component.sceneNode.add(en, placeNode, true);

        local senderTable = {
            "func" : "receivePlayerEntered",
            "path" : "res://src/Logic/Scene/ExplorationScenePlaceScript.nut"
            "id" : idx,
            "type" : _COLLISION_PLAYER,
            "event" : _COLLISION_ENTER | _COLLISION_LEAVE
        };
        local shape = _physics.getCubeShape(2, 8, 2);
        local collisionObject = _physics.collision[TRIGGER].createSender(senderTable, shape, targetPos);
        _physics.collision[TRIGGER].addObject(collisionObject);
        _component.collision.add(en, collisionObject);

        entry.setPosition(targetPos);

        return entry;
    }

};