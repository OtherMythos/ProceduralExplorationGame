::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationEnemiesContainer <- class{
    mWindow_ = null;
    mPanel_ = null;
    mSizerPanels_ = null;
    mFoundWidgetButtons_ = null;
    mBus_ = null;
    mBackground_ = null;
    mAnimator_ = null;

    mWidth_ = 0;
    mButtonSize_ = 0;

    mNumSlots_ = 4;

    mLayoutLine_ = null;

    constructor(parentWin, bus){
        mAnimator_ = ::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer.ExplorationItemsContainerAnimator(this, mNumSlots_);

        mWidth_ = _window.getWidth() * 0.9;
        mButtonSize_ = mWidth_ / 5;
        mBus_ = bus;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setHidden(true);
        mWindow_.setClickable(false);

        mBackground_ = parentWin.createPanel();
        mBackground_.setSkin("internal/WindowSkin");

        mLayoutLine_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mSizerPanels_ = array(mNumSlots_);
        mFoundWidgetButtons_ = array(mNumSlots_, null);

        //These widgets just leverage the sizer functionality to position the parent buttons.
        for(local i = 0; i < mNumSlots_; i++){
            local panel = mWindow_.createPanel();
            panel.setClickable(false);
            panel.setExpandVertical(true);
            panel.setExpandHorizontal(true);
            panel.setProportionHorizontal(1);
            mLayoutLine_.addCell(panel);
            mSizerPanels_[i] = panel;
        }
        for(local i = 0; i < mNumSlots_; i++){
            local newWidget = ExplorationFoundEnemyWidget(parentWin, i, mBus_);
            mFoundWidgetButtons_[i] = newWidget;
        }
        mLayoutLine_.setMarginForAllCells(10, 10);
    }

    function shutdown(){
        foreach(i in mFoundWidgetButtons_){
            i.shutdown();
        }
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setMargin(20, 20);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(1);
    }

    function getPosition(){
        return mWindow_.getPosition();
    }
    function setPosition(pos){
        mWindow_.setPosition(pos);
    }
    function setSize(width, height){
        mWindow_.setSize(width, height);
    }
    function getSize(){
        return mWindow_.getSize();
    }

    function setObjectForIndex(object, index, screenStart=null){
        assert(index < mFoundWidgetButtons_.len());
        local widget = mFoundWidgetButtons_[index];
        if(object == null){
            widget.deactivate();
            return;
        }
        local sizerButton = mSizerPanels_[index];
        local buttonPos = mWindow_.getPosition() + sizerButton.getCentre();
        local buttonSize = sizerButton.getSize();

        widget.setObject(object);
        widget.setSize(buttonSize);
        widget.setCentre(buttonPos);

        //If null is passed to "start" then the initial animation is not performed.
        mAnimator_.startAnimForItem(::ExplorationGuiAnimation(widget, {"start": screenStart, "end": buttonPos, "endSize": buttonSize}), index);
    }

    function setLifetimeForIndex(index, lifetime){
        assert(index < mFoundWidgetButtons_.len());
        local widget = mFoundWidgetButtons_[index];
        widget.setLifetime(lifetime);
    }

    function update(){
        mAnimator_.update();
    }

    function sizeForButtons(){
        //Actually sizing up the buttons has to be delayed until the window has its size.
        mLayoutLine_.setSize(mWindow_.getSize());
        mLayoutLine_.layout();

        mBackground_.setPosition(mWindow_.getPosition());
        mBackground_.setSize(mWindow_.getSize());

        for(local i = 0; i < mNumSlots_; i++){
            setObjectForIndex(null, i, null);
        }
        setObjectForIndex(Enemy.GOBLIN, 0, null);
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationItemsContainerAnimator.nut");