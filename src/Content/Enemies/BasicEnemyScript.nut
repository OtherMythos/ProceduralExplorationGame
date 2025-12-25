enum BasicEnemyEvents{
    PLAYER_SPOTTED,
    PLAYER_NOT_SPOTTED,
};

::BasicEnemyScript <- class{

    mMachine = null;
    mEnemyType_ = null;
    mEid_ = null;


BasicEnemyMachine = class extends ::CombatStateMachine{
    attacking = false;
    maxAttackCooldown = 30;
    attackCooldown = 30;
    targetingId = -1;
    idleWalk = false;

    direction = null;
    movementCount = 50;

    idleState = {
        "update": function(ctx, e, data) {
        },
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_SPOTTED){
                ctx.switchState(ctx.chasingPlayerState);
            }
        }
    };
    idleWalkState = {
        "update": function(ctx, e, data) {
            //Generate a new direction.
            local change = _random.randInt(0, 10 + ctx.movementCount);
            ctx.movementCount--;
            if(ctx.movementCount < 0) ctx.movementCount = 0;
            if(change == 0){
                if(ctx.movementCount <= 30){
                    local dir = _random.randVec2()-0.5
                    ctx.direction = Vec3(dir.x, 0, dir.y);
                    ctx.direction.normalise();
                    ctx.movementCount = 50;
                }
            }else if(change == 1){
                ctx.direction = null;
            }
            if(ctx.direction != null){
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                world.moveEnemyInDirection(e, ctx.direction);
            }

        },
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
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            world.moveEnemyToPlayer(e);

            local pos = world.getEntityManager().getPosition(e);
            local distance = pos.distance(world.getPlayerPosition());
            local activeEnemy = world.mActiveEnemies_[e];
            //if(distance <= 5){
                activeEnemy.setWieldActive(distance <= 10);
            //}

            //print("distance " + distance);

            local lifetimeComp = world.getEntityManager().getComponent(e, EntityComponents.LIFETIME);
            lifetimeComp.mLifetime = lifetimeComp.mLifetimeTotal;
        },
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_NOT_SPOTTED){
                ctx.switchState(ctx.idleWalk ? ctx.idleWalkState : ctx.idleState);
            }
        },
        "end": function(ctx, e) {
            assert(ctx.targetingId != -1);
            ::Base.mExplorationLogic.mCurrentWorld_.mTargetManager_.releaseTarget(::Base.mExplorationLogic.mCurrentWorld_.mActiveEnemies_[e], ctx.targetingId);
        },
    };

    constructor(entity, idleWalk){
        this.entity = entity;
        this.idleWalk = idleWalk;
        switchState(idleWalk ? idleWalkState : idleState);
    }
};

    constructor(eid, idleWalk=true, enemyType=null){
        mEnemyType_ = enemyType;
        mEid_ = eid;
        mMachine = BasicEnemyMachine(eid, idleWalk);
    }

    function receivePlayerSpotted(started){
        if(started && mEnemyType_ == EnemyId.GOBLIN){
            //Goblin sees player and says 'humon'
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            world.addSpokenText(mEid_, "humon");
        }
        mMachine.notify(started ? BasicEnemyEvents.PLAYER_SPOTTED : BasicEnemyEvents.PLAYER_NOT_SPOTTED);
    }

function update(eid){
    mMachine.update(eid, null);
}

function destroyed(eid, reason){
    //TODO This is responsible for calling destruction for models, which breaks from the ECS design pattern.
    ::Base.mExplorationLogic.notifyEnemyDestroyed(eid);
}

};
