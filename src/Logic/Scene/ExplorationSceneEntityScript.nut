
function receivePlayerSpotted(id, type, internal, sender, receiver){
    if(type == _COLLISION_INSIDE){
        ::Base.mExplorationLogic.moveEnemyToPlayer(id);
    }
}
function receivePlayerInner(id, type, internal, sender, receiver){
    return;
    if(type == _COLLISION_ENTER){
        local enemyData = ::Combat.CombatStats(Enemy.GOBLIN);
        ::Base.mExplorationLogic.notifyEncounter(id, enemyData);
    }
}