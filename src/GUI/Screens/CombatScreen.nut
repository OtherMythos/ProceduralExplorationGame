enum CombatScreenState{
    PARENT_OPTIONS,
    SELECT_MOVE,
    SELECT_OPPONENT
}

enum CombatBusEvents{
    STATE_CHANGE,
    OPPONENT_SELECTED,
    OPPONENT_DIED,
    QUEUE_PLAYER_ATTACK
};

::CombatScreen <- class extends ::Screen{

    CombatInfoBus = class extends ::Screen.ScreenBus{
        mLogicInterface = null;
        mCombatData = null;

        constructor(logicInterface){
            base.constructor();

            mLogicInterface = logicInterface;
            mCombatData = logicInterface.mData_;
        }
    };

    CombatDisplay = class{
        mWindow_ = null;
        mCombatBus_ = null;

        mCombatActors = null;

        function enemySelectedButton(widget, action){
            local opponentId = widget.getUserId();
            mCombatBus_.notifyEvent(CombatBusEvents.OPPONENT_SELECTED, opponentId);
        }

        constructor(parentWin, combatBus){
            mCombatBus_ = combatBus;
            combatBus.registerCallback(busCallback, this);
            mCombatActors = [];

            mWindow_ = _gui.createWindow(parentWin);
            //mWindow_.setClipBorders(0, 0, 0, 0);

            local layout = _gui.createLayoutLine();
            local layoutButtons = _gui.createLayoutLine();

            foreach(c,i in combatBus.mCombatData.mOpponentStats){
                local enemyType = i.mEnemyType;

                local textItem = i.mDead ? " " : ::Items.enemyToName(enemyType);
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

    CombatStatsDisplay = class{
        mWindow_ = null;

        mDataDisplays_ = null;

        constructor(parentWin, combatBus){
            combatBus.registerCallback(busCallback, this);

            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            mDataDisplays_ = [];

            local layoutLine = _gui.createLayoutLine();

            local title = mWindow_.createLabel();
            title.setText(" ");
            layoutLine.addCell(title);
            mDataDisplays_.append(title);

            local combatData = combatBus.mCombatData;
            foreach(i in combatData.mOpponentStats){
                local second = mWindow_.createLabel();
                second.setText(" ");
                layoutLine.addCell(second);
                mDataDisplays_.append(second);
            }

            layoutLine.layout();

            notifyCombatChange(combatData);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(1);
        }

        function notifyCombatChange(data){
            setStat_(data.mPlayerStats, mDataDisplays_[0]);
            for(local i = 0; i < data.mOpponentStats.len(); i++){
                local stats = data.mOpponentStats[i];
                if(stats.mDead) continue;
                setStat_(stats, mDataDisplays_[i+1]);
            }
        }

        function setStat_(statObj, guiStat){
            guiStat.setText("Health: " + statObj.mHealth);
        }

        function removeForOpponent(opponentId){
            _gui.destroy(mDataDisplays_[opponentId + 1]);
        }

        function busCallback(event, data){
        }
    };

    CombatMovesDisplay = class{
        mWindow_ = null;
        mCombatBus_ = null;

        mParentOptionsWidgets_ = null;
        mParentOptionsLayout_ = null;
        mMovesOptionsWidgets_ = null;
        mMovesOptionsLayout_ = null;
        mSelectEnemy = null;

        constructor(parentWin, combatBus){
            combatBus.registerCallback(busCallback, this);

            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            mCombatBus_ = combatBus;

            //Parent window options
            {
                mParentOptionsWidgets_ = [];
                mMovesOptionsWidgets_ = [];

                mParentOptionsLayout_ = _gui.createLayoutLine();

                local buttonLabels = ["Fight", "Inventory", "Flee"];
                local buttonFunctions = [
                    function(widget, action){
                        setDialogState(CombatScreenState.SELECT_MOVE);
                    },
                    function(widget, action){
                        ::ScreenManager.transitionToScreen(InventoryScreen(::Base.mInventory));
                    },
                    function(widget, action){
                        print("Fleeing");
                        ::ScreenManager.transitionToScreen(ExplorationScreen(::Base.mExplorationLogic));
                    },
                ];
                foreach(c,i in buttonLabels){
                    local button = mWindow_.createButton();
                    button.setText(i);
                    button.setExpandVertical(true);
                    button.setExpandHorizontal(true);
                    button.setProportionVertical(1);
                    button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
                    mParentOptionsLayout_.addCell(button);
                    mParentOptionsWidgets_.append(button);
                }

                mParentOptionsLayout_.setMarginForAllCells(5, 5);
            }

            //Moves window options
            {
                mMovesOptionsWidgets_ = [];

                mMovesOptionsLayout_ = _gui.createLayoutLine();

                local buttonLabels = ["Attack", "Special 1", "Special 2", "Special 3", "Special 4", "Back"];
                local performSpecialAttack_ = function(id){
                    mCombatBus_.notifyEvent(CombatBusEvents.QUEUE_PLAYER_ATTACK, id);
                    setDialogState(CombatScreenState.SELECT_OPPONENT);
                }
                local buttonFunctions = [
                    function(widget, action){
                        mCombatBus_.notifyEvent(CombatBusEvents.QUEUE_PLAYER_ATTACK, -1);
                        setDialogState(CombatScreenState.SELECT_OPPONENT);
                    },
                    //TODO do this with
                    function(widget, action){ performSpecialAttack_(0); },
                    function(widget, action){ performSpecialAttack_(1); },
                    function(widget, action){ performSpecialAttack_(2); },
                    function(widget, action){ performSpecialAttack_(3); },
                    function(widget, action){
                        setDialogState(CombatScreenState.PARENT_OPTIONS);
                    },
                ];
                foreach(c,i in buttonLabels){
                    local button = mWindow_.createButton();
                    button.setText(i);
                    button.setUserId(c);
                    button.setExpandVertical(true);
                    button.setExpandHorizontal(true);
                    button.setProportionVertical(1);
                    button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
                    mMovesOptionsLayout_.addCell(button);
                    mMovesOptionsWidgets_.append(button);

                    if(c == 5){
                        button.setSkinPack("ButtonRed");
                    }
                }

            }

            {
                mSelectEnemy = mWindow_.createLabel();
                mSelectEnemy.setText("Select an enemy");
            }

            setDialogState(CombatScreenState.PARENT_OPTIONS);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(2);
        }

        function notifyResize(){
            //TODO this is a common pattern. Consider how it could be optimised.
            mParentOptionsLayout_.setSize(mWindow_.getSize());
            mParentOptionsLayout_.layout();
            mMovesOptionsLayout_.setSize(mWindow_.getSize());
            mMovesOptionsLayout_.layout();
        }

        function setDialogState(state){
            local parentOptions = (state == CombatScreenState.PARENT_OPTIONS);
            local movesOptions = (state == CombatScreenState.SELECT_MOVE);
            local selectEnemy = (state == CombatScreenState.SELECT_OPPONENT);

            foreach(i in mParentOptionsWidgets_){
                i.setHidden(!parentOptions);
            }
            foreach(i in mMovesOptionsWidgets_){
                i.setHidden(!movesOptions);
            }
            mSelectEnemy.setHidden(!selectEnemy);

            mCombatBus_.notifyEvent(CombatBusEvents.STATE_CHANGE, state);
        }

        function busCallback(event, data){

        }
    };

    mWindow_ = null;
    mLogicInterface_ = null;
    mCombatDisplay_ = null;
    mStatsDisplay_ = null;
    mMovesDisplay_ = null;

    mCombatBus_ = null;
    mQueuedAttack_ = null;


    constructor(logicInterface){
        mLogicInterface_ = logicInterface;
    }

    function shutdown(){
        base.shutdown();

        mCombatBus_ = null;
        mQueuedAttack_ = null;
        mCombatDisplay_ = null;
        mStatsDisplay_ = null;
        mMovesDisplay_ = null;
    }

    function setup(){
        mLogicInterface_.setGuiObject(this);
        mCombatBus_ = CombatInfoBus(mLogicInterface_);

        mCombatBus_.registerCallback(busCallback, this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        mCombatDisplay_ = CombatDisplay(mWindow_, mCombatBus_);
        mCombatDisplay_.addToLayout(layoutLine);

        mStatsDisplay_ = CombatStatsDisplay(mWindow_, mCombatBus_);
        mStatsDisplay_.addToLayout(layoutLine);

        mMovesDisplay_ = CombatMovesDisplay(mWindow_, mCombatBus_);
        mMovesDisplay_.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(20, 20);
        layoutLine.setSize(_window.getWidth(), _window.getHeight());
        layoutLine.layout();

        mMovesDisplay_.notifyResize();
    }

    function busCallback(event, data){
        if(event == CombatBusEvents.OPPONENT_SELECTED){
            print("Opponent: " + data);
            //TODO do this with the bus.
            mMovesDisplay_.setDialogState(CombatScreenState.PARENT_OPTIONS);

            local opponentId = data;
            //Actually perform the attack.
            assert(mQueuedAttack_ != null);
            if(mQueuedAttack_ < 0){
                mCombatBus_.mLogicInterface.playerRegularAttack(opponentId);
            }else{
                mCombatBus_.mLogicInterface.playerSpecialAttack(mQueuedAttack_, opponentId);
            }
            mQueuedAttack_ = null;

            mCombatBus_.mLogicInterface.performOpponentAttacks();
        }else if(event == CombatBusEvents.QUEUE_PLAYER_ATTACK){
            //TODO might want to separate this out into a designated logic component.
            //This would have no actual gui, but would listen on the bus and coordinate what the gui is meant to be doing.
            mQueuedAttack_ = data;
        }
    }


    function update(){
        mLogicInterface_.tickUpdate();
    }

    function notifyStatsChange(combatData){
        mStatsDisplay_.notifyCombatChange(combatData);
    }

    function notifyOpponentDied(opponentId){
        mCombatBus_.notifyEvent(CombatBusEvents.OPPONENT_DIED, opponentId);
        //TODO properly replace this with bus events, rather than direct calls.
        mStatsDisplay_.removeForOpponent(opponentId);
        mCombatDisplay_.removeForOpponent(opponentId);
    }

    function notifyPlayerDied(){
        print("player died");

        _event.transmit(Event.PLAYER_DIED, null);
        ::ScreenManager.transitionToScreen(MainMenuScreen());
    }

    function notifyAllOpponentsDied(){
        ::ScreenManager.queueTransition(ExplorationScreen(::Base.mExplorationLogic));
    }

};