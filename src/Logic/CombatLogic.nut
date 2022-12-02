/**
 * Logic interface for combat.
 *
 */
::CombatLogic <- class{

    mGui_ = null;

    mData_ = null;

    constructor(combatData){
        mData_ = combatData;
    }

    function tickUpdate(){

    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }

    function performOpponentAttacks(){
        for(local i = 0; i < mData_.getNumOpponents(); i++){
            local damageValue = ::Combat.CombatMove(-5);

            local died = mData_.performAttackOnPlayer(damageValue);
            if(died){
                notifyPlayerDied_();
                return;
            }
        }

        notifyStatsChange_();
    }

    function playerRegularAttack(opponentId){
        print("Doing regular attack");

        local damageValue = ::Combat.CombatMove(-1);
        attackLogic_(damageValue, opponentId);
    }

    function playerSpecialAttack(id, opponentId){
        print("Doing special attack " + id);

        local damageValue = ::Combat.CombatMove(-20);
        attackLogic_(damageValue, opponentId);
    }

    function attackLogic_(damageValue, opponentId){
        local died = mData_.performAttackOnOpponent(damageValue, opponentId);

        notifyStatsChange_();
        if(died){
            notifyOpponentDied_(opponentId);
            if(mData_.getNumAliveOpponents() == 0){
                notifyAllOpponentsDied_();
            }
        }
    }

    function notifyStatsChange_(){
        if(!mGui_) return;

        mGui_.notifyStatsChange(mData_);
    }

    function notifyOpponentDied_(opponentId){
        if(!mGui_) return;

        mGui_.notifyOpponentDied(opponentId);
    }

    function notifyAllOpponentsDied_(){
        if(!mGui_) return;

        mGui_.notifyAllOpponentsDied();
    }

    function notifyPlayerDied_(){
        if(!mGui_) return;

        mGui_.notifyPlayerDied();
    }
};