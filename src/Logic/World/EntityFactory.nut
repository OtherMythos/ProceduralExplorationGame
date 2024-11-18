::EntityFactory <- class{
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

    function constructNPCCharacter(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local en = manager.createEntity(targetPos);

        local playerEntry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.NONE, targetPos, en);

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerModel = mCharacterGenerator_.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, 30);
        playerNode.setScale(0.5, 0.5, 0.5);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](playerNode));
        playerEntry.setModel(playerModel);

        manager.assignComponent(en, EntityComponents.SCRIPT, ::EntityManager.Components[EntityComponents.SCRIPT](::BasicEnemyScript(en)));

        playerEntry.setPosition(targetPos);

        return playerEntry;
    }

    function constructPlayer(explorationScreen, playerStats){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = Vec3();
        local en = manager.createEntity(targetPos);
        local playerEntry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.NONE, targetPos, en);

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerModel = mCharacterGenerator_.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, 30);
        playerNode.setScale(0.5, 0.5, 0.5);
        //_component.sceneNode.add(en, playerNode);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](playerNode));
        playerEntry.setModel(playerModel);
        playerEntry.setCombatData(playerStats.mPlayerCombatStats);
        playerEntry.setWieldActive(playerStats.getWieldActive());
        playerEntry.setTargetCollisionWorld(_COLLISION_ENEMY);

        playerEntry.setId(-1);

        if(!::Base.isProfileActive(GameProfile.PLAYER_GHOST)){
            local triggerWorld = mConstructorWorld_.getTriggerWorld();
            local collisionPoint = triggerWorld.addCollisionReceiver(null, 0, 0, 1.5, _COLLISION_PLAYER);

            local combatTargetWorld = mConstructorWorld_.getCombatTargetWorld();
            local combatTargetPoint = combatTargetWorld.addCollisionSender(CollisionWorldTriggerResponses.BASIC_ENEMY_PLAYER_TARGET_RADIUS, en, targetPos.x, targetPos.z, 10, _COLLISION_ENEMY);

            local damageWorld = mConstructorWorld_.getDamageWorld();
            local damagePoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);

            manager.assignComponent(en, EntityComponents.COLLISION_POINT_THREE,
                ::EntityManager.Components[EntityComponents.COLLISION_POINT_THREE](
                    collisionPoint, damagePoint, combatTargetPoint,
                    triggerWorld, damageWorld, combatTargetWorld
                )
            );
        }

        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        local healthBarBillboard = ::BillboardManager.HealthBarBillboard(explorationScreen.mWindow_, worldMask);
        healthBarBillboard.setPercentage(playerStats.getPlayerHealthPercentage());
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(playerNode, healthBarBillboard);
        manager.assignComponent(en, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));
        //_component.user[Component.MISC].add(en);
        //_component.user[Component.MISC].set(en, 0, billboardIdx);

        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](playerStats.getPlayerHealth()));

        //_component.script.add(en, "res://src/Content/Enemies/PlayerScript.nut");

        return playerEntry;
    }

    function constructEnemyBase_(enemyType, pos, explorationScreen){
        local enemyDef = ::Enemies[enemyType];

        local manager = mConstructorWorld_.getEntityManager();
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local en = manager.createEntity(targetPos);
        local entry = ActiveEnemyEntry(mConstructorWorld_, enemyType, targetPos, en);

        local enemyNode = mBaseSceneNode_.createChildSceneNode();

        local modelType = enemyDef.getModelType();
        local characterModel = mCharacterGenerator_.createCharacterModel(enemyNode, {"type": modelType}, 30, 1 << 4);

        entry.setTargetCollisionWorld(_COLLISION_PLAYER);

        //TODO add a component for the character model.
        enemyNode.setScale(0.5, 0.5, 0.5);
        //_component.sceneNode.add(en, enemyNode);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](enemyNode));
        entry.setModel(characterModel);

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local playerSpottedOutline = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED, en, targetPos.x, targetPos.z, 16, _COLLISION_PLAYER);

        local damageWorld = mConstructorWorld_.getDamageWorld();
        local damagePoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);
        //manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](damagePoint, damageWorld));

        local combatTargetWorld = mConstructorWorld_.getCombatTargetWorld();
        local combatTargetPoint = combatTargetWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);

        manager.assignComponent(en, EntityComponents.COLLISION_POINT_THREE,
            ::EntityManager.Components[EntityComponents.COLLISION_POINT_THREE](
                playerSpottedOutline, damagePoint, combatTargetPoint,
                triggerWorld, damageWorld, combatTargetWorld
            )
        );

        entry.setPosition(targetPos);

        local totalHealth = 60;
        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](totalHealth));

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](3000 + _random.randInt(100)));

        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        local billboard = ::BillboardManager.HealthBarBillboard(explorationScreen.mWindow_, worldMask)
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(enemyNode, billboard);
        manager.assignComponent(en, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));

        //_component.script.add(en, "res://src/Content/Enemies/BasicEnemyScript.nut");
        manager.assignComponent(en, EntityComponents.SCRIPT, ::EntityManager.Components[EntityComponents.SCRIPT](::BasicEnemyScript(en)));

        //local machine = ::BasicEnemyMachine(en);
        //::w.e.rawset(en.getId(), machine);

        return entry;
    }
    //Perform enemy type specific logic.
    function constructEnemy(enemyType, pos, explorationScreen){
        local enemy = constructEnemyBase_(enemyType, pos, explorationScreen);

        local spoilsData = [
            ::SpoilsEntry(SPOILS_ENTRIES.EXP_ORBS, 4 + _random.randInt(4)),
            ::SpoilsEntry(SPOILS_ENTRIES.COINS, _random.randInt(4)),
        ];

        local combatEquipped = null;
        if(enemyType == EnemyId.GOBLIN){
            combatEquipped = ::Combat.EquippedItems();
            local targetItem = ::Item(ItemId.SIMPLE_TWO_HANDED_SWORD);
            combatEquipped.setEquipped(targetItem, EquippedSlotTypes.RIGHT_HAND);
            if(_random.randInt(2) == 0) combatEquipped.setEquipped(::Item(ItemId.SIMPLE_SHIELD), EquippedSlotTypes.LEFT_HAND);

            if(_random.randInt(2) == 0) spoilsData.append(::SpoilsEntry(SPOILS_ENTRIES.DROPPED_ITEMS, ::Item(ItemId.SIMPLE_SWORD)));
        }
        else if(enemyType == EnemyId.SKELETON){
            combatEquipped = ::Combat.EquippedItems();
            combatEquipped.setEquipped(::Item(ItemId.BONE_MACE), EquippedSlotTypes.RIGHT_HAND);

            if(_random.randInt(2) == 0) spoilsData.append(::SpoilsEntry(SPOILS_ENTRIES.DROPPED_ITEMS, ::Item(ItemId.BONE_MACE)));
        }

        if(combatEquipped != null){
            local combatData = ::Combat.CombatStats(enemyType, 0, combatEquipped);
            combatEquipped.calculateEquippedStats();
            enemy.setCombatData(combatData);
        }

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.SPOILS_DATA, spoilsData, null, null);
        mConstructorWorld_.getEntityManager().assignComponent(enemy.getEntity(), EntityComponents.SPOILS, spoilsComponent);

        return enemy;
    }

    function getMeshForPlacedItemType_(item){
        switch(item){
            case PlacedItemId.CHERRY_BLOSSOM_TREE:{
                return "treeCherryBlossom.voxMesh";
            }
            case PlacedItemId.CACTUS:{
                return "cactus1.voxMesh";
            }
            default:{
                return "tree.voxMesh";
            }
        }
    }
    function getScaleForPlacedItemType_(item){
        switch(item){
            case PlacedItemId.CACTUS:{
                return 0.3;
            }
            default:
                return 0.6;
        }
    }
    function constructPlacedItem(parentNode, itemData, idx){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = Vec3(itemData.originX, 0, -itemData.originY);
        targetPos.y = getZForPos(targetPos);
        local en = manager.createEntity(targetPos);

        //local entry = ActiveEnemyEntry(mConstructorWorld_, itemData.type, targetPos, en);

        local placeNode = parentNode.createChildSceneNode();
        //local meshTarget = itemData.type == PlacedItemId.CHERRY_BLOSSOM_TREE ? "treeCherryBlossom.voxMesh" : "tree.voxMesh";
        local meshTarget = getMeshForPlacedItemType_(itemData.type);
        placeNode.setPosition(targetPos);
        //TODO make some of these scene static
        local item = _gameCore.createVoxMeshItem(meshTarget);
        item.setRenderQueueGroup(30);
        placeNode.attachObject(item);
        local scale = getScaleForPlacedItemType_(itemData.type);
        placeNode.setScale(scale, scale, scale);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local damageWorld = mConstructorWorld_.getDamageWorld();
        local collisionPoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, damageWorld));

        local totalHealth = 1;
        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](totalHealth));

        //entry.setPosition(targetPos);

        //return entry;
    }

    function constructPlace(placeData, idx, explorationScreen){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = Vec3(placeData.originX, 0, -placeData.originY);
        targetPos.y = getZForPos(targetPos);
        local en = manager.createEntity(targetPos);

        local entry = ActiveEnemyEntry(mConstructorWorld_, placeData.placeId, targetPos, en);

        local placeNode = mBaseSceneNode_.createChildSceneNode();
        local placeType = ::Places[placeData.placeId].getType();
        local meshTarget = "overworldVillage.voxMesh";
        if(placeType == PlaceType.TOWN && placeType == PlaceType.CITY) meshTarget = "overworldTown.voxMesh";
        else if(placeType == PlaceType.GATEWAY) meshTarget = "overworldGateway.voxMesh";

        placeNode.setPosition(targetPos);
        local item = _gameCore.createVoxMeshItem(meshTarget);
        item.setRenderQueueGroup(30);
        placeNode.attachObject(item);
        placeNode.setScale(0.3, 0.3, 0.3);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.OVERWORLD_VISITED_PLACE, idx, targetPos.x, targetPos.z, 4, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        local billboard = null;
        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        if(placeType == PlaceType.GATEWAY){
            billboard = ::BillboardManager.GatewayExplorationEndBillboard(explorationScreen.mWindow_, worldMask);
        }else{
            billboard = ::BillboardManager.PlaceExplorationVisitBillboard(explorationScreen.mWindow_, worldMask);
        }
        billboard.setVisible(false);
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(placeNode, billboard);

        manager.assignComponent(en, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));

        entry.setPosition(targetPos);

        return entry;
    }

    function constructEXPOrb(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local placeNode = mBaseSceneNode_.createChildSceneNode();
        placeNode.setPosition(targetPos);
        placeNode.setScale(0.4, 0.4, 0.4);
        local item = _scene.createItem("EXPOrbMesh");
        item.setRenderQueueGroup(30);
        local animNode = placeNode.createChildSceneNode();
        animNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.EXP_ORB, en, targetPos.x, targetPos.z, 4, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](500 + _random.randInt(100)));

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("EXPOrbAnim", animationInfo);
        anim.setTime(_random.randInt(0, 180));

        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        return en;
    }

    function constructPercentageEncounter(pos, explorationScreen){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);
        local RADIUS = 4 + _random.randInt(4, 8);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setPosition(targetPos);
        local item = _scene.createItem("Cylinder.mesh");
        item.setDatablock("PercentageEncounterCylinder");
        item.setCastsShadows(false);
        item.setRenderQueueGroup(30);
        parentNode.attachObject(item);
        //Add a bit of offset to the top to avoid z fighting.
        parentNode.setScale(RADIUS, 9 + _random.rand(), RADIUS);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local spoilsFirst = ::PercentageEncounterData(PercentageEncounterEntryType.ENEMY, 3, EnemyId.GOBLIN);
        local spoilsSecond = ::PercentageEncounterData(PercentageEncounterEntryType.EXP, 50, null);
        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.PERCENTAGE, 50, spoilsFirst, spoilsSecond);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        local billboard = ::BillboardManager.PercentageEncounterBillboard(spoilsComponent, explorationScreen.mWindow_, worldMask);
        //billboard.setVisible(false);
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(parentNode, billboard);

        manager.assignComponent(en, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](1000 + _random.randInt(250)));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, RADIUS, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        return en;
    }

    function constructEXPTrailEncounter(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setPosition(targetPos);
        local item = _scene.createItem("EXPOrbMesh");
        item.setRenderQueueGroup(30);
        parentNode.setScale(1.5, 1.5, 1.5);
        local animNode = parentNode.createChildSceneNode();
        animNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("EXPOrbAnim", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.EXP_TRAIL, 15 + _random.randInt(25), null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](1000 + _random.randInt(250)));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        return en;
    }

    function constructHealthOrbEncounter(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setPosition(targetPos);
        local item = _scene.createItem("HealthOrbMesh");
        item.setRenderQueueGroup(30);
        parentNode.setScale(1.5, 1.5, 1.5);
        local animNode = parentNode.createChildSceneNode();
        local scaleNode = animNode.createChildSceneNode();
        scaleNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local animationInfo = _animation.createAnimationInfo([animNode, scaleNode]);
        local anim = _animation.createAnimation("HealthOrbAnim", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.ADD_HEALTH, 2 + _random.randInt(15), null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](1000 + _random.randInt(250)));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        return en;
    }

    function constructMoneyObject(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setPosition(targetPos);
        local item = _gameCore.createVoxMeshItem("coin.voxMesh");
        item.setRenderQueueGroup(30);
        local animNode = parentNode.createChildSceneNode();
        animNode.setScale(0.1, 0.1, 0.1);
        animNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("CoinAnim", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.GIVE_MONEY, 1, null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](1000 + _random.randInt(250)));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        return en;
    }

    function constructPlaceIndicatorBeacon(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setPosition(targetPos);
        local item = _scene.createItem("EXPOrbMesh");
        item.setRenderQueueGroup(30);
        local animNode = parentNode.createChildSceneNode();
        animNode.attachObject(item);
        animNode.setScale(1.5, 100, 1.5);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        manager.assignComponent(en, EntityComponents.PROXIMITY, ::EntityManager.Components[EntityComponents.PROXIMITY](ProximityComponentType.PLAYER, ::GenericCallbacks.placeBeaconDistance));

        local block = ::DatablockManager.cloneDatablock("PlaceBeacon", en);
        item.setDatablock(block);
        manager.assignComponent(en, EntityComponents.DATABLOCK, ::EntityManager.Components[EntityComponents.DATABLOCK](block));

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("PlaceBeaconIdle", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        return en;
    }

    function constructCollectableItemObject(pos, wrappedItem){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local OBJECT_SCALE = 0.1;
        //Construct this first so we know the radius to offset by.
        local item = _gameCore.createVoxMeshItem(wrappedItem.getMesh());
        targetPos.y += item.getLocalRadius() * OBJECT_SCALE;

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setScale(OBJECT_SCALE, OBJECT_SCALE, OBJECT_SCALE);
        parentNode.setPosition(targetPos);
        local particleSystem = _scene.createParticleSystem("particle_collectableItem");
        local animNode = parentNode.createChildSceneNode();
        animNode.attachObject(item);
        animNode.attachObject(particleSystem);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.GIVE_ITEM, wrappedItem, null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("CollectableItemAnimation", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        return en;
    }

    function constructChestObject(pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setScale(0.15, 0.15, 0.15);
        parentNode.setPosition(targetPos);
        local item = _gameCore.createVoxMeshItem("treasureChestBase.voxMesh");
        //item.setRenderQueueGroup(30);
        local baseNode = parentNode.createChildSceneNode();
        baseNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, 4, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        local spoilsData = [
            SpoilsEntry(SPOILS_ENTRIES.EXP_ORBS, 2 + _random.randInt(16)),
            SpoilsEntry(SPOILS_ENTRIES.COINS, 24 + _random.randInt(12)),
            SpoilsEntry(SPOILS_ENTRIES.SPAWN_ENEMIES, 1 + _random.randInt(2)),
        ];
        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.SPOILS_DATA, spoilsData, null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        local lidNode = parentNode.createChildSceneNode();
        item = _gameCore.createVoxMeshItem("treasureChestLid.voxMesh");
        lidNode.attachObject(item);
        lidNode.setPosition(0, 6, 0);

        lidNode.setOrientation(Quat(-0.5, ::Vec3_UNIT_X));

        return en;

    }

};