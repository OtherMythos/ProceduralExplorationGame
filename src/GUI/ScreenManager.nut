::ScreenManager <- {

    "MAX_SCREENS": 4,
    "MAX_PREV_SCREENS": 3,
    //Contains screen objects rather than construction data.
    "mActiveScreens_": null,
    //Construction data for the previous screens the user has visited.
    "mPreviousScreens_": null,

    "mScreenQueued_": false,
    "mQueuedScreens_": null,

    mBGEffectRenderWindow = null
    mFGEffectRenderWindow = null
    mVersionInfoWindow_ = null

    mCurrentAspect = null

    mScreensZOrder = SCREENS_START_Z

    mDefaultCoords_ = null

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

        mBGEffectRenderWindow = EffectAnimationRenderWindow(CompositorSceneType.BG_EFFECT);
        mBGEffectRenderWindow.setZOrder(mScreensZOrder);

        for(local i = 0; i < MAX_SCREENS; i++){
            mPreviousScreens_[i] = [];
        }

        mFGEffectRenderWindow = EffectAnimationRenderWindow(CompositorSceneType.FG_EFFECT);
        mFGEffectRenderWindow.setZOrder(mScreensZOrder + MAX_SCREENS + 1);

        if(!(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE))){
            mVersionInfoWindow_ = VersionInfoWindow(::getVersionInfo());
        }

        processResize();
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

    function _shutdownForLayer(layerId, effectPrevStack = false){
        local current = mActiveScreens_[layerId];
        if(current == null) return null;
        local currentIdx = current.getScreenData().id;

        print("Calling shutdown for layer " + layerId);
        current.shutdown();
        if(effectPrevStack) _queuePrevScreen(layerId, current.getScreenData());

        return currentIdx;
    }

    function getScreenForLayer(layerIdx=0){
        return mActiveScreens_[layerIdx];
    }

    function isScreenPresentForLayer(layerIdx){
        return mActiveScreens_[layerIdx] != null;
    }

    /**
     * Immediate transition to a new screen.
     */
    function transitionToScreen(screenId, transitionEffect = null, layerId = 0, effectPrevStack = true){
        assert(layerId < MAX_SCREENS);
        local oldId = _shutdownForLayer(layerId, effectPrevStack);

        local screenData = _wrapScreenData(screenId);
        local screenObject = _createScreenForId(screenData);

        mActiveScreens_[layerId] = screenObject;

        if(!screenObject){
            _gui.simulateMouseButton(_MB_LEFT, false);
            _gui.reprocessMousePosition();
            _gui.simulateGuiPrimary(false);
            return;
        }

        print("Setting up screen for layer " + layerId);
        screenObject.mLayerIdx = layerId;
        _gui.simulateGuiPrimary(false);
        screenObject.setup(screenData.data);
        screenObject.setZOrder(mScreensZOrder + layerId + 1);
        if(!screenObject.mCustomPosition_) screenObject.setPositionCentre(_window.getWidth()/2, _window.getHeight()/2);

        _event.transmit(Event.SCREEN_CHANGED, {"old": oldId, "new": screenId});

        _gui.simulateMouseButton(_MB_LEFT, false);
        _gui.reprocessMousePosition();
    }

    function _getPrevScreen(layerId){
        local target = mPreviousScreens_[layerId];
        if(target.len() == 0){
            return null;
        }
        local screenData = target.top();
        target.pop();
        print("returning data " + screenData.id);
        _debugPrintStack(layerId);
        return screenData;
    }

    function _queuePrevScreen(layerId, screenData){
        local target = mPreviousScreens_[layerId];
        target.append(screenData);
        if(target.len() > MAX_PREV_SCREENS){
            target.remove(0);
        }
        print(screenData.id);
        _debugPrintStack(layerId);
    }

    function _debugPrintStack(layerId){
        local target = mPreviousScreens_[layerId];
        foreach(c,i in target){
            print(c.tostring() + ": " + i.id);
        }
    }

    /**
     * Queue the transition of the window to the start of the next frame.
     * This can help to ease issues if the transition happens deep in a callback stack.
     * i.e so the gui isn't deleted as part of its callback in an inconvenient way.
     */
    function queueTransition(screenData, transitionEffect = null, layerId = 0){
        //TODO transitionEffect isn't implemented yet as I don't use them.
        local data = _wrapScreenData(screenData);
        //TODO this is a bit of a work around.
        //For immediate transition null is fine, but here null means nothing waiting to be transitioned.
        //This means I need to mark in some way which screen needs to be reset, if null is passed in (meaning destroy window).
        if(data == null) data = ::ScreenManager.ScreenData(null, null);
        mQueuedScreens_[layerId] = data;
        mScreenQueued_ = true;
    }

    /**
     * Head back to the previous screen, stored in memory.
     */
    function backupScreen(layerId){
        local prev = _getPrevScreen(layerId);
        transitionToScreen(prev, null, layerId, false);
    }

    function update(){
        if(mScreenQueued_){
            for(local i = 0; i < MAX_SCREENS; i++){
                local screenData = mQueuedScreens_[i];
                if(!screenData) continue;
                print("Transitioning screen for layer " + i);
                if(screenData.id == null && screenData.data == null){
                    screenData = null;
                }
                transitionToScreen(screenData, null, i);
                mQueuedScreens_[i] = null;
            }
            mScreenQueued_ = false;
        }

        foreach(i in mActiveScreens_){
            if(i != null) i.update();
        }
    }

    function processResize(){
        calculateAspectRatio();
        if(mVersionInfoWindow_ != null){
            mVersionInfoWindow_.processResize();
        }
    }

    function calculateAspectRatio(){
        local defaultCoords = null;
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            defaultCoords = Vec2(_window.getWidth(), _window.getHeight());
        }else{
            defaultCoords = Vec2(1920, 1080);
        }
        mDefaultCoords_ = defaultCoords;

        local currentSize = _window.getSize();

        local outCoords = Vec2(currentSize.x, currentSize.y);
        local percentageX = (currentSize.x / defaultCoords.x);
        local percentageY = (currentSize.y / defaultCoords.y);
        if(percentageX < percentageY){
            outCoords.x = currentSize.x;
            outCoords.y = percentageX * defaultCoords.y;
        }
        else if(percentageY < percentageX){
            outCoords.y = currentSize.y;
            outCoords.x = percentageY * defaultCoords.x;
        }

        local finishedSize = Vec2(outCoords.x / currentSize.x, outCoords.y / currentSize.y)
        ::drawable = finishedSize * currentSize;

        foreach(c,i in mActiveScreens_){
            if(i == null) continue;
            //i.setSize(0.5, 0.5);
            i.notifyResize();
            if(!i.mCustomSize_) i.setSize(::drawable.x, ::drawable.y);
            if(!i.mCustomPosition_) i.setPositionCentre(currentSize.x/2, currentSize.y/2);
            i.setZOrder(mScreensZOrder + c + 1);
        }
    }

    function calculateRatio(width){
        local gridRatio = width.tofloat() / mDefaultCoords_.x;
        return ::drawable.x * gridRatio;
    }

    function isForefrontScreen(id){
        if(id < 0 || id >= MAX_SCREENS) return false;

        local found = false;
        for(local i = id+1; i < MAX_SCREENS; i++){
            if(mActiveScreens_[i] != null){
                found = true;
                break;
            }
        }

        return !found;
    }
};