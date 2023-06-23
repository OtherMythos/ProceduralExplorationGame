enum WorldEnemyEntityEvents{
    PLAYER_SPOTTED,
    PLAYER_NOT_SPOTTED,
};

function update(eid){
    ::w.e[eid.getId()].update(eid, null);
}

function destroyed(eid){
    //::w.e.rawdelete(eid.getId());
    //::w.mActiveEntitySkeletonAnimations.rawdelete(eid.getId());
    //::_dropItem(eid.getPosition(), [InventoryItems.EXPLODER_HELECOPTER]);
}

function receivePlayerSpotted(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        ::w.e[sender.getId()].notify(WorldEnemyEntityEvents.PLAYER_SPOTTED, sender);
    }
    else if(type == _COLLISION_LEAVE){
        local t = sender.getId();
        if(::w.e.rawin(t)) ::w.e[t].notify(WorldEnemyEntityEvents.PLAYER_NOT_SPOTTED, sender);
    }
}
function receivePlayerInner(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        print("Player entered entity innter.")

        local enemyData = [
            ::Combat.CombatStats(EnemyId.GOBLIN)
        ];
        local currentCombatData = ::Combat.CombatData(::Base.mPlayerStats.mPlayerCombatStats, enemyData);
        ::Base.notifyEncounter(currentCombatData);

        ::ScreenManager.queueTransition(::ScreenManager.ScreenData(Screen.COMBAT_SCREEN, {"logic": ::Base.mCombatLogic}));
    }
}

::WorldEnemyEntity <- class extends ::StateMachine{
    anim = null;

    idleState = {
        "start": function(ctx, e){
            print("Starting idle state");
        },
        "update": function(ctx, e, data){
        },
        "notify": function(ctx, id, e, data){
            if(id == WorldEnemyEntityEvents.PLAYER_SPOTTED){
                ctx.switchState(ctx.chasingState);
            }
        }
    };
    chasingState = {
        "update": function(ctx, e, data){
            e.moveTowards(_world.getPlayerPosition(), 0.2);
        },
        "notify": function(ctx, id, e, data){
            if(id == WorldEnemyEntityEvents.PLAYER_NOT_SPOTTED){
                ctx.switchState(ctx.idleState);
            }
        }
    };

    constructor(){
        switchState(idleState);
    }
};
