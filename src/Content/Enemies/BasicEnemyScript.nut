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
    maxChaseFrames = -1;
    chaseFrameCount = 0;
    playerSpottedRadius = 32;

    //Wield distance constants with hysteresis to prevent glitching
    wieldActivationDistance = 10;
    wieldDeactivationDistance = 12; //0.8 of activation distance

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
            ctx.chaseFrameCount = 0;
        },
        "update": function(ctx, e, data) {
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            world.moveEnemyToPlayer(e);

            local pos = world.getEntityManager().getPosition(e);
            local distance = pos.distance(world.getPlayerPosition());
            local activeEnemy = world.mActiveEnemies_[e];
            //Apply hysteresis to wield state: activate at longer distance, deactivate at shorter distance
            local currentlyWielding = activeEnemy.isWieldActive();
            if(currentlyWielding){
                activeEnemy.setWieldActive(distance <= ctx.wieldDeactivationDistance);
            }else{
                activeEnemy.setWieldActive(distance <= ctx.wieldActivationDistance);
            }

            //print("distance " + distance);

            local lifetimeComp = world.getEntityManager().getComponent(e, EntityComponents.LIFETIME);
            lifetimeComp.mLifetime = lifetimeComp.mLifetimeTotal;

            //Check if chase frame limit has been exceeded.
            if(ctx.maxChaseFrames >= 0){
                if(distance < ctx.playerSpottedRadius / 2){
                    //Reset counter if player is close.
                    ctx.chaseFrameCount = 0;
                }else{
                    ctx.chaseFrameCount++;
                    if(ctx.chaseFrameCount > ctx.maxChaseFrames){
                        //Stop chasing if timeout exceeded and distance is still large.
                        ctx.switchState(ctx.idleWalk ? ctx.idleWalkState : ctx.idleState);
                        return;
                    }
                }
            }
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

    constructor(entity, idleWalk, maxChaseFrames=-1, playerSpottedRadius=32){
        this.entity = entity;
        this.idleWalk = idleWalk;
        this.maxChaseFrames = maxChaseFrames;
        this.playerSpottedRadius = playerSpottedRadius;
        switchState(idleWalk ? idleWalkState : idleState);
    }
};

    constructor(eid, idleWalk=true, enemyType=null, maxChaseFrames=-1, playerSpottedRadius=32){
        mEnemyType_ = enemyType;
        mEid_ = eid;
        mMachine = BasicEnemyMachine(eid, idleWalk, maxChaseFrames, playerSpottedRadius);
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
