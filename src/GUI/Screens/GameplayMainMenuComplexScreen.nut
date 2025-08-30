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
        mPosition_ = null;
        mNumPanels_ = 1;
        SIZE = 75;

        constructor(parent){
            mParent_ = parent;
            mButtons_ = [];
        }

        function setup(numPanels){

            mNumPanels_ = numPanels;

            local win = mParent_.getWindow();

            for(local i = 0; i < mNumPanels_; i++){
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

            setPosition(Vec2(0, 0));
        }

        function setPosition(pos){
            mPosition_ = pos;

            for(local i = 0; i < mNumPanels_; i++){
                mButtons_[i].setPosition(mPosition_ + Vec2(i * (SIZE + 10), 0));
            }
        }

        function getSize(){
            return Vec2(mNumPanels_ * (SIZE + 10), SIZE);
        }

    };

    TabWindow = class{

        mId_ = null;
        mWindow_ = null;
        mOffset_ = null;

        constructor(id, offset){
            mId_ = id;

            mWindow_ = _gui.createWindow("TabWindow" + mId_);
            mWindow_.setZOrder(140);
            mWindow_.setVisualsEnabled(false);

            mOffset_ = offset;

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
            mWindow_.setPosition(pos + mOffset_);
        }

        function setSize(size){
            mWindow_.setSize(size);
        }

        function getSize(){
            return mWindow_.getSize();
        }

        function getOffset(){
            return mOffset_;
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
        //mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        local insets = _window.getScreenSafeAreaInsets();

        local stats = MainMenuStatsWidget();
        stats.setup(mWindow_);
        stats.setPosition(Vec2(0, insets.top));

        mTabPanel_ = TabPanel(this);
        mTabPanel_.setup(GameplayMainMenuComplexWindow.MAX);
        local tabSize = mTabPanel_.getSize();
        mTabPanel_.setPosition(Vec2(::drawable.x / 2 - tabSize.x / 2, ::drawable.y - tabSize.y - insets.bottom))

        local targetWindows = [
            ExploreWindow
        ];
        mTabWindows_ = [];
        for(local i = 0; i < GameplayMainMenuComplexWindow.MAX; i++){
            local targetObj = TabWindow;
            if(i < targetWindows.len()){
                targetObj = targetWindows[i];
            }
            local offset = Vec2(0, insets.bottom + stats.getSize().y);
            local tabWindow = targetObj(i, offset);

            local size = ::drawable.copy();
            size.y -= tabSize.y;
            size.y -= insets.bottom;
            size.y -= stats.getSize().y;
            tabWindow.setSize(size);
            tabWindow.setPosition(Vec2(0, stats.getSize().y));
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
        base.shutdown();

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
            local pos = Vec2(0, 0);
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
        local insets = _window.getScreenSafeAreaInsets();

        mWindow_.setClipBorders(0, 0, 0, 0);

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Explore", false);
        title.sizeToFit(::drawable.x * 0.9);
        line.addCell(title);

        local button = mWindow_.createButton();
        button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
        button.setText("Explore");
        button.setExpandHorizontal(true);
        line.addCell(button);
        button.attachListenerForEvent(function(widget, action){
            local viableSaves = ::Base.mSaveManager.findViableSaves();
            local saveSlot = 0;
            local save = ::Base.mSaveManager.readSaveAtPath("user://" + viableSaves[saveSlot].tostring());
            ::Base.mPlayerStats.setSaveData(save, saveSlot);

            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
        }, _GUI_ACTION_PRESSED, this);

        line.setSize(::drawable);
        line.setPosition(::drawable.x * 0.0, insets.top);
        line.setGridLocationForAllCells(_GRID_LOCATION_CENTER);

        line.layout();

    }

};

::MainMenuStatsWidget <- class{

    mCoinLabel_ = null;
    mEXPOrbLabel_ = null;

    mWindow_ = null;
    mSize_ = null;

    function setPosition(pos){
        mWindow_.setPosition(pos);
    }

    function getSize(){
        return mSize_;
    }

    function setup(parentWindow){

        local window = parentWindow.createWindow();

        local statsSize = Vec2(::drawable.x, 50);
        local leftCount = 0;
        mSize_ = statsSize;

        window.setSize(statsSize);
        window.setVisualsEnabled(false);
        window.setClipBorders(0, 0, 0, 0);
        mWindow_ = window;

        /*
        local debugBackground = window.createPanel();
        debugBackground.setSize(statsSize);
        debugBackground.setPosition(0, 0);
        debugBackground.setDatablock("playerMapIndicator");
        */

        {
            local heartIcon = window.createPanel();
            heartIcon.setDatablock("healthIcon");
            heartIcon.setSize(48, 48);
            heartIcon.setPosition(0, 0);
            leftCount += 50;

            local healthBar = ::GuiWidgets.ProgressBar(window);
            local barSize = statsSize.x / 2 - leftCount;
            local barHeight = 35;
            healthBar.setSize(barSize, barHeight);
            healthBar.setPercentage(0.5);
            healthBar.setBorder(2);
            healthBar.setPosition(leftCount, statsSize.y / 2 - barHeight / 2);
            healthBar.setLabel("120/240");
            leftCount += barSize;
        }

        {
            local orbIcon = window.createPanel();
            orbIcon.setDatablock("orbsIcon");
            orbIcon.setSize(48, 48);
            orbIcon.setPosition(leftCount, 0);
            leftCount += 48;

            mEXPOrbLabel_ = window.createLabel();
            mEXPOrbLabel_.setDefaultFontSize(mEXPOrbLabel_.getDefaultFontSize() * 1.2);
            mEXPOrbLabel_.setText("120");
            mEXPOrbLabel_.setPosition(leftCount, 0);
            leftCount += mEXPOrbLabel_.getSize().x;
        }

        {
            local coinIcon = window.createPanel();
            coinIcon.setDatablock("coinsIcon");
            coinIcon.setSize(48, 48);
            coinIcon.setPosition(leftCount, 0);
            leftCount += 48;

            mCoinLabel_ = window.createLabel();
            mCoinLabel_.setDefaultFontSize(mCoinLabel_.getDefaultFontSize() * 1.2);
            mCoinLabel_.setText("240");
            mCoinLabel_.setPosition(leftCount, 0);
            leftCount += mCoinLabel_.getSize().x;
        }

        foreach(c,i in [
            "coinsIcon",
            "settingsIcon",
            "healthIcon",
            "orbsIcon",
            "playIcon",
            "swordsIcon",
        ]){
            local panelThing = window.createPanel();
            panelThing.setDatablock(i);
            panelThing.setSize(64, 64);
            panelThing.setPosition(200, 200 + c * 50);
        }
    }

};