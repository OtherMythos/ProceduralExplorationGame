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

    function playerRegularAttack(){
        print("Doing regular attack");

        local damageValue = ::Combat.DamageValue(-1);
        attackLogic_(damageValue);
    }

    function playerSpecialAttack(id){
        print("Doing special attack " + id);

        local damageValue = ::Combat.DamageValue(-8);
        attackLogic_(damageValue);
    }

    function attackLogic_(damageValue){
        //TODO give this an actual id.
        local died = mData_.performAttackOnOpponent(damageValue, 0);

        if(died){
            notifyOpponentDied_();
        }

        notifyOpponentStatsChange_();
    }

    function notifyOpponentStatsChange_(){
        if(!mGui_) return;

        mGui_.notifyOpponentStatsChange(mData_);
    }

    function notifyOpponentDied_(){
        if(!mGui_) return;

        mGui_.notifyOpponentDied(mData_);
    }
};