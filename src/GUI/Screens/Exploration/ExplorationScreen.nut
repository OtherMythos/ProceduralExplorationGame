enum ExplorationBusEvents{
    TRIGGER_ITEM,
    TRIGGER_ENCOUNTER
};

::ScreenManager.Screens[Screen.EXPLORATION_SCREEN] = class extends ::Screen{

    mWorldMapDisplay_ = null;
    mExplorationProgressBar_ = null;
    mLogicInterface_ = null;
    mExplorationItemsContainer_ = null;
    mExplorationEnemiesContainer_ = null;
    mExplorationMovesContainer_ = null;
    mExplorationStatsContainer_ = null;
    mExplorationPlayerActionsContainer_ = null;
    mMoneyCounter_ = null;
    mExplorationBus_ = null;
    mPlaceHelperLabel_ = null;
    mPlaceHelperButton_ = null;
    mCurrentPlace_ = null;
    mScrapAllButton_ = null;
    mWieldActiveButton = null;

    mScreenInputCheckList_ = null;

    mInputBlockerWindow_ = null;

    mInsideGateway_ = false;
    mTooltipManager_ = null;

    mWorldStatsScreen_ = null;

    WorldStatsScreen = class{
        mParent_ = null;
        mWindow_ = null;
        mInfoLabel_ = null;
        constructor(parent){
            mParent_ = parent;

        }
        function setup(){
            mWindow_ = mParent_.createWindow("WorldStatsScreen");
            mWindow_.setSize(100, 100);
            mWindow_.setVisualsEnabled(false);
            mWindow_.setSkinPack("WindowSkinNoBorder");

            mInfoLabel_ = mWindow_.createLabel();

            displayWorldStats(" ");

            _event.subscribe(Event.ACTIVE_WORLD_CHANGE, receiveWorldChange, this);
        }
        function shutdown(){
            _gui.destroy(mWindow_);
            _event.unsubscribe(Event.ACTIVE_WORLD_CHANGE, receiveWorldChange, this);
        }
        function displayWorldStats(stats){
            mInfoLabel_.setText(stats != null ? stats : " ");

            local labelSize = mInfoLabel_.getSize();
            mWindow_.setPosition(10, _window.getHeight() - labelSize.y);
            mWindow_.setSize(labelSize);
        }
        function setVisible(vis){
            if(mWindow_ == null){
                setup();
            }
            mWindow_.setVisible(vis);
        }
        function receiveWorldChange(id, data){
            local statsString = data.getStatsString();
            displayWorldStats(statsString);
        }
    };

    function setup(data){
        mLogicInterface_ = data.logic;
        mExplorationBus_ = ScreenBus();

        mLogicInterface_.setGuiObject(this);

        mWindow_ = _gui.createWindow("ExplorationScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);

        local mobileInterface = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        mExplorationStatsContainer_ = ExplorationStatsContainer(mWindow_, mExplorationBus_);
        if(mobileInterface){
            mExplorationStatsContainer_.addToLayout(layoutLine);
        }else{
            mExplorationStatsContainer_.setPosition(Vec2(0, 110));
            mExplorationStatsContainer_.setSize(400, 140);
        }

        //mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_, mExplorationBus_);
        //mExplorationItemsContainer_.addToLayout(layoutLine);

        //mExplorationEnemiesContainer_ = ExplorationEnemiesContainer(mWindow_, mExplorationBus_);
        mExplorationMovesContainer_ = ExplorationMovesContainer(mWindow_, mExplorationBus_);
        if(mobileInterface){
            mExplorationMovesContainer_.addToLayout(layoutLine);
        }else{
            mExplorationMovesContainer_.setPosition(Vec2(0, 0));
            mExplorationMovesContainer_.setSize(400, 100);
        }
        mWorldMapDisplay_.addToLayout(layoutLine);

        mExplorationPlayerActionsContainer_ = ExplorationPlayerActionsContainer(mWindow_, this, mobileInterface);

        local layoutSize = _window.getSize();
        layoutLine.setHardMaxSize(layoutSize);
        layoutLine.setSize(layoutSize);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();

        mWorldMapDisplay_.notifyResize();

        mExplorationStatsContainer_.sizeLayout();
        mExplorationMovesContainer_.sizeForButtons();

        mScreenInputCheckList_ = [
            mExplorationStatsContainer_,
            mExplorationMovesContainer_
        ];

        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            mWieldActiveButton = mWindow_.createButton();
            mWieldActiveButton.setText("Wield");
            mWieldActiveButton.setPosition(_window.getWidth() / 2 - mWieldActiveButton.getSize().x/2, _window.getHeight() - mWieldActiveButton.getSize().y*2);
            mWieldActiveButton.attachListenerForEvent(function(widget, action){
                ::Base.mPlayerStats.toggleWieldActive();
            }, _GUI_ACTION_PRESSED, this);
            mScreenInputCheckList_.append(mWieldActiveButton);
        }

        mExplorationBus_.registerCallback(busCallback, this);

        mTooltipManager_ = TooltipManager();

        createInputBlockerOverlay();

        mWorldStatsScreen_ = WorldStatsScreen(mWindow_);
        checkWorldStatsVisible();

        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            mExplorationStatsContainer_.setVisible(false);
            mExplorationMovesContainer_.setVisible(false);
        }

        _event.subscribe(Event.WORLD_PREPARATION_STATE_CHANGE, receivePreparationStateChange, this);
        ::ScreenManager.transitionToScreen(Screen.WORLD_GENERATION_STATUS_SCREEN, null, 1);

        //TOOD NOTE Workaround! This isn't how the paradigm should fit together
        //Screen shouldn't dictate what the logic does other than let it know of events happening.
        ::Base.mExplorationLogic.resetExploration_();
    }

    function receivePreparationStateChange(id, data){
        if(data.began){
            ::ScreenManager.transitionToScreen(Screen.WORLD_GENERATION_STATUS_SCREEN, null, 1);
        }else{
            assert(data.ended);
            ::ScreenManager.transitionToScreen(null, null, 1);
        }
    }

    function update(){
        mLogicInterface_.tickUpdate();
        mExplorationMovesContainer_.update();
        mExplorationStatsContainer_.update();
        mWorldMapDisplay_.update();

        mTooltipManager_.update();
    }

    function getMoneyCounter(){
        return mExplorationStatsContainer_.getMoneyCounter();
    }
    function getEXPCounter(){
        return mExplorationStatsContainer_.getEXPCounter();
    }
    function getGameplayWindowPosition(){
        return mWorldMapDisplay_.getPosition();
    }

    function createInputBlockerOverlay(){
        mInputBlockerWindow_ = _gui.createWindow("InputBlocker");
        mInputBlockerWindow_.setSize(_window.getWidth(), _window.getHeight());
        mInputBlockerWindow_.setZOrder(41);
        mInputBlockerWindow_.setVisualsEnabled(false);
        mInputBlockerWindow_.setVisible(false);
    }

    function checkWorldStatsVisible(){
        if(::Base.isProfileActive(GameProfile.DISPLAY_WORLD_STATS)){
            mWorldStatsScreen_.setVisible(true);
        }
    }

    function checkIntersect_(x, y, widget){
        local start = widget.getPosition();
        local end = widget.getSize();
        return (x >= start.x && y >= start.y && x < end.x+start.x && y < end.y+start.y);
    }
    function checkPlayerInputPosition(x, y){
        local start = mWorldMapDisplay_.getPosition();
        local end = mWorldMapDisplay_.getSize();
        if(x >= start.x && y >= start.y && x < end.x+start.x && y < end.y+start.y){
            foreach(i in mScreenInputCheckList_){
                if(checkIntersect_(x, y, i)) return null;
            }

            return Vec2((x-start.x) / end.x, (y-start.y) / end.y);
        }
        return null;
    }

    function notifyObjectFound(foundObject, idx, position = null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        //mExplorationItemsContainer_.setObjectForIndex(foundObject, idx, screenPos);
    }

    function notifyHighlightEnemy(enemy){
        if(enemy != null){
            local string = ::Enemies[enemy].getName();
            mTooltipManager_.setTooltip(string);
        }
        mTooltipManager_.setVisible(enemy != null);
    }

    function notifyEnemyEncounter(idx, enemy, position=null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        mExplorationEnemiesContainer_.setObjectForIndex(enemy, idx, screenPos);
    }

    //Block input while a flag movement is in progress, to prevent buttons being pressed when they shouldn't be.
    function notifyBlockInput(block){
        mInputBlockerWindow_.setVisible(block);
    }

    function notifyFoundItemLifetime(idx, lifetime){
        //mExplorationItemsContainer_.setLifetimeForIndex(idx, lifetime);
    }
    function notifyQueuedEnemyLifetime(idx, lifetime){
        mExplorationEnemiesContainer_.setLifetimeForIndex(idx, lifetime);
    }

    function shutdown(){
        _event.unsubscribe(Event.WORLD_PREPARATION_STATE_CHANGE, receivePreparationStateChange, this);
        mLogicInterface_.shutdown();
        //mLogicInterface_.notifyLeaveExplorationScreen();
        mExplorationStatsContainer_.shutdown();
        mWorldMapDisplay_.shutdown();
        base.shutdown();
    }

    function busCallback(event, data){
        if(event == ExplorationBusEvents.TRIGGER_ITEM){

            if(data.type == FoundObjectType.ITEM){
                if(data.item.getType() == ItemType.MONEY){
                    //Just claim money immediately, no screen switching.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);

                }else{
                    //Switch to the item info screen.
                    //data.mode <- ItemInfoMode.KEEP_SCRAP_EXPLORATION;
                    //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, data));
                    //TODO temp, just scrap the item.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);
                }
                local worldPos = ::EffectManager.getWorldPositionForWindowPos(data.buttonCentre);
                local endPos = mMoneyCounter_.getPositionWindowPos();
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 2, "start": worldPos, "end": endPos, "money": 100}));
            }
            else if(data.type == FoundObjectType.PLACE){
                //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, data));
            }else{
                assert(false);
            }

        }
        else if(event == ExplorationBusEvents.TRIGGER_ENCOUNTER){
            mLogicInterface_.triggerCombatEarly();
        }
    }

    function notifyPlayerMove(moveId){
        return mExplorationMovesContainer_.notifyPlayerMove(moveId);
    }


    function notifyGatewayEnd(explorationStats){
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_END_SCREEN, explorationStats), null, 1);
    }

    function notifyPlayerDeath(){
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLAYER_DEATH_SCREEN, null), null, 1);
        _window.grabCursor(false);
    }

    function notifyPlayerTarget(target){
        _event.transmit(Event.PLAYER_TARGET_CHANGE, target);
    }
};

_doFile("script://ExplorationWorldMapDisplay.nut");
_doFile("script://ExplorationMovesContainer.nut");
_doFile("script://ExplorationEndScreen.nut");
_doFile("script://ExplorationPlayerDeathScreen.nut");
_doFile("script://ExplorationStatsContainer.nut");
_doFile("script://ExplorationTooltipManager.nut");
_doFile("script://ExplorationPlayerActionsContainer.nut");