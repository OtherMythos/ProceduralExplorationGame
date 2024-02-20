::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationStatsContainer <- class{
    mWindow_ = null;
    mBus_ = null;
    mLayoutLine_ = null;

    mMoneyCounter_ = null;
    mEXPCounter_ = null;
    mTargetEnemyWidget_ = null;

    mPlayerHealthBar_ = null;

    constructor(parentWin, bus){
        mBus_ = bus;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow(parentWin);
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

        mLayoutLine_.setMarginForAllCells(10, 10);
        //mLayoutLine_.layout();

        //TODO this is to get the layout to work but is a bit gross.
        //local healthSize = mPlayerHealthBar_.getPosition();
        //mPlayerHealthBar_.setPosition(healthSize.x, healthSize.y);

        _event.subscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
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

    function sizeLayout(){
        mPlayerHealthBar_.setMinSize(Vec2(mWindow_.getSizeAfterClipping().x, 50));
        mLayoutLine_.setSize(mWindow_.getSize());
        mLayoutLine_.layout();

        mPlayerHealthBar_.notifyLayout();
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
    function setVisible(visible){
        mWindow_.setVisible(visible);
    }
};
