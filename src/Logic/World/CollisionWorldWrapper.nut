
enum CollisionWorldTriggerResponses{
    EXP_ORB,
    OVERWORLD_VISITED_PLACE,
    PROJECTILE_DAMAGE,
    BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED,
    BASIC_ENEMY_PLAYER_TARGET_RADIUS,
    DIE,
    NPC_INTERACT,

    MAX = 100
};


::_applyHealthChangeOther <- function(manager, entity, damage){
    if(!manager.entityValid(entity)) return;
    local component = manager.getComponent(entity, EntityComponents.HEALTH);
    local newHealth = component.mHealth + damage;
    if(newHealth > component.mMaxHealth){
        newHealth = component.mMaxHealth;
    }
    local newPercentage = newHealth.tofloat() / component.mMaxHealth.tofloat();

    component.mHealth = newHealth;
    print("new health " + newHealth);

    //TODO get rid of this.
    ::Base.mExplorationLogic.mCurrentWorld_.notifyNewEntityHealth(entity, newHealth, newPercentage);

    if(newHealth <= 0){
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

    mTriggerResponses_ = null;
    mTriggerData_ = null;
    mPoints_ = null;
    mPointsQueuedDestruction_ = null;
    mId_ = null;

    constructor(parentWorld, id){
        mParentWorld_ = parentWorld;
        mId_ = id;
        mCollisionWorld_ = CollisionWorld(_COLLISION_WORLD_BRUTE_FORCE, mId_);

        mTriggerResponses_ = {};
        mTriggerData_ = {};
        mPoints_ = {};
        mPointsQueuedDestruction_ = {};

        //TODO see if I can populate these somewhere else.
        mTriggerResponses_[CollisionWorldTriggerResponses.EXP_ORB] <- TriggerResponse(function(world, entityId, receiver, collisionStatus){
            world.processEXPOrb(entityId);
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.OVERWORLD_VISITED_PLACE] <- TriggerResponse(function(world, id, receiver, collisionStatus){
            //TODO remove magic numbers.
            if(collisionStatus == 0x1){
                ::Base.mExplorationLogic.notifyPlaceEnterState(id, true);
            }
            else if(collisionStatus == 0x2){
                ::Base.mExplorationLogic.notifyPlaceEnterState(id, false);
            }
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.PROJECTILE_DAMAGE] <- TriggerResponse(function(world, projectileId, entityId, collisionStatus){
            if(collisionStatus != 0x1) return;

            local active = world.mProjectileManager_.mActiveProjectiles_;
            //TODO can this be removed with the new collision system?
            //if(!active.rawin(projectileId)) return;
            local projData = active[projectileId];
            local damage = projData.mCombatMove_.getDamage();

            _applyDamageOther(world.getEntityManager(), entityId, damage);
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x0) return;
            local manager = world.getEntityManager();
            if(!manager.entityValid(entityId)) return;
            assert(manager.hasComponent(entityId, EntityComponents.SCRIPT));
            local comp = manager.getComponent(entityId, EntityComponents.SCRIPT);
            if(collisionStatus == 0x1) comp.mScript.receivePlayerSpotted(true);
            else if(collisionStatus == 0x2) comp.mScript.receivePlayerSpotted(false);
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.BASIC_ENEMY_PLAYER_TARGET_RADIUS] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus == 0x0) return;
            world.processEntityCombatTarget(second, collisionStatus == 0x1);
            /*
            local manager = world.getEntityManager();
            assert(manager.hasComponent(entityId, EntityComponents.SCRIPT));
            local comp = manager.getComponent(entityId, EntityComponents.SCRIPT);
            if(collisionStatus == 0x1) comp.mScript.receivePlayerSpotted(true);
            else if(collisionStatus == 0x2) comp.mScript.receivePlayerSpotted(false);
            */
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.DIE] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus != 0x1) return;
            local manager = world.getEntityManager();
            manager.destroyEntity(entityId);
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.NPC_INTERACT] <- TriggerResponse(function(world, entityId, second, collisionStatus){
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

        printf("Registering sender with id %i for mask %i for world %i", pointId, mask, mId_);
        mPoints_.rawset(pointId, triggerId);
        assert(!mTriggerData_.rawin(pointId));
        mTriggerData_.rawset(pointId, triggerData);
        return pointId;
    }

    function addCollisionReceiver(triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_RECEIVER);

        printf("Registering receiver with id %i for mask %i for world %i", pointId, mask, mId_);
        assert(!mTriggerData_.rawin(pointId));
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