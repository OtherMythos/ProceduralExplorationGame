::GuiWidgets.TargetEnemyWidget <- class{

    mLabel_ = null;
    mCancelButton_ = null;
    mHorizLayout_ = null;

    constructor(parent){
        local horizLayout = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);

        mLabel_ = parent.createLabel();
        mLabel_.setText(" ");
        horizLayout.addCell(mLabel_);

        mCancelButton_ = parent.createButton();
        mCancelButton_.setText("Cancel");
        mCancelButton_.attachListenerForEvent(cancelButtonPressed, _GUI_ACTION_PRESSED);
        horizLayout.addCell(mCancelButton_);

        mHorizLayout_ = horizLayout;
        _event.subscribe(Event.PLAYER_TARGET_CHANGE, playerTargetChanged, this);

        setTargetEnemy(null);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLAYER_TARGET_CHANGE, playerTargetChanged, this);
    }

    function cancelButtonPressed(widget, action){
        ::Base.mExplorationLogic.mCurrentWorld_.setTargetEnemy(null);
    }

    function playerTargetChanged(id, data){
        setTargetEnemy(data);
    }

    function setTargetEnemy(e){
        local text = " ";
        if(e != null){
            local enemyName = ::Enemies[e.mEnemy_].getName();
            text = "Targeting: " + enemyName;
        }
        mLabel_.setText(text);

        mCancelButton_.setHidden(e == null)

        mHorizLayout_.layout();
    }

    function addToLayout(layout){
        //mHorizLayout_.layout();
        layout.addCell(mHorizLayout_);
    }
}