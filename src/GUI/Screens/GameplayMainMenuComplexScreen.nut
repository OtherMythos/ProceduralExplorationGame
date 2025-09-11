enum GameplayMainMenuComplexWindow{
    EXPLORE,
    SECOND,
    THIRD,
    FOURTH,

    MAX
};

::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN] = class extends ::Screen{

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

            local win = parentWin.createWindow();
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
        mWindow_ = null;

        constructor(id){
            mId_ = id;

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

    mAnimCount_ = 0;
    mAnimCountTotal_ = 0;

    function recreate(){
        mWindow_ = _gui.createWindow("GameplayMainMenuComplex");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        local insets = _window.getScreenSafeAreaInsets();

        local stats = ::GuiWidgets.PlayerBasicStatsWidget();
        stats.setup(mWindow_);
        stats.setPosition(Vec2(0, insets.top));
        mPlayerStats_ = stats;

        local tabs = [
            {"icon": "swordsIcon", "label": "Explore"},
            {"icon": "bagIcon", "label": "Inventory"},
            {"icon": "settingsIcon", "label": "Second"},
            {"icon": "settingsIcon", "label": "Third"},
        ];
        mTabPanel_ = TabPanel(this);
        mTabPanel_.setup(tabs);
        local tabSize = mTabPanel_.getSize();
        //mTabPanel_.setPosition(Vec2(::drawable.x / 2 - tabSize.x / 2, ::drawable.y - tabSize.y - insets.bottom))
        mTabPanel_.setPosition(Vec2(0, ::drawable.y - tabSize.y - insets.bottom));

        mTabWindowYStart_ = insets.top + stats.getSize().y;

        local targetWindows = [
            ExploreWindow
        ];
        mTabWindows_ = [];
        for(local i = 0; i < GameplayMainMenuComplexWindow.MAX; i++){
            local targetObj = TabWindow;
            if(i < targetWindows.len()){
                targetObj = targetWindows[i];
            }
            //local offset = Vec2(0, 0);
            local tabWindow = targetObj(i);

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
        mTabPanel_.update();
    }

    function setZOrder(idx){
        base.setZOrder(idx);

        foreach(i in mTabWindows_){
            i.setZOrder(idx + 1);
        }
    }

    function shutdown(){
        base.shutdown();

        foreach(c,i in mTabWindows_){
            i.shutdown();
        }
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

};

//TODO move this out of global space
::ExploreWindow <- class extends ::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN].TabWindow{

    mCompositor_ = null;

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

        local iconButton = ::IconButton(mWindow_, "settingsIcon");
        iconButton.setSize(Vec2(64, 64));
        iconButton.setPosition(Vec2(10, 10));
        iconButton.attachListenerForEvent(function(widget, action){
            ::ScreenManager.queueTransition(Screen.SETTINGS_SCREEN, null, 3);
        }, _GUI_ACTION_PRESSED, this);

        local currentY = iconButton.getPosition().y + iconButton.getSize().y;

        local winSize = mWindow_.getSize();

        local MARGIN = 10;
        currentY += MARGIN;
        local explorationMap = mWindow_.createPanel();
        explorationMap.setPosition(MARGIN, currentY);
        explorationMap.setSize(winSize.x - MARGIN * 2, 300);

        _gameCore.setCameraForNode("renderMainGameplayNode", "compositor/camera" + ::CompositorManager.mTotalCompositors_);
        {
            local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
            local size = explorationMap.getSize() * ::resolutionMult;
            _gameCore.setupCompositorDefs(size.x.tointeger(), size.y.tointeger());
        }
        mCompositor_ = ::CompositorManager.createCompositorWorkspace("renderWindowWorkspaceGameplayTexture", explorationMap.getSize() * ::resolutionMult, CompositorSceneType.OVERWORLD);
        local datablock = ::CompositorManager.getDatablockForCompositor(mCompositor_);

        explorationMap.setDatablock(datablock);
        currentY += explorationMap.getSize().y;
        local explorePanelButton = mWindow_.createButton();
        explorePanelButton.setPosition(explorationMap.getPosition());
        explorePanelButton.setSize(explorationMap.getSize());
        explorePanelButton.setVisualsEnabled(false);
        explorePanelButton.attachListenerForEvent(function(widget, action){
            notifyExplorationBegin_();
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
            notifyExplorationBegin_();
        }, _GUI_ACTION_PRESSED, this);

        line.layout();

        ::OverworldLogic.setup();
    }

    function shutdown(){
        base.shutdown();

        ::OverworldLogic.shutdown();
    }

    function notifyExplorationBegin_(){
        ::Base.applyCompositorModifications()
        ::ScreenManager.queueTransition(Screen.EXPLORATION_MAP_SELECT_SCREEN, null, 3);
    }

};
