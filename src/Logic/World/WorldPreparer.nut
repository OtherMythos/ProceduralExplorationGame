/**
 * Abstracts the logic to prepare data for a world.
 * This class is responsible for providing feedback for the progress of the generation.
 */
::WorldPreparer <- class{

    mCurrentPercent_ = 0.0;

    constructor(){

    }

    function processPreparation(){
        mCurrentPercent_ = 1.0;
        _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        return true;
    }

    function preparationComplete(){
        return mCurrentPercent_ >= 1.0;
    }

}