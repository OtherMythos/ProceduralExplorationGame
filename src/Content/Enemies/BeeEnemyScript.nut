::BeeEnemyScript <- class extends BasicEnemyScript{


    BeeEnemyMachine = class extends ::BasicEnemyScript.BasicEnemyMachine{

    };

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

};
