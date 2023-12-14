
enum CollisionWorldTriggerResponses{
    EXP_ORB,
    OVERWORLD_VISITED_PLACE,
    PROJECTILE_DAMAGE,
    BASIC_ENEMY_RECEIVE_PLAYER_SPOTTED,
    TRIGGER_SPOILS,

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

    constructor(parentWorld){
        mParentWorld_ = parentWorld;
        mCollisionWorld_ = CollisionWorld(_COLLISION_WORLD_BRUTE_FORCE);

        mTriggerResponses_ = {};
        mTriggerData_ = {};
        mPoints_ = {};

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
            assert(manager.hasComponent(entityId, EntityComponents.SCRIPT));
            local comp = manager.getComponent(entityId, EntityComponents.SCRIPT);
            if(collisionStatus == 0x1) comp.mScript.receivePlayerSpotted(true);
            else if(collisionStatus == 0x2) comp.mScript.receivePlayerSpotted(false);
        });
        mTriggerResponses_[CollisionWorldTriggerResponses.TRIGGER_SPOILS] <- TriggerResponse(function(world, entityId, second, collisionStatus){
            if(collisionStatus != 0x1) return;
            local manager = world.getEntityManager();
            assert(manager.hasComponent(entityId, EntityComponents.SPOILS));
            local comp = manager.getComponent(entityId, EntityComponents.SPOILS);
            world.actuateSpoils(comp);
            manager.destroyEntity(entityId);
        });
    }

    function processCollision(){
        mCollisionWorld_.processCollision();

        for(local i = 0; i < mCollisionWorld_.getNumCollisions(); i++){
            local pair = mCollisionWorld_.getCollisionPairForIdx(i);
            local collisionStatus = (pair & 0xF000000000000000) >> 60;

            local first = pair & 0xFFFFFFF;
            local second = (pair >> 30) & 0xFFFFFFF;
            //print("Status " + collisionStatus + " for thing " + first);
            if(!mTriggerData_.rawin(first) || !mTriggerData_.rawin(second)) continue;
            if(collisionStatus == 0x2){
                //If the point has just left it might be because it was destroyed.
                //TODO might be able to check this case in c++ for efficiency.
                if(!mPoints_.rawin(first)) continue;
            }
            //if(!mPoints_.rawin(first)) continue;
            local triggerResponseId = mPoints_[first];
            local response = mTriggerResponses_[triggerResponseId];
            local dataResponse = mTriggerData_[first];
            local dataSecond = mTriggerData_[second];

            response.trigger(mParentWorld_, dataResponse, dataSecond, collisionStatus);
        }
    }

    function addCollisionSender(triggerId, triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_SENDER);
        if(triggerId < CollisionWorldTriggerResponses.MAX){
            print("Registering sender with id " + pointId + " for mask " + mask);
            mPoints_.rawset(pointId, triggerId);
            //mPoints_[pointId] <- triggerId;
            assert(!mTriggerData_.rawin(pointId));
            mTriggerData_.rawset(pointId, triggerData);
            return pointId;
        }

        return pointId;

        //Register the new trigger.

        //mTriggerResponses_[pointId] <- trigger;
    }

    function addCollisionReceiver(triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_RECEIVER);

        assert(!mTriggerData_.rawin(pointId));
        mTriggerData_.rawset(pointId, triggerData);

        return pointId;
    }

    function removeCollisionPoint(id){
        mCollisionWorld_.removeCollisionPoint(id);

        //If the point is a receiver then it won't have a point registered.
        //assert(mPoints_.rawin(id));
        mPoints_.rawdelete(id);
        assert(mTriggerData_.rawin(id));
        mTriggerData_.rawdelete(id);
    }

}