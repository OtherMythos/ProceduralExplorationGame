/**
 * Logic interface for exploration.
 *
 * The exploration screen uses this class to determine how the exploration is progressing.
 * This prevents the gui from having to implement any of the actual logic.
 */
::ExplorationLogic <- class{

    mExplorationCount_ = 0;
    mExplorationPercentage_ = 0;

    EXPLORATION_MAX_LENGTH = 200;
    EXPLORATION_MAX_FOUND_ITEMS = 4;

    mFoundItems_ = null;
    mNumFoundItems_ = 0;

    mEnemyEncountered_ = false;
    mExplorationFinished_ = false;

    mGui_ = null;

    constructor(){
        resetExploration();
    }

    function resetExploration(){
        mExplorationCount_ = 0;
        mExplorationPercentage_ = 0;

        mNumFoundItems_ = 0;
        mFoundItems_ = array(EXPLORATION_MAX_FOUND_ITEMS, Item.NONE);
        mEnemyEncountered_ = false;
        mExplorationFinished_ = false;

        renotifyItems();
        processExplorationBegan();
    }

    function tickUpdate(){
        if(mExplorationCount_ >= EXPLORATION_MAX_LENGTH){
            processExplorationEnd();
            return;
        }
        if(mExplorationCount_ == EXPLORATION_MAX_LENGTH) return;
        if(mEnemyEncountered_) return;
        updatePercentage();
        checkForItem();
        checkForEncounter();
    }

    function updatePercentage(){
        //TODO in future this could be done with system milliseconds.
        if(mExplorationCount_ < EXPLORATION_MAX_LENGTH) mExplorationCount_++;

        local newPercentage = ((mExplorationCount_.tofloat() / EXPLORATION_MAX_LENGTH) * 100).tointeger();

        if(mExplorationPercentage_ != newPercentage){
            mGui_.notifyExplorationPercentage(newPercentage);
        }
        mExplorationPercentage_ = newPercentage;
    }

    function checkForItem(){
        local foundSomething = _random.randInt(50) == 0;
        if(foundSomething && mNumFoundItems_ < EXPLORATION_MAX_FOUND_ITEMS){
            //decide what was found.
            local item = _random.randInt(Item.NONE+1, Item.MAX-1);
            processFoundItem(item);
        }
    }

    function checkForEncounter(){
        local foundSomething = _random.randInt(200) == 0;
        if(foundSomething){
            //decide what was found.
            local enemy = _random.randInt(Enemy.NONE+1, Enemy.MAX-1);
            processEncounter(enemy);
        }
    }

    function processFoundItem(item){
        //Find the index of insertion.
        local idx = mFoundItems_.find(Item.NONE);
        //Should have found something and there should be space if this function is being called.
        assert(idx != null);

        mFoundItems_[idx] = item;
        mNumFoundItems_++;

        print(format("Found %s at index %i", ::ItemToName(item), idx));

        mGui_.notifyItemFound(item, idx);
    }

    function processEncounter(enemy){
        print("Encountered enemy " + ::EnemyToName(enemy));
        mGui_.notifyEnemyEncounter(enemy);
        mEnemyEncountered_ = true;
    }

    function processExplorationBegan(){
        if(mGui_) mGui_.notifyExplorationBegan();
    }

    function processExplorationEnd(){
        if(mExplorationFinished_) return;
        mExplorationFinished_ = true;

        if(mGui_) mGui_.notifyExplorationEnd();
    }

    function continueExploration(){
        mEnemyEncountered_ = false;
        renotifyItems();
    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }

    function renotifyItems(){
        if(!mGui_) return;
        foreach(i,c in mFoundItems_){
            mGui_.notifyItemFound(c, i);
        }
    }

    /*
    * Either continue or reset the exploration, depending on whether it's finished or not.
    */
    function continueOrResetExploration(){
        if(mExplorationFinished_){
            resetExploration();
            return;
        }
        continueExploration();
    }
};