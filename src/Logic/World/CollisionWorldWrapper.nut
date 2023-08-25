
enum CollisionWorldTriggerResponses{
    EXP_ORB,

    MAX = 100
};

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
        function trigger(world, triggerData){
            mFunc_(world, triggerData);
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

        mTriggerResponses_[CollisionWorldTriggerResponses.EXP_ORB] <- TriggerResponse(function(world, entityId){
            //print("Trigger EXP orb " + entityId);
            world.processEXPOrb(entityId);
        });
    }

    function processCollision(){
        mCollisionWorld_.processCollision();

        for(local i = 0; i < mCollisionWorld_.getNumCollisions(); i++){
            local pair = mCollisionWorld_.getCollisionPairForIdx(i);
            local collisionStatus = (pair & 0xF000000000000000) >> 60;
            //local pair = world.getCollisionPairForIdx(0) & 0xFFFFFFFFFFFFF;
            //_test.assertEqual(collisionStatus, 0x2);
            local first = pair & 0xFFFFFFF;
            //local second = (pair >> 30) & 0xFFFFFFF;
            print(first);
            assert(mPoints_.rawin(first));
            local triggerResponseId = mPoints_[first];
            local response = mTriggerResponses_[triggerResponseId];
            local dataResponse = mTriggerData_[first];
            response.trigger(mParentWorld_, dataResponse);

            //(pair & 0xFFFFFFF)
            //TODO complete this
            //assert(false);
        }
    }

    function addCollisionSender(triggerId, triggerData, x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_SENDER);
        if(triggerId < CollisionWorldTriggerResponses.MAX){
            mPoints_[pointId] <- triggerId;
            mTriggerData_[pointId] <- triggerData;
            return pointId;
        }

        return pointId;

        //Register the new trigger.

        //mTriggerResponses_[pointId] <- trigger;
    }

    function addCollisionReceiver(x, y, rad, mask=0xFF){
        local pointId = mCollisionWorld_.addCollisionPoint(x, y, rad, mask, _COLLISION_WORLD_ENTRY_RECEIVER);

        return pointId;
    }

    function removeCollisionPoint(id){
        mCollisionWorld_.removeCollisionPoint(id);
    }

}