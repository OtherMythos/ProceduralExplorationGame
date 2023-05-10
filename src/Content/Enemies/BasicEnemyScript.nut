enum BasicEnemyEvents{
    PLAYER_SPOTTED,
    PLAYER_NOT_SPOTTED
};

function receivePlayerSpotted(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        ::w.e[sender.getId()].notify(BasicEnemyEvents.PLAYER_SPOTTED, sender);
    }
    else if(type == _COLLISION_LEAVE){
        local t = sender.getId();
        if(::w.e.rawin(t)) ::w.e[t].notify(BasicEnemyEvents.PLAYER_NOT_SPOTTED, sender);
    }
}
function receivePlayerInner(id, type, internal, sender, receiver){
    return;
    if(type == _COLLISION_ENTER){
        local enemyData = ::Combat.CombatStats(Enemy.GOBLIN);
        ::Base.mExplorationLogic.notifyEncounter(id, enemyData);
    }
}

function update(eid){
    ::w.e[eid.getId()].update(eid, null);
}

function destroyed(eid){
    ::w.e.rawdelete(eid.getId());
}

::BasicEnemyMachine <- class extends ::CombatStateMachine{
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
        },
        "notify": function(ctx, id, e, data){
            if(id == BasicEnemyEvents.PLAYER_NOT_SPOTTED){
                ctx.switchState(ctx.idleState);
            }
        }
    };

    constructor(){
        switchState(idleState);
    }
};