
enum CollisionWorldTriggerResponses{
    EXP_ORB,
    OVERWORLD_VISITED_PLACE,
    PROJECTILE_DAMAGE,

    MAX = 100
};


::_applyDamageOther <- function(manager, entity, damage){
    if(!manager.entityValid(entity)) return;
    print("Applying damage " + damage);
    //local newHealth = _component.user[Component.HEALTH].get(entity, 0) - damage;
    //local maxHealth = _component.user[Component.HEALTH].get(entity, 1);
    local component = manager.getComponent(entity, EntityComponents.HEALTH);
    local newHealth = component.mHealth - damage;
    local newPercentage = newHealth.tofloat() / component.mMaxHealth.tofloat();

    component.mHealth = newHealth;
    print("new health " + newHealth);

    //::Base.mExplorationLogic.mCurrentWorld_.notifyNewEntityHealth(entity, newHealth, newPercentage);

    if(newHealth <= 0){
        //_entity.destroy(entity);
        manager.destroyEntity(entity);
    }
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
    }

    function addCollisionSender(triggerId, triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_SENDER);
        if(triggerId < CollisionWorldTriggerResponses.MAX){
            mPoints_[pointId] <- triggerId;
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

        mPoints_.rawdelete(id);
        assert(mTriggerData_.rawin(id));
        mTriggerData_.rawdelete(id);
    }

}