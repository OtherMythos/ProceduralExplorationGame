::ScreenManager <- {

    "MAX_SCREENS": 3,
    //Contains screen objects rather than construction data.
    "mActiveScreens_": null,
    //Construction data for the previous screens the user has visited.
    "mPreviousScreens_": null,

    "mScreenQueued_": false,
    "mQueuedScreens_": null,

    "Screens": array(Screen.MAX, null),

    /**
     * Class to wrap screen data for construction and transition.
     * The id of the screen as well as its setup data are coupled to facilitate creation.
     */
    "ScreenData": class{
        id = Screen.SCREEN;
        data = null;
        constructor(id, data){
            this.id = id;
            this.data = data;
        }
        function _typeof(){
            return ObjectType.SCREEN_DATA;
        }
    },

    function setup(){
        mActiveScreens_ = array(MAX_SCREENS, null);
        mPreviousScreens_ = array(MAX_SCREENS, null);
        mQueuedScreens_ = array(MAX_SCREENS, null);
    }

    function _createScreenForId(screenData){
        if(screenData == null){
            return null;
        }
        return Screens[screenData.id](screenData);
    }

    function _wrapScreenData(data){
        if(data == null) return data;
        local screenData = data;
        if(typeof screenData != ObjectType.SCREEN_DATA){
            screenData = ScreenData(data, null);
        }
        return screenData;
    }

    /**
     * Immediate transition to a new screen.
     */
    function transitionToScreen(screenId, transitionEffect = null, layerId = 0){
        assert(layerId < MAX_SCREENS);
        local current = mActiveScreens_[layerId];
        if(current != null){
            print("Calling shutdown for layer " + layerId);
            current.shutdown();
            //TODO actually stack the data in an array.
            mPreviousScreens_[layerId] = current.getScreenData();
            print("Setting previous");
        }

        local screenData = _wrapScreenData(screenId);
        local screenObject = _createScreenForId(screenData);

        mActiveScreens_[layerId] = screenObject;

        if(!screenObject) return;

        print("Setting up screen for layer " + layerId);
        mActiveScreens_[layerId].setup(screenData.data);
    }

    /**
     * Queue the transition of the window to the start of the next frame.
     * This can help to ease issues if the transition happens deep in a callback stack.
     * i.e so the gui isn't deleted as part of its callback in an inconvenient way.
     */
    function queueTransition(screenData, transitionEffect = null, layerId = 0){
        //TODO transitionEffect isn't implemented yet as I don't use them.
        local data = _wrapScreenData(screenData);
        mQueuedScreens_[layerId] = data;
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
                local screenData = mQueuedScreens_[i];
                if(!screenData) continue;
                transitionToScreen(screenData, null, i);
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