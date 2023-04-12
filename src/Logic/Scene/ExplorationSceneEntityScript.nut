
function receivePlayerSpotted(id, type, internal, sender, receiver){
    /*
    if(type == _COLLISION_ENTER){
        //::w.e[sender.getId()].notify(WorldEnemyEntityEvents.PLAYER_SPOTTED, sender);
        print("Spotted player " + id);
        //::Base.mExplorationLogic.moveEnemyToPlayer(id);
    }
    else if(type == _COLLISION_LEAVE){
        //local t = sender.getId();
        //if(::w.e.rawin(t)) ::w.e[t].notify(WorldEnemyEntityEvents.PLAYER_NOT_SPOTTED, sender);
        print("Left player " + id);
    }
    */
    if(type == _COLLISION_INSIDE){
        ::Base.mExplorationLogic.moveEnemyToPlayer(id);
    }
}
function receivePlayerInner(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        local enemyData = [
            ::Combat.CombatStats(Enemy.GOBLIN)
        ];
        ::Base.mExplorationLogic.notifyEncounter(enemyData);
    }
}