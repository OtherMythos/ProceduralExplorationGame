enum BasicEnemyEvents{
    PLAYER_SPOTTED,
    PLAYER_NOT_SPOTTED,
    PLAYER_IN_ATTACK_RANGE,
    PLAYER_OUT_ATTACK_RANGE,
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
            ctx.targetingId = ::Base.mExplorationLogic.mCurrentWorld_.mTargetManager_.targetEntity(::Base.mExplorationLogic.mCurrentWorld_.mPlayerEntry_, ::Base.mExplorationLogic.mCurrentWorld_.mActiveEnemies_[e]);
        },
        "update": function(ctx, e, data) {
            ::Base.mExplorationLogic.mCurrentWorld_.moveEnemyToPlayer(e);

            //TODO do I actually need this attacking logic?
            if(ctx.attacking){
                ctx.attackCooldown--;
                if(ctx.attackCooldown <= 0){
                    ctx.attackCooldown = ctx.maxAttackCooldown;

                    //::Base.mExplorationLogic.performMove(MoveId.AREA, e.getPosition().toVector3(), null, _COLLISION_PLAYER);
                    ::Base.mExplorationLogic.mCurrentWorld_.entityPerformAttack(e);
                }
            }
        },
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_NOT_SPOTTED){
                ctx.switchState(ctx.idleState);
            }

            else if(id == BasicEnemyEvents.PLAYER_IN_ATTACK_RANGE){
                ctx.attacking = true;
            }
            else if(id == BasicEnemyEvents.PLAYER_OUT_ATTACK_RANGE){
                ctx.attacking = false;
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
        /*
        if(type == _COLLISION_ENTER){
            local t = sender;
            if(::w.e.rawin(t)) ::w.e[sender].notify(BasicEnemyEvents.PLAYER_SPOTTED, sender);
        }
        else if(type == _COLLISION_LEAVE){
            local t = sender;
            if(::w.e.rawin(t)) ::w.e[t].notify(BasicEnemyEvents.PLAYER_NOT_SPOTTED, sender);
        }
        */
       mMachine.notify(started ? BasicEnemyEvents.PLAYER_SPOTTED : BasicEnemyEvents.PLAYER_NOT_SPOTTED);
    }
    /*
function receivePlayerSpotted(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        local t = sender;
        if(::w.e.rawin(t)) ::w.e[sender].notify(BasicEnemyEvents.PLAYER_SPOTTED, sender);
    }
    else if(type == _COLLISION_LEAVE){
        local t = sender;
        if(::w.e.rawin(t)) ::w.e[t].notify(BasicEnemyEvents.PLAYER_NOT_SPOTTED, sender);
    }
}
*/
/*
function receivePlayerInner(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        local t = sender;
        if(::w.e.rawin(t)) ::w.e[sender].notify(BasicEnemyEvents.PLAYER_IN_ATTACK_RANGE, sender);
    }
    else if(type == _COLLISION_LEAVE){
        local t = sender;
        if(::w.e.rawin(t)) ::w.e[sender].notify(BasicEnemyEvents.PLAYER_OUT_ATTACK_RANGE, sender);
    }
}
*/

function update(eid){
    //::w.e[eid].update(eid, null);
    mMachine.update(eid, null);
}

function destroyed(eid){
    //checkDestroyBillboard_(eid);

    //::w.e.rawdelete(eid);
    ::Base.mExplorationLogic.notifyEnemyDestroyed(eid);
}

function checkDestroyBillboard_(eid){
    local billboardIdx = -1;
    try{
        billboardIdx = _component.user[Component.MISC].get(eid, 0);
    }catch(e){ }

    if(billboardIdx >= 0){
        ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(billboardIdx);
    }
}
};
