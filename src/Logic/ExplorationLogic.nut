/**
 * Logic interface for exploration.
 *
 * The exploration screen uses this class to determine how the exploration is progressing.
 * This prevents the gui from having to implement any of the actual logic.
 */
::ExplorationLogic <- class{

    mExplorationCount_ = 0;
    mExplorationPercentage_ = 0;

    mExplorationMaxLength_ = 200;

    mGui_ = null;

    constructor(){

    }

    function resetExploration(){
        mExplorationCount_ = 0;
        mExplorationPercentage_ = 0;
    }

    function tickUpdate(){
        //TODO in future this could be done with system milliseconds.
        if(mExplorationCount_ < mExplorationMaxLength_) mExplorationCount_++;

        local newPercentage = ((mExplorationCount_.tofloat() / mExplorationMaxLength_) * 100).tointeger();

        if(mExplorationPercentage_ != newPercentage){
            mGui_.notifyExplorationPercentage(newPercentage);
        }
        mExplorationPercentage_ = newPercentage;
    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }
};