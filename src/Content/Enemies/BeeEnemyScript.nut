::BeeEnemyScript <- class extends BasicEnemyScript{


    BeeEnemyMachine = class extends ::BasicEnemyScript.BasicEnemyMachine{

    };

    function receiveHiveAttacked(){
        mMachine.notify(BasicEnemyEvents.PLAYER_SPOTTED);
    }

    function receivePlayerSpotted(started){
        if(started == false){
            mMachine.notify(BasicEnemyEvents.PLAYER_NOT_SPOTTED);
        }
    }

    function healthChange(newHealth, percentage, difference){
        //If attacked begin aggro against the player.
        mMachine.notify(BasicEnemyEvents.PLAYER_SPOTTED);
    }

};
