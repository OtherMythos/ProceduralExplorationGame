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

    function playerRegularAttack(opponentId){
        print("Doing regular attack");

        local damageValue = ::Combat.CombatMove(-1);
        attackLogic_(damageValue, opponentId);
    }

    function playerSpecialAttack(id, opponentId){
        print("Doing special attack " + id);

        local damageValue = ::Combat.CombatMove(-8);
        attackLogic_(damageValue, opponentId);
    }

    function attackLogic_(damageValue, opponentId){
        //TODO give this an actual id.
        local died = mData_.performAttackOnOpponent(damageValue, opponentId);

        if(died){
            notifyOpponentDied_(opponentId);
        }

        notifyOpponentStatsChange_();
    }

    function notifyOpponentStatsChange_(){
        if(!mGui_) return;

        mGui_.notifyOpponentStatsChange(mData_);
    }

    function notifyOpponentDied_(opponentId){
        if(!mGui_) return;

        mGui_.notifyOpponentDied(opponentId);
    }
};