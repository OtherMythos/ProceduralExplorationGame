::ExplorationScreen <- class extends ::Screen{

    mWindow_ = null;
    mWorldMapDisplay_ = null;
    mExplorationProgressBar_ = null;
    mLogicInterface_ = null;
    mExplorationItemsContainer_ = null;

    WorldMapDisplay = class{
        mWindow_ = null;

        mHeight_ = 300;

        constructor(parentWin){
            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setSize(_window.getWidth() * 0.9, mHeight_);
            mWindow_.setClipBorders(0, 0, 0, 0);

            local title = mWindow_.createLabel();
            title.setText("Exploration map");
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
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

            local highlightDatablock = _hlms.unlit.createDatablock("progressBar", null, null, {"diffuse": "0.4 1.0 0.4"});

            mPanel_ = mWindow_.createPanel();
            mPanel_.setSize(100, 100);
            mPanel_.setPosition(mPadding_, mPadding_);
            mPanel_.setDatablock(highlightDatablock);

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
        mHeight_ = 240;
        mButtonSize_ = 0;

        mNumSlots_ = 4;

        constructor(parentWin){
            mWidth_ = _window.getWidth() * 0.9;
            mButtonSize_ = mWidth_ / 5;

            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setSize(mWidth_, mHeight_);

            local layoutLine = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
            mButtons_ = array(mNumSlots_);
            for(local i = 0; i < mNumSlots_; i++){
                local button = mWindow_.createButton();
                button.setText("Empty");
                button.setSize(mButtonSize_, mButtonSize_);
                button.setHidden(true);
                layoutLine.addCell(button);
                mButtons_[i] = button;
            }
            layoutLine.setMarginForAllCells(10, 0);
            layoutLine.layout();
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
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
        title.setText("Exploring");
        layoutLine.addCell(title);

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);
        mWorldMapDisplay_.addToLayout(layoutLine);

        mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_);
        mExplorationItemsContainer_.addToLayout(layoutLine);

        mExplorationProgressBar_ = ExplorationProgressBar(mWindow_);
        mExplorationProgressBar_.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();

        mLogicInterface_.resetExploration();
    }

    function update(){
        mLogicInterface_.tickUpdate();
    }

    function shutdown(){
        _gui.destroy(mWindow_);
    }

    function notifyExplorationPercentage(percentage){
        mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyItemFound(item, idx){
        mExplorationItemsContainer_.setItemForIndex(item, idx);
    }
};