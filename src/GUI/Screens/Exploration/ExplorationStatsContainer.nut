::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationStatsContainer <- class{
    mWindow_ = null;
    mBus_ = null;
    mLayoutLine_ = null;

    mMoneyCounter_ = null;
    mEXPCounter_ = null;
    mTargetEnemyWidget_ = null;

    mDiffuseSlider_ = null;

    mPlayerHealthBar_ = null;

    constructor(parentWin, bus){
        mBus_ = bus;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setClickable(false);
        //mWindow_.setVisualsEnabled(false);

        mLayoutLine_ = _gui.createLayoutLine();

        mPlayerHealthBar_ = ::GuiWidgets.ProgressBar(mWindow_);
        //mPlayerHealthBar_.setSize(100, 40);
        mPlayerHealthBar_.setPercentage(1.0);
        mPlayerHealthBar_.addToLayout(mLayoutLine_);

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_);
        mMoneyCounter_.addToLayout(mLayoutLine_);
        mEXPCounter_ = ::GuiWidgets.InventoryEXPCounter(mWindow_);
        mEXPCounter_.addToLayout(mLayoutLine_);

        mTargetEnemyWidget_ = ::GuiWidgets.TargetEnemyWidget(mWindow_);
        mTargetEnemyWidget_.addToLayout(mLayoutLine_);

        //mLayoutLine_.setMarginForAllCells(10, 10);
        //mLayoutLine_.layout();

        //TODO this is to get the layout to work but is a bit gross.
        //local healthSize = mPlayerHealthBar_.getPosition();
        //mPlayerHealthBar_.setPosition(healthSize.x, healthSize.y);

        mDiffuseSlider_ = this.mWindow_.createSlider();
        mDiffuseSlider_.setSize(200, 50);
        mDiffuseSlider_.setPosition(0, 100);
        mDiffuseSlider_.setZOrder(110);
        mDiffuseSlider_.setRange(0, 10);
        mDiffuseSlider_.attachListener(sliderCallback);

        _event.subscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
    }

    function sliderCallback(widget, action){
        //::setSliderValue(widget, widget.getValue());
        local datablock = _hlms.getDatablock("baseVoxelMaterial");
        datablock.setUserValue(0, widget.getValue().tofloat() / 10.0, 0, 0, 0);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setMargin(20, 20);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(1);
    }

    function setPosition(pos){
        mWindow_.setPosition(pos);
    }
    function getPosition(){
        return mWindow_.getPosition();
    }
    function setSize(width, height){
        mWindow_.setSize(width, height);
    }
    function getSize(){
        return mWindow_.getSize();
    }

    function update(){
        mMoneyCounter_.update();
        mEXPCounter_.update();
    }

    function sizeForButtons(){
        mLayoutLine_.setSize(mWindow_.getSize());
        mLayoutLine_.layout();

        mPlayerHealthBar_.setSize(mWindow_.getSizeAfterClipping().x, 50);
    }

    function playerHealthChanged(id, data){
        mPlayerHealthBar_.setPercentage(data.percentage);
    }

    function getMoneyCounter(){
        return mMoneyCounter_;
    }
    function getEXPCounter(){
        return mEXPCounter_;
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationItemsContainerAnimator.nut");