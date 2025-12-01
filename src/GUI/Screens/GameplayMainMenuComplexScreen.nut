enum GameplayMainMenuComplexWindow{
    EXPLORE,
    SECOND,
    THIRD,
    FOURTH,

    MAX
};

enum GameplayComplexMenuBusEvents{
    SHOW_EXPLORATION_MAP_STARTED,
    SHOW_EXPLORATION_MAP_FINISHED,
    CLOSE_EXPLORATION_STARTED,
    CLOSE_EXPLORATION_FINISHED,
};

::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN] = class extends ::Screen{

    ComplexScreenBus = class extends ::Screen.ScreenBus{
    };

    TabPanel = class{

        mBackgroundPanel_ = null;
        mWindow_ = null;

        mParent_ = null;
        mButtons_ = null;
        mPosition_ = null;
        mNumPanels_ = 1;
        mHeightOverride_ = 0;
        SIZE = 75;

        constructor(parent){
            mParent_ = parent;
            mButtons_ = [];
        }

        function setup(panelData){

            mNumPanels_ = panelData.len();

            local parentWin = mParent_.getWindow();
            local totalHeight = SIZE + 10;

            mHeightOverride_ = 100;

            local win = parentWin.createWindow("GameplayMainMenuComplex");
            win.setClipBorders(0, 0, 0, 0);
            win.setSize(::drawable.x, SIZE + 10 + mHeightOverride_);
            //win.setVisualsEnabled(false);
            mWindow_ = win;

            mBackgroundPanel_ = win.createPanel();
            mBackgroundPanel_.setSize(win.getSize());
            mBackgroundPanel_.setDatablock("simpleGrey");

            local linePanel = win.createPanel();
            linePanel.setSize(::drawable.x, 2);
            linePanel.setPosition(0, ::drawable.y - totalHeight);
            linePanel.setDatablock("unlitBlack");

            local padding = 10;
            local totalButtonsWidth = mNumPanels_ * (SIZE + padding);
            local buttonsStart = (win.getSize().x / 2 - totalButtonsWidth / 2);

            for(local i = 0; i < mNumPanels_; i++){
                local button = win.createButton();
                button.setSize(SIZE, SIZE);
                button.setPosition(buttonsStart + i * (SIZE + padding), 15);
                button.setUserId(i);
                button.setKeyboardNavigable(false);
                button.setVisualsEnabled(false);
                button.attachListenerForEvent(function(widget, action){
                    local tabId = widget.getUserId();
                    ::HapticManager.triggerSimpleHaptic(HapticType.SELECTION);
                    notifyTabChange_(tabId);
                    mParent_.notifyTabChange(tabId);
                }, _GUI_ACTION_PRESSED, this);

                if(i != mNumPanels_ - 1){
                    local buttonLine = mWindow_.createPanel();
                    buttonLine.setSize(2, SIZE + 20);
                    local pos = button.getPosition();
                    buttonLine.setPosition(pos.x + SIZE + 4, pos.y - 15);
                    buttonLine.setDatablock("unlitBlack");
                }

                local icon = win.createPanel();
                icon.setDatablock(panelData[i].icon);
                icon.setClickable(false);
                icon.setSize(SIZE, SIZE);
                local pos = button.getPosition();
                icon.setPosition(pos);

                local tabLabel = win.createLabel();
                tabLabel.setText(panelData[i].label);
                tabLabel.setCentre(button.getCentre());
                local labelPos = tabLabel.getPosition();
                labelPos.y = button.getPosition().y + button.getSize().y - tabLabel.getSize().y * 0.8;
                tabLabel.setPosition(labelPos);

                mButtons_.append({
                    "button": button,
                    "icon": icon,
                    "label": tabLabel,
                    "currentAnim": 0.0,
                    "targetAnim": 0.0,
                    "startPos": pos
                });
            }

            //setPosition(Vec2(0, 0));
            notifyTabChange_(0, false);
        }

        function update(){
            foreach(i in mButtons_){
                local current = i.currentAnim;
                local target = i.targetAnim;
                if(current == target) continue;

                if(current >= target){
                    current -= 0.1;
                    if(current <= target){
                        current = target;
                    }
                }
                else if(current <= target){
                    current += 0.1;
                    if(current >= target){
                        current = target;
                    }
                }
                i.currentAnim = current;
                local startPos = i.startPos;
                i.icon.setPosition(startPos.x, startPos.y - current * 20);
                i.label.setTextColour(1, 1, 1, current);
            }
        }

        function notifyTabChange_(id, animate=true){
            foreach(i in mButtons_){
                i.label.setVisible(false);
                i.targetAnim = 0.0;
            }

            local button = mButtons_[id];
            button.label.setVisible(true);
            button.targetAnim = 1.0;
            if(!animate){
                button.currentAnim = button.targetAnim - 0.001;
            }
        }

        function setPosition(pos){
            mPosition_ = pos;
            mWindow_.setPosition(pos.x, pos.y);
        }

        function getSize(){
            return Vec2(mNumPanels_ * (SIZE + 10), SIZE + 15);
        }

    };

    TabWindow = class{

        mId_ = null;
        mBus_ = null;
        mWindow_ = null;

        constructor(id, bus){
            mId_ = id;
            mBus_ = bus;

            mWindow_ = _gui.createWindow("TabWindow" + mId_);
            mWindow_.setVisualsEnabled(false);
        }

        function setZOrder(idx){
            mWindow_.setZOrder(idx);
        }

        function shutdown(){
            _gui.destroy(mWindow_);
        }

        function recreate(){
            local label = mWindow_.createLabel();
            label.setText("Window " + mId_);
        }

        function update(){

        }

        function setPosition(pos){
            mWindow_.setPosition(pos);
        }

        function setSize(size){
            mWindow_.setSize(size);
            recreate();
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
    mTabWindowYStart_ = 0;
    mPreviousTab_ = null;
    mCurrentTab_ = null;
    mPlayerStats_ = null;
    mBus_ = null;
    mHasShutdown_ = false;

    mAnimCount_ = 0;
    mAnimCountTotal_ = 0;

    function bodgeLoadSave(){
        if(!getroottable().rawin("saveLoadedBefore")){
            ::saveLoadedBefore <- false;
        }
        if(::saveLoadedBefore){
            return;
        }
        ::saveLoadedBefore = true;

        local viableSaves = ::Base.mSaveManager.findViableSaves();
        if(viableSaves.len() <= 0){
            local freeSlot = ::SaveManager.getFreeSaveSlot();
            local save = ::Base.mSaveManager.produceSave();
            save.playerName = "test";
            ::Base.mPlayerStats.setSaveData(save, freeSlot);
            ::SaveManager.writeSaveAtPath("user://" + freeSlot, ::Base.mPlayerStats.getSaveData());
        }else{
            local saveSlot = 0;
            local save = ::Base.mSaveManager.readSaveAtPath("user://" + viableSaves[saveSlot].tostring());
            ::Base.mPlayerStats.setSaveData(save, saveSlot);
        }
    }

    function recreate(){

        bodgeLoadSave();

        mBus_ = ComplexScreenBus();
        mBus_.registerCallback(busCallback, this);
        mWindow_ = _gui.createWindow("GameplayMainMenuComplex");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        local insets = _window.getScreenSafeAreaInsets();

        local stats = ::GuiWidgets.PlayerBasicStatsWidget();
        stats.setup(mWindow_);
        stats.setPlayerStats(::Base.mPlayerStats);
        stats.setPosition(Vec2(0, insets.top));
        mPlayerStats_ = stats;

        local tabs = [
            {"icon": "swordsIcon", "label": "Explore"},
            {"icon": "bagIcon", "label": "Inventory"},
            {"icon": "helmetCoinsIcon", "label": "Shop"},
            {"icon": "treasureChestIcon", "label": "Offers"},
        ];
        mTabPanel_ = TabPanel(this);
        mTabPanel_.setup(tabs);
        local tabSize = mTabPanel_.getSize();
        //mTabPanel_.setPosition(Vec2(::drawable.x / 2 - tabSize.x / 2, ::drawable.y - tabSize.y - insets.bottom))
        mTabPanel_.setPosition(Vec2(0, ::drawable.y - tabSize.y - insets.bottom));

        mTabWindowYStart_ = insets.top + stats.getSize().y;

        local targetWindows = [
            ExploreWindow,
            InventoryWindow,
            ShopWindow
        ];
        mTabWindows_ = [];
        for(local i = 0; i < GameplayMainMenuComplexWindow.MAX; i++){
            local targetObj = TabWindow;
            if(i < targetWindows.len()){
                targetObj = targetWindows[i];
            }
            //local offset = Vec2(0, 0);
            local tabWindow = targetObj(i, mBus_);

            local size = ::drawable.copy();
            size.y -= tabSize.y;
            size.y -= insets.bottom;
            size.y -= insets.top;
            size.y -= stats.getSize().y;
            tabWindow.setSize(size);
            tabWindow.setPosition(Vec2(0, stats.getSize().y));
            mTabWindows_.append(tabWindow);
        }

        mCurrentTab_ = 0;
        notifyTabChange(mCurrentTab_);
        updateTabPosition_(1.0);

        //Transition to title screen at layer 2 with panel coordinates for animation
        local panel = mTabWindows_[0].getMapPanel();
        local titleData = {
            "pos": panel.getDerivedPosition(),
            "size": panel.getSize(),
            "bus": mBus_,
            "animateIn": false
        };
        ::ScreenManager.transitionToScreen( ::ScreenManager.ScreenData( Screen.GAME_TITLE_SCREEN, titleData ), null, 2 );
    }

    function update(){
        foreach(i in mTabWindows_){
            i.update();
        }

        if(mAnimCount_ == 0){
            updateTabPosition_(1.0);
            return;
        }

        mAnimCount_--;
        local percentage = mAnimCount_.tofloat() / mAnimCountTotal_.tofloat();

        updateTabPosition_(percentage);
        mTabPanel_.update();
    }

    function setZOrder(idx){
        base.setZOrder(idx);

        foreach(i in mTabWindows_){
            i.setZOrder(idx + 1);
        }
    }

    function shutdown(){
        mHasShutdown_ = true;
        base.shutdown();

        foreach(c,i in mTabWindows_){
            i.shutdown();
        }
        mTabWindows_.clear();
        mPlayerStats_.shutdown();
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
            pos.y = mTabWindowYStart_;
            i.setPosition(pos);
        }
    }

    function setExplorationMapVisible(vis){
        mTabWindows_[0].getMapPanel().setVisible(vis);
    }

    function busCallback(event, data){
        if(mHasShutdown_) return;

        if(event == GameplayComplexMenuBusEvents.SHOW_EXPLORATION_MAP_STARTED){
            setExplorationMapVisible(false);
            ::OverworldLogic.requestState(OverworldStates.ZOOMED_IN);
        }
        else if(event == GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_STARTED){
            ::OverworldLogic.requestState(OverworldStates.ZOOMED_OUT);
        }
        else if(event == GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_FINISHED){
            setExplorationMapVisible(true);
        }
    }

};

::ShopWindow <- class extends ::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN].TabWindow{
    mBankPanel_ = null;
    mShopPanel_ = null;

    function recreate(){
        mBankPanel_ = ::BankWidget(mWindow_);
        mBankPanel_.setup();

        mShopPanel_ = ::ShopWidget(mWindow_);
        local shopStart = mBankPanel_.getSize() + 10;
        shopStart.x = 0;
        mShopPanel_.setup(shopStart);
    }
};

//TODO move this out of global space
::InventoryWindow <- class extends ::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN].TabWindow{

    mInventoryObj_ = null;

    function recreate(){
        mWindow_.setClipBorders(0, 0, 0, 0);

        mInventoryObj_ = ::InventoryScreenObject();
        mInventoryObj_.setup(mWindow_, {
            "stats": ::Base.mPlayerStats,
            "disableBackground": true,
            "disableBackButton": true,
            "disableBackgroundClose": true,
            "supportsStorage": true
        });

        mWindow_.sizeScrollToFit();
        local maxScroll = mWindow_.getMaxScroll();
        maxScroll.y += 50;
        mWindow_.setMaxScroll(maxScroll);
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        mInventoryObj_.setZOrder(idx);
    }

    function update(){
        base.update();

        mInventoryObj_.update();
    }

    function shutdown(){
        mInventoryObj_.shutdown();

        base.shutdown();
    }
}

::ExploreWindow <- class extends ::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN].TabWindow{

    mCompositor_ = null;
    mMapPanel_ = null;
    mOrbCounter_ = null;
    mReturnToTitleButton_ = null;

    function recreate(){
        local line = _gui.createLayoutLine();
        local insets = _window.getScreenSafeAreaInsets();

        mWindow_.setClipBorders(0, 0, 0, 0);

        /*
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
        */

        local currentY = 0;

        local settingsButton = ::IconButton(mWindow_, "settingsIcon");
        settingsButton.setSize(Vec2(64, 64));
        settingsButton.setPosition(Vec2(10, 10));
        settingsButton.attachListenerForEvent(function(widget, action){
            ::ScreenManager.queueTransition(Screen.SETTINGS_SCREEN, null, 3);
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
        }, _GUI_ACTION_PRESSED, this);

        currentY += settingsButton.getPosition().y + settingsButton.getSize().y;

        local newspaperButton = ::IconButton(mWindow_, "newspaperIcon");
        newspaperButton.setSize(Vec2(64, 64));
        local newspaperPos = settingsButton.getPosition() + Vec2(10, 0);
        newspaperPos.x += settingsButton.getSize().x;
        newspaperButton.setPosition(newspaperPos);
        newspaperButton.attachListenerForEvent(function(widget, action){
            ::ScreenManager.queueTransition(Screen.SETTINGS_SCREEN, null, 3);
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
        }, _GUI_ACTION_PRESSED, this);


        local winSize = mWindow_.getSize();

        local MARGIN = 10;
        currentY += MARGIN;
        local explorationMap = mWindow_.createPanel();
        explorationMap.setPosition(MARGIN, currentY);
        explorationMap.setSize(winSize.x - MARGIN * 2, 300);
        mMapPanel_ = explorationMap;

        _gameCore.setCameraForNode("renderMainGameplayNode", "compositor/camera" + ::CompositorManager.mTotalCompositors_);
        /*
        {
            local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
            local size = explorationMap.getSize() * ::resolutionMult;
            _gameCore.setupCompositorDefs(size.x.tointeger(), size.y.tointeger());
        }
        mCompositor_ = ::CompositorManager.createCompositorWorkspace("renderWindowWorkspaceGameplayTexture", explorationMap.getSize() * ::resolutionMult, CompositorSceneType.OVERWORLD);
        */

        currentY += explorationMap.getSize().y;
        local explorePanelButton = mWindow_.createButton();
        explorePanelButton.setPosition(explorationMap.getPosition());
        explorePanelButton.setSize(explorationMap.getSize());
        explorePanelButton.setVisualsEnabled(false);
        explorePanelButton.attachListenerForEvent(function(widget, action){
            local startPos = Vec2(_input.getMouseX(), _input.getMouseY()) / ::drawable;
            notifyExplorationBegin_(startPos);
        }, _GUI_ACTION_PRESSED, this);

        currentY -= 20;
        local playIconButton = ::IconButtonComplex(mWindow_, {
            "icon": "swordsIcon",
            "iconSize": Vec2(80, 80),
            "iconPosition": Vec2(0, 0),
            "label": "Explore",
            "labelPosition": Vec2(80, 0),
            "labelSizeModifier": 2
        });
        playIconButton.setSize(Vec2(240, 80));
        playIconButton.setPosition(Vec2(MARGIN + explorationMap.getSize().x / 2 - playIconButton.getSize().x / 2, currentY));
        playIconButton.attachListenerForEvent(function(widget, action){
            notifyExplorationBegin_(null);
        }, _GUI_ACTION_PRESSED, this);

        {
            local orbCount = ::Base.mPlayerStats.getNumFoundOrbs();
            local orbCounter = ::IconButtonComplex(mWindow_, {
                "icon": "largeOrbIcon",
                "iconSize": Vec2(50, 50),
                "iconPosition": Vec2(5, 5),
                "label": orbCount.tostring(),
                "labelPosition": Vec2(60, -10),
                "labelSizeModifier": 2,
                "usePanelForButton": true
            });
            //orbCounter.setSize(Vec2(140, 60));
            orbCounter.setPosition(explorationMap.getPosition());
            local minSize = orbCounter.getMinimumSize();
            orbCounter.setSize(Vec2(minSize.x + 10, 60));
            orbCounter.setButtonColour(ColourValue(0.2, 0.2, 0.2, 0.8));
            mOrbCounter_ = orbCounter;
        }

        //Add button to return to title screen
        local returnToTitleButton = ::IconButton(mWindow_, "backButtonIcon");
        returnToTitleButton.setSize(Vec2(64, 64));
        local returnButtonPos = newspaperButton.getPosition() + Vec2(newspaperButton.getSize().x + 10, 0);
        returnToTitleButton.setPosition(returnButtonPos);
        returnToTitleButton.attachListenerForEvent(function(widget, action){
            returnToTitleScreen_();
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
        }, _GUI_ACTION_PRESSED, this);
        mReturnToTitleButton_ = returnToTitleButton;

        line.layout();

        ::OverworldLogic.requestSetup();
        ::OverworldLogic.requestState(OverworldStates.ZOOMED_OUT);
        local datablock = ::OverworldLogic.getCompositorDatablock();
        explorationMap.setDatablock(datablock);

        //Transition to title screen at layer 2 with panel coordinates for animation
        local titleData = {
            "pos": explorationMap.getDerivedPosition(),
            "size": explorationMap.getSize(),
            "bus": mBus_,
            "animateIn": false
        };
        ::ScreenManager.transitionToScreen( ::ScreenManager.ScreenData( Screen.GAME_TITLE_SCREEN, titleData ), null, 2 );
    }

    function getMapPanel(){
        return mMapPanel_;
    }

    function shutdown(){
        mMapPanel_.setDatablock("simpleGrey");
        base.shutdown();

        ::OverworldLogic.requestShutdown();
    }

    function notifyExplorationBegin_(startScreenPos){
        ::Base.applyCompositorModifications()
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_MAP_SELECT_SCREEN, mBus_), null, 3);

        ::OverworldLogic.setMapPositionFromPress(startScreenPos);

        local panel = getMapPanel();
        local data = {
            "pos": panel.getDerivedPosition(),
            "size": panel.getSize()
        };
        mBus_.notifyEvent(GameplayComplexMenuBusEvents.SHOW_EXPLORATION_MAP_STARTED, data);
    }

    function update(){
        base.update();

        ::OverworldLogic.update();
    }

    function returnToTitleScreen_(){
        //Re-setup the title screen on layer 2 with panel coordinates
        local explorationMap = getMapPanel();
        local titleData = {
            "pos": explorationMap.getDerivedPosition(),
            "size": explorationMap.getSize(),
            "bus": mBus_,
            "animateIn": true
        };
        ::ScreenManager.transitionToScreen( ::ScreenManager.ScreenData( Screen.GAME_TITLE_SCREEN, titleData ), null, 2 );
    }

};
