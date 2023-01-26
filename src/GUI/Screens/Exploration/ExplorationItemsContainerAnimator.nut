::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer.ExplorationItemsContainerAnimator <- class{

    mCounter_ = 0;

    constructor(parentContainer){

    }

    function update(mButtons_, mFoundObjects_){
        mCounter_+=0.01;
        //mButtons_[0].setOrientation(mCounter_);
        mButtons_[0].setSize(100 * sin(mCounter_), mButtons_[0].getSize().y);
    }
};