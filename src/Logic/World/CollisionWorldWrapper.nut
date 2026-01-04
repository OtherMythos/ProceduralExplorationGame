

::_applyHealthChangeOther <- function(manager, entity, damage){
    if(!manager.entityValid(entity)) return;
    local component = manager.getComponent(entity, EntityComponents.HEALTH);
    local oldHealth = component.mHealth;
    if(oldHealth <= 0) return;
    local newHealth = oldHealth + damage;
    if(newHealth > component.mMaxHealth){
        newHealth = component.mMaxHealth;
    }
    if(newHealth < 0){
        newHealth = 0;
    }
    local newPercentage = newHealth.tofloat() / component.mMaxHealth.tofloat();
    assert(newHealth >= 0);

    if(manager.hasComponent(entity, EntityComponents.SCRIPT)){
        local scriptComponent = manager.getComponent(entity, EntityComponents.SCRIPT);
        local script = scriptComponent.mScript;
        if(script.rawin("healthChange")){
            script.healthChange(newHealth, newPercentage, damage);
        }
    }

    component.mHealth = newHealth;
    print("new health " + newHealth);

    //TODO get rid of this.
    ::Base.mExplorationLogic.mCurrentWorld_.notifyNewEntityHealth(entity, newHealth, oldHealth, newPercentage);

    //The player entity needs a special case for destruction.
    //The world will manage player destruction by itself.
    if(newHealth <= 0 && !manager.isPlayerEntity(entity)){
        manager.destroyEntity(entity);
    }
}
::_applyDamageOther <- function(manager, entity, damage){
    print("Applying damage " + damage);
    _applyHealthChangeOther(manager, entity, -damage);
}
::_applyHealthIncrease <- function(manager, entity, health){
    print("Applying health increase " + health);
    _applyHealthChangeOther(manager, entity, health);
}

/**
 * Wrapper for the engine's collision world objects.
 * This helps facilitate callback functions.
 */
::World.CollisionWorldWrapper <- class{

    TriggerResponse = class{
        mFunc_ = null;
        constructor(targetFunction){
            mFunc_ = targetFunction;
        }
        function trigger(world, triggerData, dataSecond, collisionStatus){
            mFunc_(world, triggerData, dataSecond, collisionStatus);
        }
    };

    mCollisionWorld_ = null;
    mParentWorld_ = null;

    mTriggerResponses_ = {};
    mTriggerData_ = null;
    mPoints_ = null;
    mPointsQueuedDestruction_ = null;
    mId_ = null;

    constructor(parentWorld, id){
        mParentWorld_ = parentWorld;
        mId_ = id;
        mCollisionWorld_ = CollisionWorld(_COLLISION_WORLD_OCTREE, mId_);

        //mTriggerResponses_ = {};
        mTriggerData_ = {};
        mPoints_ = {};
        mPointsQueuedDestruction_ = {};

    }

    function processCollision(){
        mCollisionWorld_.processCollision();

        for(local i = 0; i < mCollisionWorld_.getNumCollisions(); i++){
            local pair = mCollisionWorld_.getCollisionPairForIdx(i);
            local collisionStatus = (pair & 0xF000000000000000) >> 60;

            local first = pair & 0xFFFFFFF;
            local second = (pair >> 30) & 0xFFFFFFF;
            if(!mTriggerData_.rawin(first) || !mTriggerData_.rawin(second)) continue;

            local triggerResponseId = mPoints_[first];
            local response = mTriggerResponses_[triggerResponseId];
            local dataResponse = mTriggerData_[first];
            local dataSecond = mTriggerData_[second];

            response.trigger(mParentWorld_, dataResponse, dataSecond, collisionStatus);
        }

        foreach(c,i in mPointsQueuedDestruction_){
            checkPointDestruction(c);
        }
        mPointsQueuedDestruction_.clear();
    }

    function addCollisionSender(triggerId, triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_SENDER);
        assert(triggerId < CollisionWorldTriggerResponses.MAX);
        //assert(!mPoints_.rawin(pointId));
        if(mPointsQueuedDestruction_.rawin(pointId)){
            mPointsQueuedDestruction_.rawdelete(pointId);
        }
        assert(!mPointsQueuedDestruction_.rawin(pointId));

        printf("Registering sender with id %i for mask %i for world %i", pointId, mask, mId_);
        mPoints_.rawset(pointId, triggerId);
        //assert(!mTriggerData_.rawin(pointId));
        mTriggerData_.rawset(pointId, triggerData);
        return pointId;
    }

    function setPositionForPoint(id, x, y){
        mCollisionWorld_.setPositionForPoint(id, x, y);
    }

    function addCollisionReceiver(triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_RECEIVER);
        //assert(!mPoints_.rawin(pointId));
        if(mPointsQueuedDestruction_.rawin(pointId)){
            mPointsQueuedDestruction_.rawdelete(pointId);
        }
        assert(!mPointsQueuedDestruction_.rawin(pointId));

        printf("Registering receiver with id %i for mask %i for world %i", pointId, mask, mId_);
        //assert(!mTriggerData_.rawin(pointId));
        mTriggerData_.rawset(pointId, triggerData);

        return pointId;
    }

    function removeCollisionPoint(id){
        mCollisionWorld_.removeCollisionPoint(id);
        mPointsQueuedDestruction_.rawset(id, true);
    }

    function checkPointDestruction(id){
        mPoints_.rawdelete(id);
        assert(mTriggerData_.rawin(id));
        mTriggerData_.rawdelete(id);
    }

}

        //TODO see if I can populate these somewhere else.
        local TriggerResponse = ::World.CollisionWorldWrapper.TriggerResponse;
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.EXP_ORB] <- TriggerResponse(function(world, entityId, receiver, collisionStatus){
            world.processEXPOrb(entityId);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.OVERWORLD_VISITED_PLACE] <- TriggerResponse(function(world, id, receiver, collisionStatus){
            //TODO remove magic numbers.
            if(collisionStatus == 0x1){
                ::Base.mExplorationLogic.notifyPlaceEnterState(id, true);
            }
            else if(collisionStatus == 0x2){
                ::Base.mExplorationLogic.notifyPlaceEnterState(id, false);
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION] <- TriggerResponse(function(world, teleData, receiver, collisionStatus){
            if(collisionStatus == 0x1){
                ::Base.mActionManager.registerAction(teleData.actionType, 0, teleData, receiver);
            }
            else if(collisionStatus == 0x2){
                ::Base.mActionManager.unsetAction(0, receiver);
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.PROJECTILE_DAMAGE] <- TriggerResponse(function(world, combatMove, entityId, collisionStatus){
            if(collisionStatus != 0x1) return;

            local entityManager = world.getEntityManager();
            //assert(entityManager.hasComponent(projectileId, EntityComponents.LIFETIME));

            /*
            local active = world.mProjectileManager_.mActiveProjectiles_;
            //TODO can this be removed with the new collision system?
            //if(!active.rawin(projectileId)) return;
            local projData = active[projectileId];
            local damage = projData.mCombatMove_.getDamage();
            */

            //TODO this check should not be necessary and is a result of issues with the collision world.
            if(entityManager.entityValid(entityId)){
                combatMove.performOnEntity(entityId, world);
            }

            //entityManager.destroyEntity(projectileId);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.PASSIVE_DAMAGE] <- TriggerResponse(function(world, damage, entityId, collisionStatus){
            if(collisionStatus != 0x1) return;

            _applyDamageOther(world.getEntityManager(), entityId, damage);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x0) return;
            local manager = world.getEntityManager();
            if(!manager.entityValid(entityId)) return;
            assert(manager.hasComponent(entityId, EntityComponents.SCRIPT));
            local comp = manager.getComponent(entityId, EntityComponents.SCRIPT);
            if(collisionStatus == 0x1) comp.mScript.receivePlayerSpotted(true);
            else if(collisionStatus == 0x2) comp.mScript.receivePlayerSpotted(false);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.BASIC_ENEMY_PLAYER_TARGET_RADIUS] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x0) return;
            world.processEntityCombatTarget(second, collisionStatus == 0x1, false);
            /*
            local manager = world.getEntityManager();
            assert(manager.hasComponent(entityId, EntityComponents.SCRIPT));
            local comp = manager.getComponent(entityId, EntityComponents.SCRIPT);
            if(collisionStatus == 0x1) comp.mScript.receivePlayerSpotted(true);
            else if(collisionStatus == 0x2) comp.mScript.receivePlayerSpotted(false);
            */
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.BASIC_ENEMY_PLAYER_TARGET_RADIUS_PROJECTILE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x0) return;
            world.processEntityCombatTarget(second, collisionStatus == 0x1, true);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.DIE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus != 0x1) return;
            local manager = world.getEntityManager();
            manager.destroyEntity(entityId);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.COLLECTABLE_ITEM_COLLIDE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus != 0x1) return;
            if(!::Base.mPlayerStats.doesInventoryHaveFreeSlot()) return;
            local manager = world.getEntityManager();
            manager.destroyEntity(entityId);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.NPC_INTERACT] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x1){
                local manager = world.getEntityManager();
                assert(manager.hasComponent(entityId, EntityComponents.DIALOG));
                local comp = manager.getComponent(entityId, EntityComponents.DIALOG);
                local data = {
                    "path": comp.mDialogPath,
                    "block": comp.mInitialBlock
                };

                ::Base.mActionManager.registerAction(ActionSlotType.TALK_TO, 0, data, entityId);
            }else if(collisionStatus == 0x2){
                ::Base.mActionManager.unsetAction(0, entityId);
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.ITEM_SEARCH] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x1){
                local manager = world.getEntityManager();
                assert(manager.hasComponent(entityId, EntityComponents.INVENTORY_ITEMS));
                local comp = manager.getComponent(entityId, EntityComponents.INVENTORY_ITEMS);
                local data = {
                    "width": comp.mWidth,
                    "height": comp.mHeight,
                    "items": comp.mItems,
                    "stats": ::Base.mPlayerStats
                };

                ::Base.mActionManager.registerAction(ActionSlotType.ITEM_SEARCH, 0, data, entityId);
            }else if(collisionStatus == 0x2){
                ::Base.mActionManager.unsetAction(0, entityId);
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.PLACED_ITEM_COLLIDE_CHANGE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus != 0x1) return;
            local entityManager = world.getEntityManager();
            local pos = entityManager.getPosition(entityId);
            local targetPos = ::randDistanceFromPoint(pos, 10, 10);
            world.spawnDroppedItem(targetPos, ::Item(ItemId.APPLE));

            //Destroy the old entity and replace with a new one.

            local sceneNode = entityManager.getComponent(entityId, EntityComponents.SCENE_NODE).mNode;
            local targetNode = sceneNode.getParent();
            entityManager.destroyEntity(entityId);

            local data = {
                "originX": pos.x,
                "originY": -pos.z,
                "type": PlacedItemId.TREE
            };
            world.mEntityFactory_.constructPlacedItem(targetNode, data, null);
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.PICK] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x1){
                local isActive = ::Base.mPlayerStats.doesInventoryHaveFreeSlot();
                ::Base.mActionManager.registerAction(ActionSlotType.PICK, 0, entityId, entityId, isActive);
            }else if(collisionStatus == 0x2){
                ::Base.mActionManager.unsetAction(0, entityId);
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.READ_LORE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x1){
                ::Base.mActionManager.registerAction(ActionSlotType.READ_LORE, 0, entityId, entityId);
            }else if(collisionStatus == 0x2){
                ::Base.mActionManager.unsetAction(0, entityId);
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.PLACE_DESCRIPTION_TRIGGER] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x1){
                local manager = world.getEntityManager();
                if(manager.hasComponent(entityId, EntityComponents.BILLBOARD)){
                    local billboardComponent = manager.getComponent(entityId, EntityComponents.BILLBOARD);
                    local billboardIdx = billboardComponent.mBillboard;
                    local billboardManager = ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_;
                    if(billboardIdx < billboardManager.mTrackedNodes_.len()){
                        local billboard = billboardManager.mTrackedNodes_[billboardIdx];
                        if(billboard != null && billboard.mBillboard.rawin("startAnimation")){
                            billboard.mBillboard.startAnimation();
                        }
                    }
                }
            }
        });
        ::World.CollisionWorldWrapper.mTriggerResponses_[CollisionWorldTriggerResponses.CLAIM_MESSAGE_IN_BOTTLE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x1){
                local isActive = ::Base.mPlayerStats.doesInventoryHaveFreeSlot();
                ::Base.mActionManager.registerAction(ActionSlotType.CLAIM_MESSAGE_IN_BOTTLE, 0, entityId, entityId, isActive);
            }else if(collisionStatus == 0x2){
                ::Base.mActionManager.unsetAction(0, entityId);
            }
        });

