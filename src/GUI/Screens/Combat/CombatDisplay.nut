::ScreenManager.Screens[Screen.COMBAT_SCREEN].CombatDisplay <- class{
    mWindow_ = null;
    mCombatBus_ = null;

    mCombatActors = null;

    mCombatScenePanel_ = null;
    mCompositorId_ = null;

    function enemySelectedButton(widget, action){
        local opponentId = widget.getUserId();
        mCombatBus_.notifyEvent(CombatBusEvents.OPPONENT_SELECTED, opponentId);
    }

    constructor(parentWin, combatBus){
        mCombatBus_ = combatBus;
        combatBus.registerCallback(busCallback, this);
        mCombatActors = [];

        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);

        {
            local victoryButton = mWindow_.createButton();
            victoryButton.setText("Trigger victory");
            victoryButton.setPosition(300, 0);
            victoryButton.attachListenerForEvent(function(widget, action){
                mCombatBus_.notifyEvent(CombatBusEvents.ALL_OPPONENTS_DIED, null);
            }, _GUI_ACTION_PRESSED, this);
        }

        mCombatScenePanel_ = mWindow_.createPanel();
        mCombatScenePanel_.setPosition(0, 0);

        local layout = _gui.createLayoutLine();
        local layoutButtons = _gui.createLayoutLine();

        foreach(c,i in combatBus.mCombatData.mOpponentStats){
            local enemyType = i.mEnemyType;

            local textItem = i.mDead ? " " : ::Enemies[enemyType].getName();
            local enemyLabel = mWindow_.createLabel();
            enemyLabel.setText(textItem);
            layout.addCell(enemyLabel);

            local enemyButton = mWindow_.createButton();
            enemyButton.setText(textItem);
            enemyButton.setUserId(c);
            enemyButton.attachListenerForEvent(enemySelectedButton, _GUI_ACTION_PRESSED, this);
            layoutButtons.addCell(enemyButton);

            mCombatActors.append([enemyLabel, enemyButton]);
        }

        layout.layout();
        layoutButtons.layout();

        setButtonsVisible(false);
    }

    function shutdown(){
        mCombatScenePanel_.setDatablock("unlitEmpty");
        shutdownCompositor_();
    }

    function shutdownCompositor_(){
        if(mCompositorId_ == null) return;
        ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
        mCompositorId_ = null;
    }

    function notifyResize(){
        local winSize = mWindow_.getSize();
        mCombatScenePanel_.setSize(winSize);

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture20Workspace", winSize, CompositorSceneType.COMBAT);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mCombatScenePanel_.setDatablock(datablock);
    }

    function setButtonsVisible(visible){
        foreach(i in mCombatActors){
            if(i == null) continue;
            i[0].setHidden(visible);
            i[1].setHidden(!visible);
        }
    }

    function removeForOpponent(opponentId){
        local actors = mCombatActors[opponentId]
        _gui.destroy(actors[0]);
        _gui.destroy(actors[1]);
        mCombatActors[opponentId] = null;
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(2);
    }

    function _handleStateChange(event){
        setButtonsVisible(event == CombatScreenState.SELECT_OPPONENT);
    }

    function busCallback(event, data){
        switch(event){
            case CombatBusEvents.STATE_CHANGE:{
                _handleStateChange(data);
                break;
            }
        }
    }
};