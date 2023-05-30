::ScreenManager.Screens[Screen.COMBAT_SPOILS_POPUP_SCREEN] = class extends ::Screen{

    mItemsContainer_ = null;
    mBus_ = null;

    function setup(data){
        local winWidth = _window.getWidth() * 0.9;
        mBus_ = ScreenBus();

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();

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

        mItemsContainer_ = ::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer(mWindow_, mBus_);
        mItemsContainer_.addToLayout(layoutLine);

        local buttonNames = ["Scrap All", "Finish"];
        local buttonFunctions = [
            function(widget, action){
                print("Scrapping");
                ::Base.mCombatLogic.scrapAllSpoils();
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

        layoutLine.setSize(mWindow_.getSizeAfterClipping());
        layoutLine.setHardMaxSize(mWindow_.getSizeAfterClipping());
        layoutLine.layout();
        mItemsContainer_.sizeForButtons();

        local combatData = data.logic.mData_;
        local spoils = combatData.mCombatSpoils;
        setObjectsForData(spoils);

        mBus_.registerCallback(busCallback, this);
        _event.subscribe(Event.COMBAT_SPOILS_CHANGE, receiveSpoilsChange, this);
    }

    function setObjectsForData(data){
        local populated = false;

        for(local i = 0; i < data.len(); i++){
            local obj = data[i];
            if(obj == null){
                obj = ::FoundObject();
            }else{
                populated = true;
            }
            mItemsContainer_.setObjectForIndex(obj, i);
        }

        if(!populated){
            closeScreen();
        }
    }

    function closeScreen(){
        ::ScreenManager.queueTransition(null, null, mLayerIdx);
        ::ScreenManager.queueTransition(Screen.MAIN_MENU_SCREEN);
    }

    function shutdown(){
        mItemsContainer_.shutdown();
        _gui.destroy(mWindow_);
        _gui.destroy(mBackgroundWindow_);
        _event.unsubscribe(Event.COMBAT_SPOILS_CHANGE, receiveSpoilsChange, this);
    }

    function busCallback(event, data){
        if(event == ExplorationBusEvents.TRIGGER_ITEM){

            if(data.type == FoundObjectType.ITEM){
                data.mode <- ItemInfoMode.KEEP_SCRAP_SPOILS;
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, data), null, 3);
            }else{
                //Items like places should not appear here.
                assert(false);
            }

        }
    }

    function receiveSpoilsChange(id, data){
        if(id == Event.COMBAT_SPOILS_CHANGE){
            setObjectsForData(data);
        }
    }
}