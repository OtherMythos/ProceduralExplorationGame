::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer.ExplorationItemsContainerAnimator <- class{

    mCounter_ = 0;
    mNumSlots_ = 0;

    mActiveAnimations_ = null

    constructor(parentContainer, numSlots){
        mNumSlots_ = numSlots;
        mActiveAnimations_ = array(numSlots);
    }

    function update(){
        foreach(i in mActiveAnimations_){
            if(i == null) continue;
            i.update();
        }
    }

    /**
     * Set an animation active for a particular widget.
     * @param widget The gui widget which should be animated.
     * @param idx The index in which this widget exists in the panel.
     * @param anim The animation object with which to perform the animation.
     */
    function startAnimForItem(anim, idx){
        mActiveAnimations_[idx] = anim;
        anim.start();
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationGuiAnimations/ExplorationGuiAnimation.nut")