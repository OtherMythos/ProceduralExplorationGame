::EntityFactory <- class{
    mBaseSceneNode_ = null
    mCharacterGenerator_ = null
    mConstructorWorld_ = null;
    mMobScale_ = Vec3(0.2, 0.2, 0.2)

    COLLISION_DETECTION_RADIUS = 1;

    constructor(constructorWorld, parentSceneNode, characterGenerator){
        mConstructorWorld_ = constructorWorld;
        mBaseSceneNode_ = parentSceneNode;
        mCharacterGenerator_ = characterGenerator;
    }

    function getZForPos(pos){
        return mConstructorWorld_.getZForPos(pos);
    }

    function readBoolFromData_(data, val, defaultVal){
        if(data == null){
            return defaultVal;
        }
        if(data.rawin(val)){
            return data.rawget(val);
        }
        return defaultVal;
    }
    function constructNPCCharacter(pos, data){
        local manager = mConstructorWorld_.getEntityManager();
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local en = manager.createEntity(targetPos);

        local playerEntry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.NONE, targetPos, en);

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerModel = mCharacterGenerator_.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
        playerNode.setScale(0.5, 0.5, 0.5);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](playerNode));
        playerEntry.setModel(playerModel);

        manager.assignComponent(en, EntityComponents.SCRIPT, ::EntityManager.Components[EntityComponents.SCRIPT](::BasicEnemyScript(en, readBoolFromData_(data, "idleWalk", false))));

        playerEntry.setPosition(targetPos);

        return playerEntry;
    }

    function constructBillboard_(entity, manager, node, screen, maxHealth){
        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        local billboard = ::BillboardManager.HealthBarBillboard(screen.mWindow_, worldMask, maxHealth);
        local billboardIdx = screen.mWorldMapDisplay_.mBillboardManager_.trackNode(node, billboard);
        manager.assignComponent(entity, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));
        return billboard;
    }

    function constructPlayer(explorationScreen, playerStats, ghostPlayer=false){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = Vec3();
        local en = manager.createEntity(targetPos);
        local playerEntry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.NONE, targetPos, en);

        local clonedBlock = ::DatablockManager.quickCloneDatablock("baseVoxelMaterial");
        manager.assignComponent(en, EntityComponents.DATABLOCK, ::EntityManager.Components[EntityComponents.DATABLOCK](clonedBlock));

        local playerNode = mBaseSceneNode_.createChildSceneNode();
        local playerModel = mCharacterGenerator_.createCharacterModel(playerNode, {"type": CharacterModelType.HUMANOID}, RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY, 0, clonedBlock);
        playerNode.setScale(0.5, 0.5, 0.5);
        //_component.sceneNode.add(en, playerNode);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](playerNode));
        playerEntry.setModel(playerModel);
        playerEntry.setCombatData(playerStats.mPlayerCombatStats);
        playerEntry.setWieldActive(playerStats.getWieldActive());
        playerEntry.setTargetCollisionWorld(_COLLISION_ENEMY);

        playerEntry.setId(-1);

        if(!::Base.isProfileActive(GameProfile.PLAYER_GHOST) && !ghostPlayer){
            local triggerWorld = mConstructorWorld_.getTriggerWorld();
            local collisionPoint = triggerWorld.addCollisionReceiver(null, 0, 0, 1.5, _COLLISION_PLAYER);

            local combatTargetWorld = mConstructorWorld_.getCombatTargetWorld();
            local combatTargetPoint = combatTargetWorld.addCollisionSender(CollisionWorldTriggerResponses.BASIC_ENEMY_PLAYER_TARGET_RADIUS, en, targetPos.x, targetPos.z, 6, _COLLISION_ENEMY);
            local combatTargetProjectilePoint = combatTargetWorld.addCollisionSender(CollisionWorldTriggerResponses.BASIC_ENEMY_PLAYER_TARGET_RADIUS_PROJECTILE, en, targetPos.x, targetPos.z, 20, _COLLISION_ENEMY);

            local damageWorld = mConstructorWorld_.getDamageWorld();
            local damagePoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);

            manager.assignComponent(en, EntityComponents.COLLISION_POINT_FOUR,
                ::EntityManager.Components[EntityComponents.COLLISION_POINT_FOUR](
                    collisionPoint, damagePoint, combatTargetPoint, combatTargetProjectilePoint
                    triggerWorld, damageWorld, combatTargetWorld, combatTargetWorld
                )
            );

            local collisionRadius = 1.5;
            manager.assignComponent(en, EntityComponents.COLLISION_DETECTION, ::EntityManager.Components[EntityComponents.COLLISION_DETECTION](collisionRadius));
        }

        /*
        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        local healthBarBillboard = ::BillboardManager.HealthBarBillboard(explorationScreen.mWindow_, worldMask);
        healthBarBillboard.setPercentage(playerStats.getPlayerHealthPercentage());
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(playerNode, healthBarBillboard);
        manager.assignComponent(en, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));
        */
        local playerBillboard = constructBillboard_(en, manager, playerNode, explorationScreen, playerStats.getPlayerMaxHealth());
        //_component.user[Component.MISC].add(en);
        //_component.user[Component.MISC].set(en, 0, billboardIdx);

        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](playerStats.getPlayerHealth()));
        playerBillboard.setHealth(playerStats.getPlayerHealth());

        //_component.script.add(en, "res://src/Content/Enemies/PlayerScript.nut");

        return playerEntry;
    }

    function constructEnemyBaseBeehive_(pos, explorationScreen){
        local manager = mConstructorWorld_.getEntityManager();
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local en = manager.createEntity(targetPos);
        local entry = ActiveEnemyEntry(mConstructorWorld_, EnemyId.BEE_HIVE, targetPos, en);

        local enemyNode = mBaseSceneNode_.createChildSceneNode();
        local mesh = _gameCore.createVoxMeshItem("beeHive.voxMesh");
        mesh.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
        enemyNode.attachObject(mesh);
        enemyNode.setScale(0.15, 0.15, 0.15);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](enemyNode, true));

        local enemyStats = ::Enemies[EnemyId.BEE_HIVE].getStats();
        local maxHealth = enemyStats.getHealth();

        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](maxHealth));

        constructBillboard_(en, manager, enemyNode, explorationScreen, maxHealth);

        local damageWorld = mConstructorWorld_.getDamageWorld();
        local damagePoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);

        local combatTargetWorld = mConstructorWorld_.getCombatTargetWorld();
        local combatTargetPoint = combatTargetWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);

        manager.assignComponent(en, EntityComponents.COLLISION_POINT_TWO,
            ::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO](
                damagePoint, combatTargetPoint,
                damageWorld, combatTargetWorld
            )
        );

        local hiveScript = ::BeeHiveScript(en);
        manager.assignComponent(en, EntityComponents.SCRIPT, ::EntityManager.Components[EntityComponents.SCRIPT](hiveScript));

        for(local i = 0; i < 3; i++){
            local offset = _random.randVec3()-0.5;
            offset.y = 0;
            local beeEntity = mConstructorWorld_.createEnemy(EnemyId.BEE, pos + (offset * 15));
            hiveScript.registerBee(beeEntity);
        }

        entry.setPosition(targetPos);

        return entry;
    }

    function checkEnemyCollisionPlacement(x, y){
        local collisionWorld = mConstructorWorld_.getCollisionDetectionWorld();
        return !(collisionWorld.checkCollisionPoint(x, y, COLLISION_DETECTION_RADIUS));
    }

    function constructEnemyBase_(enemyType, pos, explorationScreen){
        local enemyDef = ::Enemies[enemyType];
        local enemyStats = enemyDef.getStats();

        local manager = mConstructorWorld_.getEntityManager();
        local zPos = getZForPos(pos);
        local targetPos = Vec3(pos.x, zPos, pos.z);
        local en = manager.createEntity(targetPos);
        local entry = ActiveEnemyEntry(mConstructorWorld_, enemyType, targetPos, en);

        local clonedBlock = ::DatablockManager.quickCloneDatablock("baseVoxelMaterial");
        manager.assignComponent(en, EntityComponents.DATABLOCK, ::EntityManager.Components[EntityComponents.DATABLOCK](clonedBlock));

        local enemyNode = mBaseSceneNode_.createChildSceneNode();

        local modelType = enemyDef.getModelType();
        local characterModel = mCharacterGenerator_.createCharacterModel(enemyNode, {"type": modelType}, RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY_DANGEROUS, 1 << 4, clonedBlock);

        entry.setTargetCollisionWorld(_COLLISION_PLAYER);

        //TODO add a component for the character model.
        enemyNode.setScale(0.5, 0.5, 0.5);
        //_component.sceneNode.add(en, enemyNode);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](enemyNode));
        entry.setModel(characterModel);

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local playerSpottedOutline = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED, en, targetPos.x, targetPos.z, 32, _COLLISION_PLAYER);

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

        local traversable = enemyDef.getTraversableTerrain();
        if(traversable != EnemyTraversableTerrain.ALL){
            manager.assignComponent(en, EntityComponents.TRAVERSABLE_TERRAIN, ::EntityManager.Components[EntityComponents.TRAVERSABLE_TERRAIN](traversable));
        }

        local totalHealth = enemyStats.getHealth();
        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](totalHealth));

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](3000 + _random.randInt(100)));

        //local collisionRadius = 1;
        manager.assignComponent(en, EntityComponents.COLLISION_DETECTION, ::EntityManager.Components[EntityComponents.COLLISION_DETECTION](COLLISION_DETECTION_RADIUS));

        /*
        local worldMask = (0x1 << mConstructorWorld_.getWorldId());
        local billboard = ::BillboardManager.HealthBarBillboard(explorationScreen.mWindow_, worldMask)
        local billboardIdx = explorationScreen.mWorldMapDisplay_.mBillboardManager_.trackNode(enemyNode, billboard);
        manager.assignComponent(en, EntityComponents.BILLBOARD, ::EntityManager.Components[EntityComponents.BILLBOARD](billboardIdx));
        */
        constructBillboard_(en, manager, enemyNode, explorationScreen, totalHealth);

        //_component.script.add(en, "res://src/Content/Enemies/BasicEnemyScript.nut");
        local scriptObj = null;
        if(enemyType == EnemyId.BEE){
            scriptObj = ::BeeEnemyScript(en)
        }else{
            scriptObj = ::BasicEnemyScript(en)
        }
        assert(scriptObj != null);
        manager.assignComponent(en, EntityComponents.SCRIPT, ::EntityManager.Components[EntityComponents.SCRIPT](scriptObj));

        //local machine = ::BasicEnemyMachine(en);
        //::w.e.rawset(en.getId(), machine);

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
            entry.setCombatData(combatData);
        }else{
            local combatData = ::Combat.CombatStats();
            entry.setCombatData(combatData);
        }

        entry.setWieldActive(false);

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.SPOILS_DATA, spoilsData, null, null);
        mConstructorWorld_.getEntityManager().assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        return entry;
    }
    //Perform enemy type specific logic.
    function constructEnemy(enemyType, pos, explorationScreen){
        local enemy = null;
        switch(enemyType){
            case EnemyId.BEE_HIVE:{
                enemy = constructEnemyBaseBeehive_(pos, explorationScreen);
                break;
            }
            default:{
                enemy = constructEnemyBase_(enemyType, pos, explorationScreen);
                break;
            }
        }

        return enemy;
    }

    function constructSimpleTeleportItem(parentNode, meshPath, pos, scale, teleData, collisionRadius=null, forceZ=null){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        if(forceZ != null){
            targetPos.y = forceZ;
        }else{
            targetPos.y = getZForPos(targetPos);
        }
        local en = manager.createEntity(targetPos);

        local placeNode = parentNode.createChildSceneNode();
        placeNode.setPosition(targetPos);
        //TODO make some of these scene static
        local item = _gameCore.createVoxMeshItem(meshPath);
        local targetQueue = RENDER_QUEUE_EXPLORATION;
        if(teleData.rawin("renderQueue")){
            targetQueue = teleData.renderQueue;
        }
        item.setRenderQueueGroup(targetQueue);
        placeNode.attachObject(item);
        placeNode.setScale(scale, scale, scale);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local targetRadius = 4;
        if(teleData.rawin("radius")){
            targetRadius = teleData.radius;
        }
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION, teleData, targetPos.x, targetPos.z, targetRadius, _COLLISION_PLAYER);

        if(collisionRadius != null){
            local detectionWorld = mConstructorWorld_.getCollisionDetectionWorld();
            local collisionDetectionPoint = detectionWorld.
                addCollisionPoint(targetPos.x, targetPos.z, collisionRadius, 0xFF, _COLLISION_WORLD_ENTRY_SENDER);

            manager.assignComponent(en, EntityComponents.COLLISION_POINT_TWO ::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO](
                collisionPoint, collisionDetectionPoint,
                triggerWorld, detectionWorld
            ));
        }else{
            manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));
        }

        return en;
    }
    function constructSimpleItem(parentNode, meshPath, pos, scale, collisionRadius=null, spoilData=null, totalHealth=null, orientation=null, posOffset=null, forceZ=null){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        if(forceZ != null){
            targetPos.y = forceZ;
        }else{
            targetPos.y = getZForPos(targetPos);
        }
        local en = manager.createEntity(targetPos);

        //local entry = ActiveEnemyEntry(mConstructorWorld_, itemData.type, targetPos, en);

        local placeNode = parentNode.createChildSceneNode();
        //local meshTarget = itemData.type == PlacedItemId.CHERRY_BLOSSOM_TREE ? "treeCherryBlossom.voxMesh" : "tree.voxMesh";
        placeNode.setPosition(targetPos);
        //TODO make some of these scene static
        local attachNode = placeNode;
        if(posOffset != null){
            local offsetNode = placeNode.createChildSceneNode();
            offsetNode.setPosition(posOffset);
            attachNode = offsetNode;
        }
        local item = _gameCore.createVoxMeshItem(meshPath);
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        attachNode.attachObject(item);
        placeNode.setScale(scale, scale, scale);
        if(orientation != null){
            placeNode.setOrientation(orientation);
        }
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local damageWorld = mConstructorWorld_.getDamageWorld();
        local combatTargetWorld = mConstructorWorld_.getCombatTargetWorld();
        local collisionPoint = null;
        local combatTargetPoint = null;
        if(totalHealth != null){
            collisionPoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);
            combatTargetPoint = combatTargetWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);
        }

        if(collisionRadius != null){
            local collisionDetectionWorld = mConstructorWorld_.getCollisionDetectionWorld();
            local collisionDetectionPoint = collisionDetectionWorld.addCollisionPoint(targetPos.x, targetPos.z, collisionRadius, 0xFF, _COLLISION_WORLD_ENTRY_SENDER);

            if(collisionPoint != null){
                manager.assignComponent(en, EntityComponents.COLLISION_POINT_THREE, ::EntityManager.Components[EntityComponents.COLLISION_POINT_THREE](
                    collisionPoint, combatTargetPoint, collisionDetectionPoint,
                    damageWorld, combatTargetWorld, collisionDetectionWorld
                ));
            }else{
                manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionDetectionPoint, collisionDetectionWorld));
            }
        }else{
            if(collisionPoint != null){
                manager.assignComponent(en, EntityComponents.COLLISION_POINT_TWO, ::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO](
                    collisionPoint, combatTargetPoint,
                    damageWorld, combatTargetWorld
                ));
            }
        }

        if(spoilData != null){
            local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.SPOILS_DATA, spoilData, null, null);
            manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);
        }
        if(totalHealth != null){
            manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](totalHealth));
        }

        return en;
    }
    function constructPlacedItem(parentNode, itemData, idx=0){
        local itemType = itemData.type;
        local d = ::PlacedItems[itemType];

        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = Vec3(itemData.originX, 0, -itemData.originY);
        targetPos.y = getZForPos(targetPos);
        local en = manager.createEntity(targetPos);

        if(d.mPosOffset != null){
            targetPos += d.mPosOffset;
        }

        //local entry = ActiveEnemyEntry(mConstructorWorld_, itemData.type, targetPos, en);

        local placeNode = parentNode.createChildSceneNode(_SCENE_STATIC);
        local meshTarget = d.mMesh;
        placeNode.setPosition(targetPos);
        local item = _gameCore.createVoxMeshItem(meshTarget, HLMS_PACKED_VOXELS | HLMS_PACKED_OFFLINE_VOXELS | HLMS_TREE_VERTICES, _SCENE_STATIC);
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        //_gameCore.writeFlagsToItem(item, HLMS_PACKED_VOXELS | HLMS_PACKED_OFFLINE_VOXELS | HLMS_TREE_VERTICES);
        placeNode.attachObject(item);
        local scale = d.mScale;
        placeNode.setScale(scale, scale, scale);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local damageWorld = mConstructorWorld_.getDamageWorld();
        local collisionPoint = damageWorld.addCollisionReceiver(en, targetPos.x, targetPos.z, 2, _COLLISION_ENEMY);
        if(itemType == PlacedItemId.CACTUS){
            local damageSender = damageWorld.addCollisionSender(CollisionWorldTriggerResponses.PASSIVE_DAMAGE, 5, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);

            manager.assignComponent(en, EntityComponents.COLLISION_POINT_TWO, ::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO](
                collisionPoint, damageSender,
                damageWorld, damageWorld
            ));
        }
        else if(
            itemType == PlacedItemId.TREE_APPLE || itemType == PlacedItemId.PALM_TREE_COCONUTS ||
            itemType == PlacedItemId.BERRY_BUSH_BERRIES
        ){
            local triggerWorld = mConstructorWorld_.getTriggerWorld();
            local playerInteraction = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.PICK, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);

            manager.assignComponent(en, EntityComponents.COLLISION_POINT_TWO, ::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO](
                collisionPoint, playerInteraction,
                damageWorld, triggerWorld
            ));

            local targetChange = null;
            local targetItem = null;
            if(itemType == PlacedItemId.TREE_APPLE){
                targetChange = PlacedItemId.TREE;
                targetItem = ItemId.APPLE;
            }
            else if(itemType == PlacedItemId.PALM_TREE_COCONUTS){
                targetChange = PlacedItemId.PALM_TREE;
                targetItem = ItemId.COCONUT;
            }
            else if(itemType == PlacedItemId.BERRY_BUSH_BERRIES){
                targetChange = PlacedItemId.BERRY_BUSH;
                targetItem = ItemId.RED_BERRIES;
            }
            assert(targetChange != null);
            assert(targetItem != null);

            local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.PICK_KEEP_PLACED_ITEM, ::Item(targetItem), targetChange, null, EntityDestroyReason.CONSUMED);
            manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);
        }else if(
            itemType == PlacedItemId.FLOWER_RED ||
            itemType == PlacedItemId.FLOWER_WHITE ||
            itemType == PlacedItemId.FLOWER_PURPLE
        ){
            local triggerWorld = mConstructorWorld_.getTriggerWorld();
            local playerInteraction = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.PICK, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);

            manager.assignComponent(en, EntityComponents.COLLISION_POINT_TWO, ::EntityManager.Components[EntityComponents.COLLISION_POINT_TWO](
                collisionPoint, playerInteraction,
                damageWorld, triggerWorld
            ));

            local flowerItem = ItemId.FLOWER_RED;
            if(itemType == PlacedItemId.FLOWER_RED) flowerItem = ItemId.FLOWER_RED;
            else if(itemType == PlacedItemId.FLOWER_WHITE) flowerItem = ItemId.FLOWER_WHITE;
            else if(itemType == PlacedItemId.FLOWER_PURPLE) flowerItem = ItemId.FLOWER_PURPLE;

            local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.GIVE_ITEM, ::Item(flowerItem), null, null);
            manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);
        }else{
            manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, damageWorld));
        }

        local totalHealth = 100;
        manager.assignComponent(en, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](totalHealth));

        //entry.setPosition(targetPos);

        //return entry;
    }

    function constructPlace(placeData, idx, explorationScreen=null){
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
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        placeNode.attachObject(item);
        placeNode.setScale(0.3, 0.3, 0.3);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](placeNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.OVERWORLD_VISITED_PLACE, idx, targetPos.x, targetPos.z, 4, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        /*
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
        */

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
        //local item = _gameCore.createVoxMeshItem("EXPOrbMesh");
        local item = _scene.createItem(::expOrbMesh);
        _gameCore.writeFlagsToItem(item, 0x1);
        item.setDatablock("baseVoxelMaterial");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
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
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
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
        local item = _scene.createItem(::expOrbMesh);
        _gameCore.writeFlagsToItem(item, 0x1);
        item.setDatablock("baseVoxelMaterial");
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

    function constructOrb(orbId, pos){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local found = ::Base.mPlayerStats.isOrbFound(orbId);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setPosition(targetPos);
        local item = _scene.createItem(::expOrbMesh);
        _gameCore.writeFlagsToItem(item, 0x1);
        if(!found){
            item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
        }
        item.setDatablock(found ? "foundOrbMaterial" : "baseVoxelMaterial");
        parentNode.setScale(1.5, 1.5, 1.5);
        local animNode = parentNode.createChildSceneNode();
        animNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("EXPOrbAnim", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.GIVE_ORB, orbId, null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

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
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
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
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
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
        local item = _scene.createItem("cube");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
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
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
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
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.COLLECTABLE_ITEM_COLLIDE, en, targetPos.x, targetPos.z, 2, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.GIVE_ITEM, wrappedItem, null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        local animationInfo = _animation.createAnimationInfo([animNode]);
        local anim = _animation.createAnimation("CollectableItemAnimation", animationInfo);
        anim.setTime(_random.randInt(0, 180));
        manager.assignComponent(en, EntityComponents.ANIMATION, ::EntityManager.Components[EntityComponents.ANIMATION](anim));

        return en;
    }

    function constructChestObject(pos, spoils=null){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local parentNode = mBaseSceneNode_.createChildSceneNode();
        parentNode.setScale(0.15, 0.15, 0.15);
        parentNode.setPosition(targetPos);
        local item = _gameCore.createVoxMeshItem("treasureChestBase.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
        local baseNode = parentNode.createChildSceneNode();
        baseNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.DIE, en, targetPos.x, targetPos.z, 4, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        local spoilsData = spoils;
        if(spoilsData == null){
            spoilsData = [
                SpoilsEntry(SPOILS_ENTRIES.EXP_ORBS, 2 + _random.randInt(16)),
                SpoilsEntry(SPOILS_ENTRIES.COINS, 24 + _random.randInt(12)),
            ];
        }
        local spoilsComponent = ::EntityManager.Components[EntityComponents.SPOILS](SpoilsComponentType.SPOILS_DATA, spoilsData, null, null);
        manager.assignComponent(en, EntityComponents.SPOILS, spoilsComponent);

        local lidNode = parentNode.createChildSceneNode();
        item = _gameCore.createVoxMeshItem("treasureChestLid.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
        lidNode.attachObject(item);
        lidNode.setPosition(0, 6, 0);

        lidNode.setOrientation(Quat(-0.5, ::Vec3_UNIT_X));

        return en;

    }

    function constructChestObjectInventory(pos, node, inventory, inventoryWidth, inventoryHeight){
        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        //local parentNode = mBaseSceneNode_.createChildSceneNode();
        local parentNode = node;
        parentNode.setScale(0.15, 0.15, 0.15);
        parentNode.setPosition(targetPos);
        local item = _gameCore.createVoxMeshItem("treasureChestBase.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        //item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        local baseNode = parentNode.createChildSceneNode();
        baseNode.attachObject(item);
        manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));

        local triggerWorld = mConstructorWorld_.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.ITEM_SEARCH, en, targetPos.x, targetPos.z, 4, _COLLISION_PLAYER);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](collisionPoint, triggerWorld));

        local inventoryItemsComponent = ::EntityManager.Components[EntityComponents.INVENTORY_ITEMS](inventory, inventoryWidth, inventoryHeight);
        manager.assignComponent(en, EntityComponents.INVENTORY_ITEMS, inventoryItemsComponent);

        local lidNode = parentNode.createChildSceneNode();
        item = _gameCore.createVoxMeshItem("treasureChestLid.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        lidNode.attachObject(item);
        lidNode.setPosition(0, 6, 0);

        lidNode.setOrientation(Quat(-0.5, ::Vec3_UNIT_X));

        return en;

    }

    function constructProjectile(projectileId, pos, dir, combatMove, collisionType=_COLLISION_ENEMY){
        local projData = ::Projectiles[projectileId];

        local manager = mConstructorWorld_.getEntityManager();
        local targetPos = pos.copy();
        targetPos.y = getZForPos(targetPos);

        local en = manager.createEntity(targetPos);

        local damageWorld = mConstructorWorld_.getDamageWorld();
        local collisionPoint = damageWorld.addCollisionSender(CollisionWorldTriggerResponses.PROJECTILE_DAMAGE, combatMove, targetPos.x, targetPos.z, projData.mSize.x, collisionType);
        manager.assignComponent(en, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](
            collisionPoint,
            damageWorld
        ));

        if(projData.mMesh != null){
            local parentNode = mBaseSceneNode_.createChildSceneNode();
            local mesh = _scene.createItem(projData.mMesh);
            mesh.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_EFFECTS);
            mesh.setCastsShadows(false);
            local animNode = parentNode.createChildSceneNode();
            if(projData.mModelScale != null){
                animNode.setScale(projData.mModelScale);
            }
            parentNode.setPosition(targetPos);
            animNode.setPosition(0, 2, 0);
            animNode.attachObject(mesh);

            if(dir != null){
                local radian = atan2(-dir.x, -dir.z);
                local quat = Quat(radian, ::Vec3_UNIT_Y);
                parentNode.setOrientation(quat);
            }

            manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](parentNode, true));
        }

        if(dir != null){
            manager.assignComponent(en, EntityComponents.MOVEMENT, ::EntityManager.Components[EntityComponents.MOVEMENT](dir));
        }

        manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](projData.mLifetime));

        return en;
    }

};