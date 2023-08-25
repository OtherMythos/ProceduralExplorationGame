::World.EntityFactory <- class{
    mBaseSceneNode_ = null
    mCharacterGenerator_ = null
    mConstructorWorld_ = null;
    mMobScale_ = Vec3(0.2, 0.2, 0.2)

    constructor(constructorWorld, parentSceneNode, characterGenerator){
        mConstructorWorld_ = constructorWorld;
        mBaseSceneNode_ = parentSceneNode;
        mCharacterGenerator_ = characterGenerator;
    }

    function getZForPos(pos){
        return mConstructorWorld_.getZForPos(pos);
    }

    function constructNPCCharacter(){
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local playerEntry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.NONE, Vec3(0, 0, 0), en);

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerModel = mCharacterGenerator_.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, 30);
        playerNode.setScale(0.5, 0.5, 0.5);
        _component.sceneNode.add(en, playerNode);
        playerEntry.setModel(playerModel);

        local equipped = ::Combat.EquippedItems();
        local targetItem = ::Item(ItemId.SIMPLE_TWO_HANDED_SWORD);
        equipped.setEquipped(targetItem, EquippedSlotTypes.LEFT_HAND);
        local combatData = ::Combat.CombatStats(EnemyId.NONE, 0, equipped);
        playerEntry.setTargetCollisionWorld(_COLLISION_ENEMY);

        playerEntry.setId(-1);

        return playerEntry;
    }

    function constructPlayer(explorationScreen){
//testCount = 0;
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local playerEntry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.NONE, Vec3(0, 0, 0), en);

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerModel = mCharacterGenerator_.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, 30);
        playerNode.setScale(0.5, 0.5, 0.5);
        _component.sceneNode.add(en, playerNode);
        playerEntry.setModel(playerModel);

        local equipped = ::Combat.EquippedItems();
        local targetItem = ::Item(ItemId.SIMPLE_TWO_HANDED_SWORD);
        equipped.setEquipped(targetItem, EquippedSlotTypes.LEFT_HAND);
        local combatData = ::Combat.CombatStats(EnemyId.NONE, 0, equipped);
        //TODO tie this up a bit better with the rest of the code.
        playerModel.equipToNode(targetItem, CharacterModelEquipNodeType.LEFT_HAND);
        playerModel.equipToNode(::Item(ItemId.SIMPLE_SHIELD), CharacterModelEquipNodeType.RIGHT_HAND);
        playerEntry.setCombatData(combatData);
        playerEntry.setTargetCollisionWorld(_COLLISION_ENEMY);

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionReceiver(0, 0, 1.5, _COLLISION_PLAYER);

        local receiverInfo = {
            "type" : _COLLISION_PLAYER
        };
        local shape = _physics.getSphereShape(2);

        local collisionObject = _physics.collision[TRIGGER].createReceiver(receiverInfo, shape);
        _physics.collision[TRIGGER].addObject(collisionObject);

        //
            local receiverInfo = {
                "type" : _COLLISION_PLAYER
            };
            local shape = _physics.getSphereShape(2.1);

            local damageReceiver = _physics.collision[DAMAGE].createReceiver(receiverInfo, shape);
            _physics.collision[DAMAGE].addObject(damageReceiver);
        //

        playerEntry.setId(-1);

        playerEntry.setCollisionPoint(collisionPoint);

        _component.collision.add(en, collisionObject, damageReceiver);

        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(playerNode, ::BillboardManager.HealthBarBillboard(explorationScreen.mWindow_));
        _component.user[Component.MISC].add(en);
        _component.user[Component.MISC].set(en, 0, billboardIdx);

        local totalHealth = 100;
        _component.user[Component.HEALTH].add(en);
        _component.user[Component.HEALTH].set(en, 0, totalHealth);
        _component.user[Component.HEALTH].set(en, 1, totalHealth);

        _component.script.add(en, "res://src/Content/Enemies/PlayerScript.nut");

        return playerEntry;
    }

    function constructEnemyBase_(enemyType, pos, explorationScreen){
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local entry = ActiveEnemyEntry(mConstructorWorld_, enemyType, targetPos, en);

        local enemyNode = mBaseSceneNode_.createChildSceneNode();

        //TODO in future have entity defs which contain this information.
        local modelType = CharacterModelType.GOBLIN;
        if(enemyType == EnemyId.SQUID){
            modelType = CharacterModelType.SQUID;
        }
        local characterModel = mCharacterGenerator_.createCharacterModel(enemyNode, {"type": modelType}, 30, 1 << 4);

        entry.setTargetCollisionWorld(_COLLISION_PLAYER);

        enemyNode.setScale(0.5, 0.5, 0.5);
        _component.sceneNode.add(en, enemyNode);
        entry.setModel(characterModel);

        local senderTable = {
            "func" : "receivePlayerSpotted",
            "path" : "res://src/Content/Enemies/BasicEnemyScript.nut",
            "type" : _COLLISION_PLAYER,
            "event" : _COLLISION_ENTER | _COLLISION_LEAVE | _COLLISION_INSIDE
        };
        local shape = _physics.getCubeShape(16, 4, 16);
        local collisionObject = _physics.collision[TRIGGER].createSender(senderTable, shape, pos);
        _physics.collision[TRIGGER].addObject(collisionObject);

        senderTable["func"] = "receivePlayerInner";
        local innerShape = _physics.getCubeShape(3, 3, 3);
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

        local totalHealth = 10;
        _component.user[Component.HEALTH].add(en);
        _component.user[Component.HEALTH].set(en, 0, totalHealth);
        _component.user[Component.HEALTH].set(en, 1, totalHealth);

        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(enemyNode, ::BillboardManager.HealthBarBillboard(explorationScreen.mWindow_));
        _component.user[Component.MISC].add(en);
        _component.user[Component.MISC].set(en, 0, billboardIdx);

        _component.script.add(en, "res://src/Content/Enemies/BasicEnemyScript.nut");

        local machine = ::BasicEnemyMachine(en);
        ::w.e.rawset(en.getId(), machine);

        return entry;

    }
    function constructEnemy(enemyType, pos, explorationScreen){
        local enemy = constructEnemyBase_(enemyType, pos, explorationScreen);

        if(enemyType == EnemyId.GOBLIN){
            local equipped = ::Combat.EquippedItems();
            local targetItem = ::Item(ItemId.SIMPLE_TWO_HANDED_SWORD);
            equipped.setEquipped(targetItem, EquippedSlotTypes.LEFT_HAND);
            local combatData = ::Combat.CombatStats(enemyType, 0, equipped);
            enemy.setCombatData(combatData);

            local goblinModel = enemy.getModel();
            //TODO tie this up a bit better with the rest of the code.
            goblinModel.equipToNode(targetItem, CharacterModelEquipNodeType.LEFT_HAND);
            //playerModel.equipToNode(::Item(ItemId.SIMPLE_SHIELD), CharacterModelEquipNodeType.LEFT_HAND);
            goblinModel.equipToNode(::Item(ItemId.SIMPLE_SWORD), CharacterModelEquipNodeType.LEFT_HAND);
            //goblinModel.equipToNode(::Item(ItemId.SIMPLE_TWO_HANDED_SWORD), CharacterModelEquipNodeType.LEFT_HAND);
            if(_random.randInt(2) == 0)goblinModel.equipToNode(::Item(ItemId.SIMPLE_SHIELD), CharacterModelEquipNodeType.RIGHT_HAND);
        }

        return enemy;
    }

    function constructPlacedItem(itemData, idx){
        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local targetPos = Vec3(itemData.originX, 0, -itemData.originY);
        targetPos.y = getZForPos(targetPos);

        local entry = ActiveEnemyEntry(mConstructorWorld_, itemData.type, targetPos, en);

        local placeNode = mBaseSceneNode_.createChildSceneNode();
        local meshTarget = itemData.type == PlacedItemId.CHERRY_BLOSSOM_TREE ? "treeCherryBlossom.mesh" : "tree.mesh";
        placeNode.setPosition(targetPos);
        local item = _scene.createItem(meshTarget);
        item.setRenderQueueGroup(30);
        placeNode.attachObject(item);
        placeNode.setScale(0.6, 0.6, 0.6);
        _component.sceneNode.add(en, placeNode, true);


        local receiverInfo = {
            "type" : _COLLISION_ENEMY
        };
        local shape = _physics.getSphereShape(2);
        local damageReceiver = _physics.collision[DAMAGE].createReceiver(receiverInfo, shape, targetPos);
        _physics.collision[DAMAGE].addObject(damageReceiver);
        _component.collision.add(en, damageReceiver);


        local totalHealth = 1;
        _component.user[Component.HEALTH].add(en);
        _component.user[Component.HEALTH].set(en, 0, totalHealth);
        _component.user[Component.HEALTH].set(en, 1, totalHealth);


        entry.setPosition(targetPos);

        return entry;
    }

    function constructPlace(placeData, idx, explorationScreen){
        //if(testCount > 0) return;
//testCount++;

        local en = _entity.create(SlotPosition());
        if(!en.valid()) throw "Error creating entity";
        local targetPos = Vec3(placeData.originX, 0, -placeData.originY);
        targetPos.y = getZForPos(targetPos);

        local entry = ActiveEnemyEntry(mConstructorWorld_, placeData.placeId, targetPos, en);

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

        local billboard = null;
        if(placeType == PlaceType.GATEWAY){
            billboard = ::BillboardManager.GatewayExplorationEndBillboard(explorationScreen.mWindow_);
        }else{
            billboard = ::BillboardManager.PlaceExplorationVisitBillboard(explorationScreen.mWindow_);
        }
        billboard.setVisible(false);
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(placeNode, billboard);
        _component.user[Component.MISC].add(en);
        _component.user[Component.MISC].set(en, 0, billboardIdx);


        entry.setPosition(targetPos);

        return entry;
    }

    function constructEXPOrb(pos){
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = _entity.create(SlotPosition(targetPos));
        if(!en.valid()) throw "Error creating entity";

        local placeNode = mBaseSceneNode_.createChildSceneNode();
        placeNode.setPosition(targetPos);
        placeNode.setScale(0.4, 0.4, 0.4);
        local item = _scene.createItem("EXPOrbMesh");
        item.setRenderQueueGroup(30);
        local animNode = placeNode.createChildSceneNode();
        animNode.attachObject(item);
        _component.sceneNode.add(en, placeNode, true);

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.EXP_ORB, en.getId(), targetPos.x, targetPos.z, 1.5, _COLLISION_PLAYER);

        _component.lifetime.add(en, 600);

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("EXPOrbAnim", animationInfo);

        anim.setTime(_random.randInt(0, 180));

        _component.animation.add(en, anim);

        return en;
    }

};