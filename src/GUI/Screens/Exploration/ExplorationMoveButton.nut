
::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationMovesContainer.ExplorationMoveButton <- class{

    mParent_ = null;
    mBus_ = null;
    mButton_ = null;
    mMoveCover_ = null;
    mSize_ = null;

    mTotalCooldown_ = 100;
    mMoveCooldown_ = 0;
    mTargetMoveId_ = MoveId.NONE;

    constructor(parentWin, buttonId, bus){
        mParent_ = parentWin;
        mBus_ = bus;
        mSize_ = Vec2(10, 10);
        mTargetMoveId_ = ::Base.mExplorationLogic.mPlayerMoves[buttonId];

        local button = parentWin.createButton();
        button.setText(::Moves[mTargetMoveId_].getName());
        button.setHidden(false);
        button.setUserId(buttonId);
        button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
        //button.setKeyboardNavigable(false);
        mButton_ = button;

        mMoveCover_ = parentWin.createPanel();
        mMoveCover_.setClickable(false);
        mMoveCover_.setSkin("internal/WindowSkin");
    }

    function buttonPressed(widget, action){
        ::Base.mExplorationLogic.triggerPlayerMove(widget.getUserId());
    }

    function notifyMovePerformed(){
        if(mMoveCooldown_ > 0) return false;
        mTotalCooldown_ = ::Moves[mTargetMoveId_].getCooldown();
        mMoveCooldown_ = mTotalCooldown_;
        mButton_.setDisabled(true);

        return true;
    }

    function setPosition(pos){
        mButton_.setPosition(pos);
        mMoveCover_.setPosition(pos);
    }
    function setSize(size){
        mSize_ = size;
        mButton_.setSize(size);
        updateMoveCover();
    }

    function update(){
        if(mMoveCooldown_ > 0){
            mMoveCooldown_--;
            updateMoveCover();
        }
    }

    function updateMoveCover(){
        local newPercent = mMoveCooldown_.tofloat() / mTotalCooldown_.tofloat()
        local newSize = Vec2(mSize_.x, mSize_.y * newPercent);
        mMoveCover_.setSize(newSize);
        mMoveCover_.setHidden(newPercent <= 0);
        mButton_.setDisabled(newPercent > 0);
    }


};