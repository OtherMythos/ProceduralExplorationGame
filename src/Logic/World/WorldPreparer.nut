/**
 * Abstracts the logic to prepare data for a world.
 * This class is responsible for providing feedback for the progress of the generation.
 */
::WorldPreparer <- class{

    mCurrentPercent_ = 0.0;

    constructor(){

    }

    function processPreparation(){

    }

    function preparationComplete(){
        return mCurrentPercent_ >= 1.0;
    }

}