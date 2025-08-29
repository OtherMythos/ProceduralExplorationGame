enum GameplayMainMenuComplexWindow{
    EXPLORE,
    SECOND,
    THIRD,
    FOURTH,

    MAX
};

::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN] = class extends ::Screen{

    TabPanel = class{

        mParent_ = null;
        mButtons_ = null;

        constructor(parent){
            mParent_ = parent;
            mButtons_ = [];
        }

        function setup(numPanels){

            local win = mParent_.getWindow();
            local SIZE = 50;

            for(local i = 0; i < numPanels; i++){
                local button = win.createButton();
                button.setSize(SIZE, SIZE);
                button.setPosition(i * SIZE, 0);
                button.setUserId(i);
                button.setKeyboardNavigable(false);
                button.attachListenerForEvent(function(widget, action){
                    mParent_.notifyTabChange(widget.getUserId());
                }, _GUI_ACTION_PRESSED, this);
                mButtons_.append(button);
            }

        }

    };

    TabWindow = class{

        mId_ = null;
        mWindow_ = null;

        constructor(id){
            mId_ = id;

            mWindow_ = _gui.createWindow("TabWindow" + mId_);
            mWindow_.setZOrder(140);

            recreate();
        }

        function shutdown(){
            _gui.destroy(mWindow_);
        }

        function recreate(){
            local label = mWindow_.createLabel();
            label.setText("Window " + mId_);
        }

        function setPosition(pos){
            mWindow_.setPosition(pos);
        }

        function setSize(size){
            mWindow_.setSize(size);
        }

        function getSize(){
            return mWindow_.getSize();
        }

    };

    mTabPanel_ = null;
    mTabWindows_ = null;
    mPreviousTab_ = null;
    mCurrentTab_ = null;

    mAnimCount_ = 0;
    mAnimCountTotal_ = 0;

    function recreate(){
        mWindow_ = _gui.createWindow("GameplayMainMenuComplex");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        mTabPanel_ = TabPanel(this);
        mTabPanel_.setup(GameplayMainMenuComplexWindow.MAX);

        local targetWindows = [
            ExploreWindow
        ];
        mTabWindows_ = [];
        for(local i = 0; i < GameplayMainMenuComplexWindow.MAX; i++){
            local targetObj = TabWindow;
            if(i < targetWindows.len()){
                targetObj = targetWindows[i];
            }
            local tabWindow = targetObj(i);

            local size = _window.getSize();
            size.y -= 50;
            tabWindow.setSize(size);
            tabWindow.setPosition(Vec2(0, 50));
            mTabWindows_.append(tabWindow);
        }

        mCurrentTab_ = 0;
        notifyTabChange(mCurrentTab_);
    }

    function update(){
        if(mAnimCount_ == 0){
            updateTabPosition_(1.0);
            return;
        }

        mAnimCount_--;
        local percentage = mAnimCount_.tofloat() / mAnimCountTotal_.tofloat();
        print(percentage);

        updateTabPosition_(percentage);
    }

    function shutdown(){
        foreach(c,i in mTabWindows_){
            i.shutdown();
        }
    }

    function getWindow(){
        return mWindow_;
    }

    function notifyTabChange(idx){
        mPreviousTab_ = mCurrentTab_;
        mCurrentTab_ = idx;

        mAnimCountTotal_ = 10;
        mAnimCount_ = mAnimCountTotal_;
    }

    function updateTabPosition_(percentage){
        foreach(c,i in mTabWindows_){
            local size = i.getSize();
            local pos = Vec2(0, 50);
            //pos.x = (c.tofloat() - ( (mPreviousTab_ + (mCurrentTab_ -  mPreviousTab_) * percentage).tofloat())) * size.x;
            pos.x = (c.tofloat() - mCurrentTab_) * size.x;
            i.setPosition(pos);
        }
    }

};

//TODO move this out of global space
::ExploreWindow <- class extends ::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN].TabWindow{

    function recreate(){
        local line = _gui.createLayoutLine();

        local label = mWindow_.createLabel();
        label.setText("Explore");
        line.addCell(label);

        local button = mWindow_.createButton();
        button.setText("Explore");
        line.addCell(button);
        button.attachListenerForEvent(function(widget, action){
            local viableSaves = ::Base.mSaveManager.findViableSaves();
            local saveSlot = 0;
            local save = ::Base.mSaveManager.readSaveAtPath("user://" + viableSaves[saveSlot].tostring());
            ::Base.mPlayerStats.setSaveData(save, saveSlot);

            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
        }, _GUI_ACTION_PRESSED, this);

        line.layout();

    }

};