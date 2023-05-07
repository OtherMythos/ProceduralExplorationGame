
::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationMovesContainer.ExplorationMoveButton <- class{

    mParent_ = null;
    mBus_ = null;
    mButton_ = null;
    mMoveCover_ = null;
    mSize_ = null;

    static TOTAL_COOLDOWN = 100;
    mMoveCooldown_ = 0;

    constructor(parentWin, buttonId, bus){
        mParent_ = parentWin;
        mBus_ = bus;
        mSize_ = Vec2(10, 10);

        local button = parentWin.createButton();
        button.setText("Move");
        button.setHidden(false);
        button.setUserId(buttonId);
        button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
        mButton_ = button;

        mMoveCover_ = parentWin.createPanel();
        mMoveCover_.setClickable(false);
        mMoveCover_.setSkin("internal/WindowSkin");
    }

    function buttonPressed(widget, action){
        mMoveCooldown_ = TOTAL_COOLDOWN;
        widget.setDisabled(true);

        local explorationLogic = ::Base.mExplorationLogic;
        local playerPos = explorationLogic.mPlayerEntry_.mPos_.copy();
        explorationLogic.mProjectileManager_.spawnProjectile(ProjectileId.AREA, playerPos, Vec3(0, 0, 0));
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
        local newPercent = mMoveCooldown_.tofloat() / TOTAL_COOLDOWN.tofloat()
        local newSize = Vec2(mSize_.x, mSize_.y * newPercent);
        mMoveCover_.setSize(newSize);
        mMoveCover_.setHidden(newPercent <= 0);
        mButton_.setDisabled(newPercent > 0);
    }


};