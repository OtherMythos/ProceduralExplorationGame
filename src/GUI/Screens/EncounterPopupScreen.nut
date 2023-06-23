
enum EncounterPopupScreenStages{
    NONE,
    INITIAL_APPEAR,
    IDLE,

    MAX
}
const ENCOUNTER_EFFECT_ENEMY_Z = 50;

local EncounterPopupScreenStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(EncounterPopupScreenStages.MAX);
};

{
    EncounterPopupScreenStateMachine.mStates_[EncounterPopupScreenStages.INITIAL_APPEAR] = class extends ::Util.State{
        mTotalCount_ = 20
        mNextState_ = EncounterPopupScreenStages.IDLE;
        function start(data){
            data.node.setPosition(0, 0, 0);
            data.win.setHidden(true);
        }
        function update(p, data){
            local animPercentage = 1 - pow(1 - p, 4);
            data.animNode.setScale(Vec3(animPercentage));
            local animX = computePoint(data, animPercentage);

            local c1 = 6;
            local c3 = c1 + 1;
            local val = 1 + c3 * pow(p - 1, 3) + c1 * pow(p - 1, 2);

            local animY = computePoint(data, val);
            data.node.setPosition(animX.x, animY.y, ENCOUNTER_EFFECT_ENEMY_Z);
        }
        function computePoint(data, v){
            return data.start + ((data.end - data.start) * v);
        }
    };
    EncounterPopupScreenStateMachine.mStates_[EncounterPopupScreenStages.IDLE] = class extends ::Util.State{
        mTotalCount_ = 200
        mNextState_ = EncounterPopupScreenStages.NONE;
        function start(data){
            data.win.setHidden(false);
        }
        function update(p, data){
            data.animNode.setOrientation(Quat(p * 12, Vec3(0, 1, 0)));
        }
    };
}

::PopupManager.Popups[Popup.ENCOUNTER] = class extends ::Popup{

    mCombatData_ = null;
    mEnemyStart_ = null;
    mEnemyEnd_ = null;

    mCount_ = 0;
    mMaxCount_ = 150;
    mBackgroundColour_ = false;

    mParentNode_ = null;
    mObjectNode_ = null;
    mAnimNode_ = null;

    mStateMachine_ = null;

    function setup(data){
        mCombatData_ = data.combatData;
        mEnemyStart_ = data.start;
        mEnemyEnd_ = data.end;

        local winWidth = _window.getWidth() * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();

        mPopupWin_ = _gui.createWindow();
        mPopupWin_.setSize(winWidth, _window.getHeight() * 0.333);
        mPopupWin_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.333);
        mPopupWin_.setClipBorders(10, 10, 10, 10);

        local title = mPopupWin_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Encounter");
        title.setSize(winWidth, title.getSize().y);
        title.setTextColour(0, 0, 0, 1);

        local enemyName = mPopupWin_.createLabel();
        enemyName.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        enemyName.setText(getNameForEnemies(mCombatData_));
        enemyName.setSize(winWidth, enemyName.getSize().y);
        enemyName.setTextColour(0, 0, 0, 1);

        mPopupWin_.setSize(winWidth, title.getSize().y + 10*2);
        mPopupWin_.setHidden(true);

        setBackground(mBackgroundColour_);

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
        setupScene(mParentNode_);

        local targetPos = ::EffectManager.getWorldPositionForWindowPos(Vec2(_window.getWidth() / 2, _window.getHeight() * 0.33));

        local machineData = {
            "start": mEnemyStart_,
            "end": targetPos,
            "node": mObjectNode_,
            "animNode": mAnimNode_,
            "win": mPopupWin_
        };
        mStateMachine_ = EncounterPopupScreenStateMachine(machineData);
        mStateMachine_.setState(EncounterPopupScreenStages.INITIAL_APPEAR);
    }

    function getNameForEnemies(combatData){
        local combatLen = mCombatData_.mOpponentStats.len();
        assert(combatLen > 0);
        if(combatLen == 1){
            local enemyType = mCombatData_.mOpponentStats[0].mEnemyType;
            return ::Enemies[enemyType].getName();
        }

        return "Multiple enemies";
    }

    function update(){
        mCount_++;
        if(mCount_ % 25 == 0){
            mBackgroundColour_ = !mBackgroundColour_;
            setBackground(mBackgroundColour_);
        }

        if(mCount_ == mMaxCount_){
            //::ScreenManager.transitionToScreen(null, null, mLayerIdx);
            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.COMBAT_SCREEN, {"logic": ::Base.mCombatLogic}));
            return false;
        }
        assert(mCount_ <= mMaxCount_);

        mStateMachine_.update();

        return true;
    }

    function setBackground(background){
        if(background) mPopupWin_.setDatablock("gui/encounterWindowFirstColour");
        else mPopupWin_.setDatablock("gui/encounterWindowSecondColour");
    }

    function shutdown(){
        _gui.destroy(mPopupWin_);
        _gui.destroy(mBackgroundWindow_);

        mParentNode_.destroyNodeAndChildren();

        mStateMachine_.setState(EncounterPopupScreenStages.NONE);
    }

    function setupScene(parentNode){
        local newNode = parentNode.createChildSceneNode();
        local animNode = newNode.createChildSceneNode();
        local opponentItem = _scene.createItem("goblin.mesh");
        opponentItem.setRenderQueueGroup(66);
        animNode.attachObject(opponentItem);

        newNode.setScale(0.5, 0.5, 0.5);
        newNode.setPosition(Vec3(mEnemyStart_.x, mEnemyStart_.y, ENCOUNTER_EFFECT_ENEMY_Z));

        mObjectNode_ = newNode;
        mAnimNode_ = animNode;
    }
}