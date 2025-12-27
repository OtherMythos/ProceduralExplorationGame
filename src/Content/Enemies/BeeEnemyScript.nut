::BeeEnemyScript <- class extends BasicEnemyScript{

    mHivePosition_ = null;
    mHiveEid_ = null;

    BeeEnemyMachine = class extends ::BasicEnemyScript.BasicEnemyMachine{
        idleTimer = 0;
        idleTimeout = 1200;
        returningToHive = false;
        hiveDistance = 3.0;

        returningState = {
            "start": function(ctx, e) {
                ctx.returningToHive = true;
            },
            "update": function(ctx, e, data) {
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                local bee = world.mActiveEnemies_[e];
                if(bee == null) return;

                local pos = world.getEntityManager().getPosition(e);
                local hivePos = data;
                local dist = pos.distance(hivePos);

                if(dist <= ctx.hiveDistance){
                    //Close enough to hive, switch back to idle
                    ctx.switchState(ctx.idleWalkState);
                }else{
                    //Move towards hive
                    local direction = hivePos - pos;
                    direction.normalise();
                    world.moveEnemyInDirection(e, direction);
                }
            },
            "notify": function(ctx, id, e, data){
                if(id == BasicEnemyEvents.PLAYER_SPOTTED){
                    ctx.switchState(ctx.chasingPlayerState);
                }
            },
            "end": function(ctx, e) {
                ctx.returningToHive = false;
            }
        };

        idleWalkState = {
            "start": function(ctx, e) {
                ctx.idleTimer = _random.randInt(0, ctx.idleTimeout);
            },
            "update": function(ctx, e, data) {
                ctx.idleTimer++;
                if(ctx.idleTimer >= ctx.idleTimeout && !ctx.returningToHive){
                    ctx.switchState(ctx.returningState);
                    return;
                }

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
                    ctx.idleTimer = 0; //Reset timer when player spotted
                    ctx.switchState(ctx.chasingPlayerState);
                }
            }
        };

        constructor(entity, idleWalk){
            this.entity = entity;
            this.idleWalk = idleWalk;
            this.hiveDistance = 3.0;
            switchState(idleWalk ? idleWalkState : idleState);
        }
    };

    constructor(eid, idleWalk=true){
        mMachine = BeeEnemyMachine(eid, idleWalk);
    }

    function receiveHiveAttacked(){
        mMachine.notify(BasicEnemyEvents.PLAYER_SPOTTED);
        switchToAggressiveRenderQueue();
    }

    function receivePlayerSpotted(started){
        if(started == false){
            switchToNormalRenderQueue();
            mMachine.notify(BasicEnemyEvents.PLAYER_NOT_SPOTTED);
        }
    }

    function setHivePosition(hivePos, hiveEid){
        mHivePosition_ = hivePos;
        mHiveEid_ = hiveEid;
    }

    function healthChange(newHealth, percentage, difference){
        //If attacked begin aggro against the player.
        switchToAggressiveRenderQueue();
        mMachine.notify(BasicEnemyEvents.PLAYER_SPOTTED);
    }

    function switchRenderQueue_(renderQueue){
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        local activeEnemy = world.mActiveEnemies_[mMachine.entity];
        if(activeEnemy != null){
            activeEnemy.setRenderQueue(renderQueue);
        }
    }

    function switchToAggressiveRenderQueue(){
        switchRenderQueue_(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY_DANGEROUS);
    }

    function switchToNormalRenderQueue(){
        switchRenderQueue_(RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY);
    }

    function update(eid){
        mMachine.update(eid, mHivePosition_);
    }

};
