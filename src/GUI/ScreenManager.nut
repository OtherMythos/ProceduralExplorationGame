::ScreenManager <- {

    "MAX_SCREENS": 3,
    "mActiveScreens_": null,

    function setup(){
        mActiveScreens_ = array(MAX_SCREENS, null);
    }

    /**
     * Transition to a new screen.
     */
    function transitionToScreen(screenObject, transitionEffect = null, layerId = 0){
        assert(layerId < MAX_SCREENS);
        if(mActiveScreens_[layerId] != null){
            mActiveScreens_[layerId].shutdown();
        }
        mActiveScreens_[layerId] = screenObject;

        if(!screenObject) return;

        mActiveScreens_[layerId].setup();
    }

    function update(){
        foreach(i in mActiveScreens_){
            if(i != null) i.update();
        }
    }
};

::ScreenManager.setup();