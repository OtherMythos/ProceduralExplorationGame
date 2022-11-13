::ExplorationScreen <- class extends ::Screen{

    mWorldMapDisplay_ = null;
    mExplorationProgressBar_ = null;
    mLogicInterface_ = null;
    mExplorationItemsContainer_ = null;

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
            local cellId = layoutLine.addCell(mWindow_);
            layoutLine.setCellExpandHorizontal(cellId, true);
            layoutLine.setCellExpandVertical(cellId, true);
            layoutLine.setCellProportionVertical(cellId, 2);
        }
    };

    ExplorationProgressBar = class{
        mWindow_ = null;
        mPanel_ = null;

        mWidth_ = 0;
        mHeight_ = 60;
        mPadding_ = 8;

        constructor(parentWin){
            mWidth_ = _window.getWidth() * 0.9;

            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setSize(mWidth_, mHeight_);
            mWindow_.setClipBorders(0, 0, 0, 0);

            mPanel_ = mWindow_.createPanel();
            mPanel_.setSize(100, 100);
            mPanel_.setPosition(mPadding_, mPadding_);
            mPanel_.setDatablock("gui/explorationProgressBar");

            setPercentage(0);
        }

        function setPercentage(percentage){
            //*2 for both sides.
            local actualWidth = mWidth_ - mPadding_ * 2;
            mPanel_.setSize(actualWidth * (percentage.tofloat() / 100.0), mHeight_ - mPadding_ * 2);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
        }
    };

    ExplorationItemsContainer = class{
        mWindow_ = null;
        mPanel_ = null;
        mButtons_ = null;

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
            for(local i = 0; i < mNumSlots_; i++){
                local button = mWindow_.createButton();
                button.setText("Empty");
                button.setHidden(true);
                local cellId = mLayoutLine_.addCell(button);
                mLayoutLine_.setCellExpandHorizontal(cellId, true);
                mLayoutLine_.setCellExpandVertical(cellId, true);
                mLayoutLine_.setCellProportionHorizontal(cellId, 1);
                mButtons_[i] = button;
            }
            mLayoutLine_.setMarginForAllCells(10, 10);
        }

        function addToLayout(layoutLine){
            local cellId = layoutLine.addCell(mWindow_);
            layoutLine.setCellExpandHorizontal(cellId, true);
            layoutLine.setCellExpandVertical(cellId, true);
            layoutLine.setCellProportionVertical(cellId, 1);
        }

        function setItemForIndex(item, index){
            assert(index < mButtons_.len());
            local button = mButtons_[index];
            if(item == Item.NONE){
                button.setHidden(true);
                return;
            }
            button.setText(::ItemToName(item), false);
            button.setHidden(false);
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

        local resetButton = mWindow_.createButton();
        resetButton.setText("Restart exploration");
        resetButton.setPosition(5, 5);
        resetButton.attachListenerForEvent(function(widget, action){
            mLogicInterface_.resetExploration();
        }, _GUI_ACTION_PRESSED, this);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Exploring", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);
        mWorldMapDisplay_.addToLayout(layoutLine);

        mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_);
        mExplorationItemsContainer_.addToLayout(layoutLine);

        mExplorationProgressBar_ = ExplorationProgressBar(mWindow_);
        mExplorationProgressBar_.addToLayout(layoutLine);

        layoutLine.setHardMaxSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight() * 0.9);
        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();

        mExplorationItemsContainer_.sizeForButtons();

        mLogicInterface_.resetExploration();
    }

    function update(){
        mLogicInterface_.tickUpdate();
    }

    function notifyExplorationPercentage(percentage){
        mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyItemFound(item, idx){
        mExplorationItemsContainer_.setItemForIndex(item, idx);
    }

    function notifyEnemyEncounter(enemy){
        ::ScreenManager.transitionToScreen(EncounterPopupScreen(), null, 2);
    }
};