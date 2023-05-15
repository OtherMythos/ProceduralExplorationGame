enum BasicEnemyEvents{
    PLAYER_SPOTTED,
    PLAYER_NOT_SPOTTED,
    PLAYER_IN_ATTACK_RANGE,
    PLAYER_OUT_ATTACK_RANGE,
};

function receivePlayerSpotted(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        local t = sender.getId();
        if(::w.e.rawin(t)) ::w.e[sender.getId()].notify(BasicEnemyEvents.PLAYER_SPOTTED, sender);
    }
    else if(type == _COLLISION_LEAVE){
        local t = sender.getId();
        if(::w.e.rawin(t)) ::w.e[t].notify(BasicEnemyEvents.PLAYER_NOT_SPOTTED, sender);
    }
}
function receivePlayerInner(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        local t = sender.getId();
        if(::w.e.rawin(t)) ::w.e[sender.getId()].notify(BasicEnemyEvents.PLAYER_IN_ATTACK_RANGE, sender);
    }
    else if(type == _COLLISION_LEAVE){
        local t = sender.getId();
        if(::w.e.rawin(t)) ::w.e[sender.getId()].notify(BasicEnemyEvents.PLAYER_OUT_ATTACK_RANGE, sender);
    }
}

function update(eid){
    ::w.e[eid.getId()].update(eid, null);
}

function destroyed(eid){
    local worldPos = ::EffectManager.getWorldPositionForWindowPos(::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getPosition() + ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getSize() / 2);
    local endPos = ::Base.mExplorationLogic.mGui_.mMoneyCounter_.getPositionWindowPos();
    ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_COIN_EFFECT, {"numCoins": 10, "start": worldPos, "end": endPos, "money": 10, "coinScale": 0.1}));

    ::w.e.rawdelete(eid.getId());
}

::BasicEnemyMachine <- class extends ::CombatStateMachine{
    attacking = false;
    maxAttackCooldown = 30;
    attackCooldown = 30;

    idleState = {
        "update": function(ctx, e, data) {},
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_SPOTTED){
                ctx.switchState(ctx.chasingPlayerState);
            }
        }
    };
    chasingPlayerState = {
        "update": function(ctx, e, data) {
            ::Base.mExplorationLogic.moveEnemyToPlayer(e.getId());

            if(ctx.attacking){
                ctx.attackCooldown--;
                if(ctx.attackCooldown <= 0){
                    ctx.attackCooldown = ctx.maxAttackCooldown;

                    ::Base.mExplorationLogic.performMove(MoveId.AREA, e.getPosition().toVector3(), null, _COLLISION_PLAYER);
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
        }
    };

    constructor(){
        switchState(idleState);
    }
};