::ExplorationScreen <- class extends ::Screen{

    mWorldMapDisplay_ = null;
    mExplorationProgressBar_ = null;
    mLogicInterface_ = null;
    mExplorationItemsContainer_ = null;
    mMoneyCounter_ = null;

    WorldMapDisplay = class{
        mWindow_ = null;

        mHeight_ = 300;

        constructor(parentWin){
            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            local title = mWindow_.createLabel();
            title.setText("Exploration map");
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(2);
        }
    };

    ExplorationProgressBar = class{
        mParentScreen_ = null;
        mWindow_ = null;
        mPanel_ = null;

        mWidth_ = 0;
        mHeight_ = 60;
        mPadding_ = 8;

        mOptionButtons_ = null;

        function exploreAgainButton(widget, action){
            mParentScreen_.mLogicInterface_.resetExploration();
        }

        function mainMenuButton(widget, action){
            ::ScreenManager.transitionToScreen(GameplayMainMenuScreen());
        }

        constructor(parentWin, parentScreen){
            mParentScreen_ = parentScreen;
            mWidth_ = _window.getWidth() * 0.9;

            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setSize(mWidth_, mHeight_);
            mWindow_.setClipBorders(0, 0, 0, 0);

            {
                mPanel_ = mWindow_.createPanel();
                mPanel_.setSize(100, 100);
                mPanel_.setPosition(mPadding_, mPadding_);
                mPanel_.setDatablock("gui/explorationProgressBar");
            }

            { //Create buttons
                local buttonLayout = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
                mOptionButtons_ = [];

                local buttonNames = ["Explore again", "Main Menu"]
                local buttonFunctions = [exploreAgainButton, mainMenuButton];
                foreach(c,i in buttonNames){
                    local button = mWindow_.createButton();
                    button.setText(i);
                    button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
                    button.setHidden(true);
                    buttonLayout.addCell(button);
                    button.setExpandVertical(true);
                    button.setExpandHorizontal(true);
                    button.setProportionHorizontal(1);
                    mOptionButtons_.append(button);
                }

                buttonLayout.setMarginForAllCells(10, 10);
                buttonLayout.setSize(mWindow_.getSize());
                buttonLayout.layout();
            }

            setPercentage(0);
        }

        function setPercentage(percentage){
            //*2 for both sides.
            local actualWidth = mWidth_ - mPadding_ * 2;
            mPanel_.setSize(actualWidth * (percentage.tofloat() / 100.0), mHeight_ - mPadding_ * 2);
        }

        function showButtons(show){
            foreach(i in mOptionButtons_){
                i.setHidden(!show);
            }

            mPanel_.setHidden(show);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
        }
    };

    ExplorationItemsContainer = class{
        mWindow_ = null;
        mPanel_ = null;
        mButtons_ = null;
        mFoundObjects_ = null;

        mWidth_ = 0;
        mButtonSize_ = 0;

        mNumSlots_ = 4;

        mLayoutLine_ = null;

        constructor(parentWin){
            mWidth_ = _window.getWidth() * 0.9;
            mButtonSize_ = mWidth_ / 5;

            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            mLayoutLine_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
            mButtons_ = array(mNumSlots_);
            mFoundObjects_ = array(mNumSlots_, null);

            for(local i = 0; i < mNumSlots_; i++){
                local button = mWindow_.createButton();
                button.setText("Empty");
                button.setHidden(true);
                button.setUserId(i);
                button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
                button.setExpandVertical(true);
                button.setExpandHorizontal(true);
                button.setProportionHorizontal(1);
                mLayoutLine_.addCell(button);
                mButtons_[i] = button;
            }
            mLayoutLine_.setMarginForAllCells(10, 10);
        }

        function buttonPressed(widget, action){
            local id = widget.getUserId();
            local foundObj = mFoundObjects_[id];
            if(foundObj.type == FoundObjectType.ITEM){
                ::ScreenManager.transitionToScreen(ItemInfoScreen(foundObj.obj, id));
            }
            else if(foundObj.type == FoundObjectType.PLACE){
                ::ScreenManager.transitionToScreen(::PlaceInfoScreen(foundObj.obj, id));
            }else{
                assert(false);
            }
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(1);
        }

        function setObjectForIndex(object, index){
            assert(index < mButtons_.len());
            local button = mButtons_[index];
            if(object.isNone()){
                button.setHidden(true);
                return;
            }
            button.setText(object.toName(), false);
            button.setHidden(false);
            mFoundObjects_[index] = object;
        }

        function sizeForButtons(){
            //Actually sizing up the buttons has to be delayed until the window has its size.
            mLayoutLine_.setSize(mWindow_.getSize());
            mLayoutLine_.layout();
        }
    };

    constructor(logicInterface){
        mLogicInterface_ = logicInterface;
        mLogicInterface_.setGuiObject(this);
    }

    function setup(){
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
                ::ScreenManager.transitionToScreen(InventoryScreen(::Base.mInventory));
            }, _GUI_ACTION_PRESSED, this);
            helperButtonLayout.addCell(inventoryButton);

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

        mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_);
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

        mLogicInterface_.continueOrResetExploration();
    }

    function update(){
        mLogicInterface_.tickUpdate();
    }

    function notifyExplorationPercentage(percentage){
        mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyObjectFound(foundObject, idx){
        mExplorationItemsContainer_.setObjectForIndex(foundObject, idx);
    }

    function notifyEnemyEncounter(enemy){
        ::ScreenManager.transitionToScreen(EncounterPopupScreen(), null, 2);
    }

    function notifyExplorationEnd(){
        mExplorationProgressBar_.showButtons(true);
    }

    function notifyExplorationBegan(){
        mExplorationProgressBar_.showButtons(false);
    }

    function shutdown(){
        mMoneyCounter_.shutdown();
        base.shutdown();
        mLogicInterface_.notifyLeaveExplorationScreen();
    }
};