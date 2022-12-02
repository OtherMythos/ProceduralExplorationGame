::ScreenManager <- {

    "MAX_SCREENS": 3,
    "mActiveScreens_": null,
    "mPreviousScreens_": null,

    "mScreenQueued_": false,
    "mQueuedScreens_": null,

    function setup(){
        mActiveScreens_ = array(MAX_SCREENS, null);
        mPreviousScreens_ = array(MAX_SCREENS, null);
        mQueuedScreens_ = array(MAX_SCREENS, null);
    }

    /**
     * Immediate transition to a new screen.
     */
    function transitionToScreen(screenObject, transitionEffect = null, layerId = 0){
        assert(layerId < MAX_SCREENS);
        local current = mActiveScreens_[layerId];
        if(current != null){
            print("Calling shutdown for layer " + layerId);
            current.shutdown();
            mPreviousScreens_[layerId] = current
        }
        mActiveScreens_[layerId] = screenObject;

        if(!screenObject) return;

        print("Setting up screen for layer " + layerId);
        mActiveScreens_[layerId].setup();
    }

    /**
     * Queue the transition of the window to the start of the next frame.
     * This can help to ease issues if the transition happens deep in a callback stack.
     * i.e so the gui isn't deleted as part of its callback in an inconvenient way.
     */
    function queueTransition(screenObject, transitionEffect = null, layerId = 0){
        mQueuedScreens_[layerId] = screenObject;
        mScreenQueued_ = true;
    }

    /**
     * Head back to the previous screen, stored in memory.
     */
    function backupScreen(layerId){
        local prev = mPreviousScreens_[layerId];
        if(prev == null) return;
        transitionToScreen(prev, null, layerId);
    }

    function update(){
        if(mScreenQueued_){
            for(local i = 0; i < MAX_SCREENS; i++){
                local screen = mQueuedScreens_[i];
                if(!screen) continue;
                transitionToScreen(screen, null, i);
                mQueuedScreens_[i] = null;
            }
            mScreenQueued_ = false;
        }

        foreach(i in mActiveScreens_){
            if(i != null) i.update();
        }
    }
};

::ScreenManager.setup();