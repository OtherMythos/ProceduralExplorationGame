::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationStatsContainer <- class{
    mWindow_ = null;
    mBus_ = null;
    mLayoutLine_ = null;
    mHorizontalLayoutLine_ = null;

    mMoneyCounter_ = null;
    mEXPCounter_ = null;
    mTargetEnemyWidget_ = null;
    mInventoryButton_ = null;
    mInventoryCounter_ = null;
    mPauseButton_ = null;
    mWieldPutAway_ = null;

    mPlayerHealthBar_ = null;

    constructor(parentWin, bus){
        mBus_ = bus;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow("ExplorationScreen", parentWin);
        mWindow_.setClickable(false);
        //Shrink to the correct size later on.
        //if(::Base.getTargetInterface() != TargetInterface.MOBILE){
            mWindow_.setSize(400, 100);
        //}
        //mWindow_.setVisualsEnabled(false);

        mLayoutLine_ = _gui.createLayoutLine();

        local buttonLayout = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mInventoryButton_ = mWindow_.createButton();
        mInventoryButton_.setText("Inventory");
        mInventoryButton_.setShadowOutline(true, ColourValue(0.3, 0.3, 0.3), Vec2(2, 2));
        //mInventoryButton_.setExpandVertical(true);
        mInventoryButton_.setExpandHorizontal(true);
        mInventoryButton_.attachListenerForEvent(function(widget, action){
            ::Base.mExplorationLogic.mCurrentWorld_.showInventory();
        }, _GUI_ACTION_PRESSED, this);

        mInventoryCounter_ = mWindow_.createLabel();
        {
            local inv = ::Base.mPlayerStats.mInventory_;
            local free = inv.getNumSlotsFree();
            local fullSize = inv.getInventorySize();
            setInventoryCount_(fullSize - free, fullSize);
        }
        mInventoryCounter_.setShadowOutline(true, ColourValue(0.3, 0.3, 0.3), Vec2(2, 2));

        mPauseButton_ = mWindow_.createButton();
        mPauseButton_.setText("Pause");
        //mPauseButton_.setExpandVertical(true);
        mPauseButton_.setExpandHorizontal(true);
        mPauseButton_.setShadowOutline(true, ColourValue(0.3, 0.3, 0.3), Vec2(2, 2));
        mPauseButton_.setMargin(10, 0);
        mPauseButton_.attachListenerForEvent(function(widget, action){
            ::Base.mExplorationLogic.setGamePaused(true);
        }, _GUI_ACTION_PRESSED, this);

        buttonLayout.addCell(mPauseButton_);
        buttonLayout.addCell(mInventoryButton_);

        buttonLayout.setSize(mWindow_.getSize());
        //buttonLayout.setMarginForAllCells(10, 10);
        buttonLayout.layout();

        //mLayoutLine_.addCell(buttonLayout);


        ::evenOutButtonsForHeight([
            mInventoryButton_,
            mPauseButton_
        ]);

        mPlayerHealthBar_ = ::GuiWidgets.ProgressBar(mWindow_);
        //mPlayerHealthBar_.setSize(100, 40);
        mPlayerHealthBar_.setPercentage(1.0);
        mPlayerHealthBar_.addToLayout(mLayoutLine_);

        //local mobileInterface = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        local mobileInterface = true;
        local targetLayout = mLayoutLine_;
        /*
        if(mobileInterface){
            mHorizontalLayoutLine_ = _gui.createLayoutLine(_LAYOUT_VERTICAL);
            targetLayout = mHorizontalLayoutLine_;
        }
        */


        /*
        if(::Base.getTargetInterface() != TargetInterface.MOBILE){
            mWieldPutAway_ = mWindow_.createButton();
            mWieldPutAway_.setText("Wield");
            mWieldPutAway_.setExpandVertical(true);
            mWieldPutAway_.setExpandHorizontal(true);
            targetLayout.addCell(mWieldPutAway_);
            mWieldPutAway_.attachListenerForEvent(function(widget, action){
                ::Base.mPlayerStats.toggleWieldActive();
            }, _GUI_ACTION_PRESSED, this);
        }
        */

        mMoneyCounter_ = ::GuiWidgets.InventoryMoneyCounter(mWindow_, this);
        mMoneyCounter_.addToLayout(targetLayout);
        mEXPCounter_ = ::GuiWidgets.InventoryEXPCounter(mWindow_, this);
        mEXPCounter_.addToLayout(targetLayout);

        mTargetEnemyWidget_ = ::GuiWidgets.TargetEnemyWidget(mWindow_);
        mTargetEnemyWidget_.addToLayout(targetLayout);

        if(mobileInterface){
            //mLayoutLine_.addCell(targetLayout);
            targetLayout.setMarginForAllCells(10, 10);
        }

        mLayoutLine_.setMarginForAllCells(10, 10);
        mPlayerHealthBar_.mParentContainer_.setMargin(0, 0);

        //mLayoutLine_.layout();

        //TODO this is to get the layout to work but is a bit gross.
        //local healthSize = mPlayerHealthBar_.getPosition();
        //mPlayerHealthBar_.setPosition(healthSize.x, healthSize.y);

        _event.subscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
        _event.subscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
        mTargetEnemyWidget_.shutdown();
    }

    function addToLayout(layout){
        layout.addCell(mWindow_);
        mWindow_.setMargin(10, 10);
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

    function sizeLayout(minimapSize){
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            mWindow_.setSize(_window.getWidth() - minimapSize.x, mWindow_.calculateChildrenSize().y * 2);
        }
        mWindow_.setVisualsEnabled(false);

        mPlayerHealthBar_.setMinSize(Vec2(mWindow_.getSizeAfterClipping().x, 50));
        mLayoutLine_.setSize(mWindow_.getSize());
        //mHorizontalLayoutLine_.setSize(mWindow_.getSize());
        if(mHorizontalLayoutLine_){
            mHorizontalLayoutLine_.setSize(mWindow_.getSize());
        }
        mLayoutLine_.layout();
        if(mHorizontalLayoutLine_){
            mHorizontalLayoutLine_.layout();
        }

        mPlayerHealthBar_.notifyLayout();

        local healthBarPos = mPauseButton_.getPosition();
        healthBarPos.y += mPauseButton_.getSize().y + 10;
        mPlayerHealthBar_.setPosition(healthBarPos.x, healthBarPos.y);

        local delta = (mPlayerHealthBar_.getPosition().y + mPlayerHealthBar_.getSize().y) - (mMoneyCounter_.getPosition().y) - 5;
        foreach(c,i in [mMoneyCounter_, mEXPCounter_]){
            local newPos = i.getPosition();
            newPos.y += delta;
            print(i);
            print(delta);
            print(newPos);
            i.setPosition(newPos);
        }

        //if(::Base.getTargetInterface() != TargetInterface.MOBILE){
            mWindow_.setSize(mWindow_.calculateChildrenSize());
        //}

        mInventoryCounter_.setPosition(mInventoryButton_.getPosition().x + mInventoryButton_.getSize().x + 5, 5);
    }

    function notifyCounterChanged(){
        //sizeLayout();
    }

    function playerHealthChanged(id, data){
        mPlayerHealthBar_.setPercentage(data.percentage);
    }

    function receiveInventoryChangedEvent(id, data){
        local count = 0;
        foreach(i in data){
            if(i != null) count++;
        }
        setInventoryCount_(count, data.len());
    }

    function setInventoryCount_(count, size){
        mInventoryCounter_.setText(format("%i/%i", count, size));
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
