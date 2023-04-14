enum ExplorationBusEvents{
    TRIGGER_ITEM,
};

::ScreenManager.Screens[Screen.EXPLORATION_SCREEN] = class extends ::Screen{

    mWorldMapDisplay_ = null;
    mExplorationProgressBar_ = null;
    mLogicInterface_ = null;
    mExplorationItemsContainer_ = null;
    mMoneyCounter_ = null;
    mExplorationBus_ = null;
    mPlaceHelperLabel_ = null;
    mPlaceHelperButton_ = null;
    mCurrentPlace_ = null;
    mScrapAllButton_ = null;

    function setup(data){
        mLogicInterface_ = data.logic;
        mExplorationBus_ = ScreenBus();

        mLogicInterface_.setGuiObject(this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        if(false){
            local helperButtonLayout = _gui.createLayoutLine();

            local resetButton = mWindow_.createButton();
            resetButton.setText("Restart exploration");
            resetButton.attachListenerForEvent(function(widget, action){
                mLogicInterface_.resetExploration();
            }, _GUI_ACTION_PRESSED, this);
            helperButtonLayout.addCell(resetButton);

            local inventoryButton = mWindow_.createButton();
            inventoryButton.setText("Inventory");
            inventoryButton.attachListenerForEvent(function(widget, action){
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN, {"inventory": ::Base.mInventory, "equipStats": ::Base.mPlayerStats.mPlayerCombatStats.mEquippedItems}));
            }, _GUI_ACTION_PRESSED, this);
            helperButtonLayout.addCell(inventoryButton);

            local exploreAgain = mWindow_.createButton();
            exploreAgain.setText("Trigger encounter");
            exploreAgain.attachListenerForEvent(function(widget, action){
                mLogicInterface_.processEncounter(Enemy.GOBLIN);
            }, _GUI_ACTION_PRESSED, this);
            helperButtonLayout.addCell(exploreAgain);

            local worldScene = mWindow_.createButton();
            worldScene.setText("World scene");
            worldScene.attachListenerForEvent(function(widget, action){
                ::ScreenManager.transitionToScreen(Screen.WORLD_SCENE_SCREEN);
            }, _GUI_ACTION_PRESSED, this);
            helperButtonLayout.addCell(worldScene);

            helperButtonLayout.setPosition(5, 5);
            helperButtonLayout.layout();
        }

        local layoutLine = _gui.createLayoutLine();

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        //mMoneyCounter_.addToLayout(layoutLine);

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);
        mWorldMapDisplay_.addToLayout(layoutLine);

        mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_, mExplorationBus_);
        mExplorationItemsContainer_.addToLayout(layoutLine);

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

        mExplorationItemsContainer_.sizeForButtons();
        mWorldMapDisplay_.notifyResize();

        mPlaceHelperLabel_ = mWindow_.createLabel();
        mPlaceHelperLabel_.setPosition(0, 0);
        mPlaceHelperLabel_.setText(" ");
        mPlaceHelperButton_ = mWindow_.createButton();
        mPlaceHelperButton_.setText("Visit");
        mPlaceHelperButton_.setPosition(0, 40);
        mPlaceHelperButton_.setHidden(true);
        mPlaceHelperButton_.attachListenerForEvent(function(widget, action){
            local data = {
                "place": mCurrentPlace_,
                "slotIdx": -1
            };
            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, data));
        }, _GUI_ACTION_PRESSED, this);

        mScrapAllButton_ = mWindow_.createButton();
        mScrapAllButton_.setText("Scrap all");
        mScrapAllButton_.setPosition(0, mExplorationItemsContainer_.getPosition().y - mScrapAllButton_.getSize().y);
        mScrapAllButton_.attachListenerForEvent(function(widget, action){
            mLogicInterface_.scrapAllFoundObjects();
        }, _GUI_ACTION_PRESSED, this);

        mLogicInterface_.continueOrResetExploration();

        mExplorationBus_.registerCallback(busCallback, this);
        mLogicInterface_.setup();
    }

    function update(){
        mLogicInterface_.tickUpdate();
        mExplorationItemsContainer_.update();
        mMoneyCounter_.update();
    }


    function checkPlayerInputPosition(x, y){
        local start = mWorldMapDisplay_.getPosition();
        local end = mWorldMapDisplay_.getSize();
        if(x >= start.x && y >= start.y && x < end.x && y < end.y){
            return Vec2(x / end.x, y / end.y);
        }
        return null;
    }

    function notifyExplorationPercentage(percentage){
        //mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyObjectFound(foundObject, idx, position = null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        mExplorationItemsContainer_.setObjectForIndex(foundObject, idx, screenPos);
    }

    function notifyEnemyEncounter(combatData, position){
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
        mExplorationItemsContainer_.setObjectForIndex(FoundObject(), idx, null);
    }

    function notifyPlaceEnterState(id, entered){
        local text = "";
        if(entered){
            text = ::Places[id].getName();
        }
        mPlaceHelperLabel_.setText(text);
        mPlaceHelperButton_.setHidden(!entered);
        mCurrentPlace_ = entered ? id : null;
    }

    function notifyFoundItemLifetime(idx, lifetime){
        mExplorationItemsContainer_.setLifetimeForIndex(idx, lifetime);
    }

    function shutdown(){
        mLogicInterface_.shutdown();
        mMoneyCounter_.shutdown();
        base.shutdown();
        mLogicInterface_.notifyLeaveExplorationScreen();
        mExplorationItemsContainer_.shutdown();
    }

    function busCallback(event, data){
        if(event == ExplorationBusEvents.TRIGGER_ITEM){

            if(data.type == FoundObjectType.ITEM){
                if(data.item.getType() == ItemType.MONEY){
                    //Just claim money immediately, no screen switching.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);

                    local worldPos = ::EffectManager.getWorldPositionForWindowPos(data.buttonCentre);
                    local endPos = mMoneyCounter_.getPosition();
                    ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.COIN_EFFECT, {"numCoins": itemData.money / 8, "start": worldPos, "end": endPos, "money": itemData.money}));
                }else{
                    //Switch to the item info screen.
                    //data.mode <- ItemInfoMode.KEEP_SCRAP_EXPLORATION;
                    //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, data));
                    //TODO temp, just scrap the item.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);
                }
            }
            else if(data.type == FoundObjectType.PLACE){
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, data));
            }else{
                assert(false);
            }

        }
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationItemsContainer.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationProgressBar.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationWorldMapDisplay.nut");
_doFile("res://src/GUI/Screens/Exploration/ExplorationFoundItemWidget.nut");
