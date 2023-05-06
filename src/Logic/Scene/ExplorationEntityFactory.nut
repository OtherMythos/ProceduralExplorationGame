::ExplorationEntityFactory <- {
    mBaseSceneNode_ = null,
    mMobScale_ = Vec3(0.2, 0.2, 0.2),

    function constructPlayer(){
        local playerEntry = ::ExplorationLogic.ActiveEnemyEntry(Enemy.NONE, Vec2(0, 0));

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerItem = _scene.createItem("player.mesh");
        playerItem.setRenderQueueGroup(30);
        playerNode.attachObject(playerItem);
        playerNode.setScale(mMobScale_);

        playerEntry.setEnemyNode(playerNode);

        local receiverInfo = {
            "type" : _COLLISION_PLAYER
        };
        local shape = _physics.getSphereShape(2);

        local collisionObject = _physics.collision[TRIGGER].createReceiver(receiverInfo, shape);
        _physics.collision[TRIGGER].addObject(collisionObject);
        playerEntry.setCollisionShapes(collisionObject, null);

        playerEntry.setId(-1);

        {
            local senderTable = {
                "func" : "baseDamage",
                "path" : "res://src/Logic/Scene/ExplorationDamageCallback.nut"
                "type" : _COLLISION_ENEMY,
                "event" : _COLLISION_ENTER
            };
            local shape = _physics.getCubeShape(1, 1, 1);
            local collisionObject = _physics.collision[DAMAGE].createSender(senderTable, shape);
            _physics.collision[DAMAGE].addObject(collisionObject);
            playerEntry.setDamageShape(collisionObject);
        }

        return playerEntry;
    }

    function constructEnemy(enemyId, pos){
        local entry = ::ExplorationLogic.ActiveEnemyEntry(enemyId, Vec3(pos.x, 0, pos.z));

        local enemyNode = mBaseSceneNode_.createChildSceneNode();
        local enemyItem = _scene.createItem("goblin.mesh");
        enemyItem.setRenderQueueGroup(30);
        enemyNode.attachObject(enemyItem);
        //local zPos = getZForPos(enemy.mPos_);
        local zPos = 0;
        //local pos = Vec3(enemy.mPos_.x, zPos, enemy.mPos_.z);
        enemyNode.setPosition(pos);
        enemyNode.setScale(mMobScale_);

        local senderTable = {
            "func" : "receivePlayerSpotted",
            "path" : "res://src/Logic/Scene/ExplorationSceneEntityScript.nut",
            "id" : 0,
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

        {
            local receiverInfo = {
                "type" : _COLLISION_ENEMY
            };
            local shape = _physics.getSphereShape(2);

            local collisionObject = _physics.collision[DAMAGE].createReceiver(receiverInfo, shape);
            _physics.collision[DAMAGE].addObject(collisionObject);

            entry.setDamageShape(collisionObject);
        }

        entry.setCollisionShapes(innerCollisionObject, collisionObject);
        entry.setEnemyNode(enemyNode);
        entry.setPosition(pos);

        return entry;
    }

};