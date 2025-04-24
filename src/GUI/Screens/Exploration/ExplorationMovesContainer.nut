::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationMovesContainer <- class{
    mWindow_ = null;
    mPanel_ = null;
    mSizerPanels_ = null;
    mBus_ = null;
    mBackground_ = null;
    mAnimator_ = null;
    mMoveButtons_ = null;

    mWidth_ = 0;
    mButtonSize_ = 0;

    mNumSlots_ = 4;

    mLayoutLine_ = null;

    constructor(parentWin, bus){
        mWidth_ = _window.getWidth() * 0.9;
        mButtonSize_ = mWidth_ / 5;
        mBus_ = bus;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow("ExplorationMovesContainer", parentWin);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setHidden(true);
        mWindow_.setClickable(false);

        mBackground_ = parentWin.createPanel();
        mBackground_.setSkin("internal/WindowSkin");
        mBackground_.setZOrder(80);

        mLayoutLine_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mSizerPanels_ = array(mNumSlots_);
        mMoveButtons_ = array(mNumSlots_);

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
            local moveButton = ExplorationMoveButton(parentWin, i, bus);
            mMoveButtons_[i] = moveButton;
        }
        mLayoutLine_.setMarginForAllCells(10, 10);
    }

    function shutdown(){
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setMargin(10, 0);
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
        foreach(i in mMoveButtons_){
            i.update();
        }
    }

    function notifyPlayerMove(moveId){
        assert(moveId >= 0 && moveId < mMoveButtons_.len());
        return mMoveButtons_[moveId].notifyMovePerformed();
    }

    function sizeForButtons(){
        //Actually sizing up the buttons has to be delayed until the window has its size.
        mLayoutLine_.setSize(mWindow_.getSize());
        mLayoutLine_.layout();

        mBackground_.setPosition(mWindow_.getPosition());
        mBackground_.setSize(mWindow_.getSize());

        for(local i = 0; i < mNumSlots_; i++){
            mMoveButtons_[i].setPosition(mSizerPanels_[i].getDerivedPosition());
            mMoveButtons_[i].setSize(mSizerPanels_[i].getSize());
        }
    }

    function setVisible(visible){
        mBackground_.setVisible(visible);
        foreach(i in mMoveButtons_){
            i.setVisible(visible);
        }
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationMoveButton.nut");