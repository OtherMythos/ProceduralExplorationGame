
function receivePlayerSpotted(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        //::w.e[sender.getId()].notify(WorldEnemyEntityEvents.PLAYER_SPOTTED, sender);
        print("Spotted player");
    }
    else if(type == _COLLISION_LEAVE){
        //local t = sender.getId();
        //if(::w.e.rawin(t)) ::w.e[t].notify(WorldEnemyEntityEvents.PLAYER_NOT_SPOTTED, sender);
        print("Left player");
    }
}
function receivePlayerInner(id, type, internal, sender, receiver){
    if(type == _COLLISION_ENTER){
        print("Fighting player");
        /*
        print("Player entered entity innter.")

        local enemyData = [
            ::Combat.CombatStats(Enemy.GOBLIN)
        ];
        local currentCombatData = ::Combat.CombatData(::Base.mPlayerStats.mPlayerCombatStats, enemyData);
        ::Base.notifyEncounter(currentCombatData);

        ::ScreenManager.queueTransition(::ScreenManager.ScreenData(Screen.COMBAT_SCREEN, {"logic": ::Base.mCombatLogic}));
        */
    }
}