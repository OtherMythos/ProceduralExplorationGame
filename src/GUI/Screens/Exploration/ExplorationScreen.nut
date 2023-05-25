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
    mMoneyCounter_ = null;
    mExplorationBus_ = null;
    mPlaceHelperLabel_ = null;
    mPlaceHelperButton_ = null;
    mCurrentPlace_ = null;
    mScrapAllButton_ = null;
    mCameraButton_ = null;

    mInsideGateway_ = false;
    mTooltipManager_ = null;

    function setup(data){
        mLogicInterface_ = data.logic;
        mExplorationBus_ = ScreenBus();

        mLogicInterface_.setGuiObject(this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        //mMoneyCounter_.addToLayout(layoutLine);

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);

        mExplorationStatsContainer_ = ExplorationStatsContainer(mWindow_, mExplorationBus_);
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            mExplorationStatsContainer_.addToLayout(layoutLine);
        }else{
            mExplorationStatsContainer_.setPosition(Vec2(0, 110));
            mExplorationStatsContainer_.setSize(400, 100);
        }

        //mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_, mExplorationBus_);
        //mExplorationItemsContainer_.addToLayout(layoutLine);

        //mExplorationEnemiesContainer_ = ExplorationEnemiesContainer(mWindow_, mExplorationBus_);
        mExplorationMovesContainer_ = ExplorationMovesContainer(mWindow_, mExplorationBus_);
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            mExplorationMovesContainer_.addToLayout(layoutLine);
        }else{
            mExplorationMovesContainer_.setPosition(Vec2(0, 0));
            mExplorationMovesContainer_.setSize(400, 100);
        }
        mWorldMapDisplay_.addToLayout(layoutLine);

        //mExplorationProgressBar_ = ExplorationProgressBar(mWindow_, this);
        //mExplorationProgressBar_.addToLayout(layoutLine);

        local layoutSize = _window.getSize();
        layoutLine.setHardMaxSize(layoutSize);
        layoutLine.setSize(layoutSize);
        //layoutLine.setMarginForAllCells(0, 20);
        //layoutLine.setPosition(_window.getWidth() * 0.05, 0);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        mMoneyCounter_.mMoneyLabel_.setMargin(0, 0);
        mMoneyCounter_.mMoneyLabel_.setGridLocation(_GRID_LOCATION_TOP_LEFT);
        layoutLine.layout();

        //local targetSize = mExplorationItemsContainer_.getSize();
        //mExplorationItemsContainer_.setSize(targetSize.x, targetSize.y/2);
        //mExplorationItemsContainer_.sizeForButtons();
        mWorldMapDisplay_.notifyResize();

        //mExplorationEnemiesContainer_.setSize(targetSize.x, targetSize.y/2);
        //mExplorationEnemiesContainer_.setPosition(Vec2(mExplorationItemsContainer_.getPosition().x, 5 + mExplorationItemsContainer_.getPosition().y + mExplorationItemsContainer_.getSize().y));
        //mExplorationEnemiesContainer_.sizeForButtons();

        //mExplorationMovesContainer_.setSize(targetSize.x, targetSize.y/2);
        //mExplorationMovesContainer_.setPosition(Vec2(mExplorationItemsContainer_.getPosition().x, 5 + mExplorationItemsContainer_.getPosition().y + mExplorationItemsContainer_.getSize().y));
        //mExplorationMovesContainer_.setPosition(Vec2(0, 100));
        mExplorationStatsContainer_.sizeForButtons();
        mExplorationMovesContainer_.sizeForButtons();


        mPlaceHelperLabel_ = mWindow_.createLabel();
        mPlaceHelperLabel_.setPosition(0, 0);
        mPlaceHelperLabel_.setText(" ");
        mPlaceHelperButton_ = mWindow_.createButton();
        mPlaceHelperButton_.setText("Visit");
        mPlaceHelperButton_.setPosition(0, 40);
        mPlaceHelperButton_.setHidden(true);
        mPlaceHelperButton_.attachListenerForEvent(notifyPlaceVisitButton, _GUI_ACTION_PRESSED);


        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            mCameraButton_ = mWindow_.createButton();
            mCameraButton_.setText("Camera");
            mCameraButton_.setPosition(_window.getWidth() / 2 - mCameraButton_.getSize().x/2, _window.getHeight() - mCameraButton_.getSize().y*2);
            mCameraButton_.attachListenerForEvent(function(widget, action){
                mLogicInterface_.setOrientatingCamera(true);
            }, _GUI_ACTION_PRESSED, this);
        }

        /*
        mScrapAllButton_ = mWindow_.createButton();
        mScrapAllButton_.setText("Scrap all");
        mScrapAllButton_.setPosition(0, mExplorationItemsContainer_.getPosition().y - mScrapAllButton_.getSize().y);
        mScrapAllButton_.attachListenerForEvent(function(widget, action){
            //mLogicInterface_.scrapAllFoundObjects();
            scrapAllObjects();
        }, _GUI_ACTION_PRESSED, this);
        */

        mLogicInterface_.continueOrResetExploration();

        mExplorationBus_.registerCallback(busCallback, this);
        mLogicInterface_.setup();

        mTooltipManager_ = TooltipManager();

    }

    function update(){
        mLogicInterface_.tickUpdate();
        //mExplorationItemsContainer_.update();
        //mExplorationEnemiesContainer_.update();
        mExplorationMovesContainer_.update();
        mMoneyCounter_.update();
        mWorldMapDisplay_.update();

        mTooltipManager_.update();
    }


    function checkPlayerInputPosition(x, y){
        local start = mWorldMapDisplay_.getPosition();
        local end = mWorldMapDisplay_.getSize();
        if(x >= start.x && y >= start.y && x < end.x+start.x && y < end.y+start.y){
            return Vec2((x-start.x) / end.x, (y-start.y) / end.y);
        }
        return null;
    }

    function notifyExplorationPercentage(percentage){
        //mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyObjectFound(foundObject, idx, position = null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        //mExplorationItemsContainer_.setObjectForIndex(foundObject, idx, screenPos);
    }

    function notifyEnemyCombatBegan(combatData, position){
        local screenPos = ::EffectManager.getWorldPositionForWindowPos(mWorldMapDisplay_.getWorldPositionInScreenSpace(position));
        local endPos = ::EffectManager.getWorldPositionForWindowPos(Vec2(_window.getWidth() / 2, _window.getHeight() / 2));

        local data = {"combatData": combatData, "start": screenPos, "end": endPos};
        ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.ENCOUNTER, data));
    }

    function notifyExplorationEnd(){
        //mExplorationProgressBar_.showButtons(true);
    }

    function notifyExplorationBegan(){
        //mExplorationProgressBar_.showButtons(false);
    }

    function notifyNewMapData(data){
        mWorldMapDisplay_.notifyNewMapData(data);
    }

    function notifyFoundItemRemoved(idx){
        //mExplorationItemsContainer_.setObjectForIndex(FoundObject(), idx, null);
    }
    function notifyQueuedEnemyRemoved(idx){
        //mExplorationEnemiesContainer_.setObjectForIndex(null, idx, null);
    }

    function notifyHighlightEnemy(enemy){
        if(enemy != null){
            local string = ::ItemHelper.enemyToName(enemy);
            mTooltipManager_.setTooltip(string);
        }
        mTooltipManager_.setVisible(enemy != null);
    }

    function notifyGatewayStatsChange(gatewayPercentage){
        print("Current gateway " + gatewayPercentage);
    }

    function notifyPlaceVisitButton(widget, action){
        local data = {
            "place": mCurrentPlace_,
            "slotIdx": -1
        };
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, data));
    }
    function notifyPlaceGatewayButton(widget, action){
        ::Base.mExplorationLogic.gatewayEndExploration();
    }

    function notifyPlaceEnterState(id, entered, firstTime, placeEnteredPos){
        if(firstTime){
            mWorldMapDisplay_.mMapViewer_.notifyNewPlaceFound(id, placeEnteredPos);
        }
        if(id == PlaceId.GATEWAY){
            mInsideGateway_ = entered;
            local text = "";
            local gatewayReady = mLogicInterface_.isGatewayReady();
            if(entered){
                text = gatewayReady ? "Gateway is ready" : "Gateway is not ready yet"
            }
            mPlaceHelperLabel_.setText(text);
            mPlaceHelperButton_.setText("End exploration");
            mPlaceHelperButton_.setHidden(!entered || !gatewayReady);
            mPlaceHelperButton_.attachListenerForEvent(notifyPlaceGatewayButton, _GUI_ACTION_PRESSED);
            return;
        }
        //Make sure if the player has entered the gateway box that overrides everything else.
        if(mInsideGateway_) return;

        local text = "";
        if(entered){
            text = ::Places[id].getName();
        }
        mPlaceHelperLabel_.setText(text);
        mPlaceHelperButton_.setText("Visit");
        mPlaceHelperButton_.setHidden(!entered);
        mPlaceHelperButton_.attachListenerForEvent(notifyPlaceVisitButton, _GUI_ACTION_PRESSED);
        mCurrentPlace_ = entered ? id : null;
    }

    function notifyEnemyEncounter(idx, enemy, position=null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        mExplorationEnemiesContainer_.setObjectForIndex(enemy, idx, screenPos);
    }

    function notifyFoundItemLifetime(idx, lifetime){
        //mExplorationItemsContainer_.setLifetimeForIndex(idx, lifetime);
    }
    function notifyQueuedEnemyLifetime(idx, lifetime){
        mExplorationEnemiesContainer_.setLifetimeForIndex(idx, lifetime);
    }

    function shutdown(){
        mLogicInterface_.shutdown();
        mMoneyCounter_.shutdown();
        base.shutdown();
        mLogicInterface_.notifyLeaveExplorationScreen();
        mExplorationItemsContainer_.shutdown();
        mExplorationEnemiesContainer_.shutdown();
        mWorldMapDisplay_.shutdown();
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
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, data));
            }else{
                assert(false);
            }

        }
        else if(event == ExplorationBusEvents.TRIGGER_ENCOUNTER){
            mLogicInterface_.triggerCombatEarly();
        }
    }

    function scrapAllObjects(){
        /*
        for(local i = 0; i < mExplorationItemsContainer_.mNumSlots_; i++){
            if(mLogicInterface_.mFoundObjects_[i] == null) continue;
            local targetButton = mExplorationItemsContainer_.mFoundWidgetButtons_[i];
            local worldPos = ::EffectManager.getWorldPositionForWindowPos(targetButton.mPosition_);
            local endPos = mMoneyCounter_.getPositionWindowPos();
            ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 2, "start": worldPos, "end": endPos, "money": 100}));
        }

        mLogicInterface_.scrapAllFoundObjects();
        */
    }

    function notifyPlayerMove(moveId){
        return mExplorationMovesContainer_.notifyPlayerMove(moveId);
    }


    function notifyGatewayEnd(explorationStats){
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_END_SCREEN, explorationStats), null, 1);
    }

    function notifyPlayerDeath(){
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLAYER_DEATH_SCREEN, null), null, 1);
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationItemsContainer.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationEnemiesContainer.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationProgressBar.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationWorldMapDisplay.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationFoundItemWidget.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationFoundEnemyWidget.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationMovesContainer.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationEndScreen.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationPlayerDeathScreen.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationStatsContainer.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationTooltipManager.nut");