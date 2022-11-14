/**
 * Logic interface for combat.
 *
 */
::CombatLogic <- class{

    mGui_ = null;

    constructor(){

    }

    function tickUpdate(){

    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }
};