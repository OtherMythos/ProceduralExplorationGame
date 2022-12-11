::ScreenManager.Screens[Screen.COMBAT_SPOILS_POPUP_SCREEN] = class extends ::Screen{

    mBackgroundWindow_ = null;
    mItemsContainer = null;
    mBus_ = null;

    function setup(data){
        local winWidth = _window.getWidth() * 0.9;
        mBus_ = ScreenBus();

        //Create a window to block inputs for when the popup appears.
        mBackgroundWindow_ = createBackgroundScreen_();

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(winWidth, _window.getHeight() * 0.333);
        mWindow_.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.333);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Victory!");
        title.setSize(winWidth, title.getSize().y);
        layoutLine.addCell(title);

        mItemsContainer = ::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer(mWindow_, mBus_);
        mItemsContainer.addToLayout(layoutLine);

        local buttonNames = ["Scrap All", "Finish"];
        local buttonFunctions = [
            function(widget, action){
                print("Scrapping");
                closeScreen();
            },
            function(widget, action){
                print("Finish");
                closeScreen();
            }
        ];
        foreach(c,i in buttonNames){
            local button = mWindow_.createButton();
            //button.setDefaultFontSize(button.getDefaultFontSize() * 1.2);
            button.setText(i);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 50);
            button.setProportionHorizontal(1);
            layoutLine.addCell(button);
        }

        setObjectsForData(data);

        layoutLine.setSize(mWindow_.getSizeAfterClipping());
        layoutLine.setHardMaxSize(mWindow_.getSizeAfterClipping());
        layoutLine.layout();
        mItemsContainer.sizeForButtons();

        mBus_.registerCallback(busCallback, this);
    }

    function setObjectsForData(data){
        local combatData = data.logic.mData_;
        local spoils = combatData.mCombatSpoils;
        for(local i = 0; i < spoils.len(); i++){
            if(spoils[i] == null) continue;
            mItemsContainer.setObjectForIndex(spoils[i], i);
        }
    }

    function closeScreen(){
        ::ScreenManager.transitionToScreen(null, null, 1);
        //::ScreenManager.transitionToScreen(null, null, 0);
        ::ScreenManager.queueTransition(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
    }

    function shutdown(){
        _gui.destroy(mWindow_);
        _gui.destroy(mBackgroundWindow_);
    }

    function busCallback(event, data){
        if(event == ExplorationBusEvents.TRIGGER_ITEM){

            if(data.type == FoundObjectType.ITEM){
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, data), null, 3);
            }else{
                //Items like places should not appear here.
                assert(false);
            }

        }
    }
}