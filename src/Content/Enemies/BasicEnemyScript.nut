enum BasicEnemyEvents{
    PLAYER_SPOTTED,
    PLAYER_NOT_SPOTTED,
};

::BasicEnemyScript <- class{

    mMachine = null;


BasicEnemyMachine = class extends ::CombatStateMachine{
    attacking = false;
    maxAttackCooldown = 30;
    attackCooldown = 30;
    targetingId = -1;

    idleState = {
        "update": function(ctx, e, data) {},
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_SPOTTED){
                ctx.switchState(ctx.chasingPlayerState);
            }
        }
    };
    chasingPlayerState = {
        "start": function(ctx, e) {
            //TODO remove direct access.
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local activeEnemy = world.mActiveEnemies_[e];
            ctx.targetingId = world.mTargetManager_.targetEntity(world.mPlayerEntry_, activeEnemy);
        },
        "update": function(ctx, e, data) {
            ::Base.mExplorationLogic.mCurrentWorld_.moveEnemyToPlayer(e);
        },
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_NOT_SPOTTED){
                ctx.switchState(ctx.idleState);
            }
        },
        "end": function(ctx, e) {
            assert(ctx.targetingId != -1);
            ::Base.mExplorationLogic.mCurrentWorld_.mTargetManager_.releaseTarget(::Base.mExplorationLogic.mCurrentWorld_.mActiveEnemies_[e], ctx.targetingId);
        },
    };

    constructor(entity){
        this.entity = entity;
        switchState(idleState);
    }
};

    constructor(eid){
        mMachine = BasicEnemyMachine(eid);
    }

    function receivePlayerSpotted(started){
        mMachine.notify(started ? BasicEnemyEvents.PLAYER_SPOTTED : BasicEnemyEvents.PLAYER_NOT_SPOTTED);
    }

function update(eid){
    mMachine.update(eid, null);
}

function destroyed(eid){
    //TODO This is responsible for calling destruction for models, which breaks from the ECS design pattern.
    ::Base.mExplorationLogic.notifyEnemyDestroyed(eid);
}

};
