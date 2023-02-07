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

    function setup(data){
        mLogicInterface_ = data.logic;
        mExplorationBus_ = ScreenBus();

        mLogicInterface_.setGuiObject(this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        {
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

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Exploring", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        mMoneyCounter_.addToLayout(layoutLine);

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);
        mWorldMapDisplay_.addToLayout(layoutLine);

        mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_, mExplorationBus_);
        mExplorationItemsContainer_.addToLayout(layoutLine);

        mExplorationProgressBar_ = ExplorationProgressBar(mWindow_, this);
        mExplorationProgressBar_.addToLayout(layoutLine);

        layoutLine.setHardMaxSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        mMoneyCounter_.mMoneyLabel_.setMargin(0, 0);
        mMoneyCounter_.mMoneyLabel_.setGridLocation(_GRID_LOCATION_TOP_LEFT);
        layoutLine.layout();

        mExplorationItemsContainer_.sizeForButtons();
        mWorldMapDisplay_.notifyResize();

        mLogicInterface_.continueOrResetExploration();

        mExplorationBus_.registerCallback(busCallback, this);
        mLogicInterface_.setup();
    }

    function update(){
        mLogicInterface_.tickUpdate();
        mExplorationItemsContainer_.update();
        mMoneyCounter_.update();
    }

    function notifyExplorationPercentage(percentage){
        mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyObjectFound(foundObject, idx, position = null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        mExplorationItemsContainer_.setObjectForIndex(foundObject, idx, screenPos);
    }

    function notifyEnemyEncounter(enemy){
        ::ScreenManager.transitionToScreen(Screen.ENCOUNTER_POPUP_SCREEN, null, 3);
    }

    function notifyExplorationEnd(){
        mExplorationProgressBar_.showButtons(true);
    }

    function notifyExplorationBegan(){
        mExplorationProgressBar_.showButtons(false);
    }

    function shutdown(){
        mLogicInterface_.shutdown();
        mMoneyCounter_.shutdown();
        base.shutdown();
        mLogicInterface_.notifyLeaveExplorationScreen();
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
                    data.mode <- ItemInfoMode.KEEP_SCRAP_EXPLORATION;
                    ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, data));
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