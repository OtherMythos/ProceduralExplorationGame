::CombatScreen <- class extends ::Screen{

    CombatDisplay = class{
        mWindow_ = null;

        mCombatActors = null;

        constructor(parentWin, combatData){
            mCombatActors = [];

            mWindow_ = _gui.createWindow(parentWin);
            //mWindow_.setClipBorders(0, 0, 0, 0);

            local layout = _gui.createLayoutLine();

            foreach(i in combatData.mOpponentStats){
                local enemyType = i.mEnemyType;

                local enemyLabel = mWindow_.createLabel();
                enemyLabel.setText(i.mDead ? " " : ::Items.enemyToName(enemyType));
                layout.addCell(enemyLabel);

                mCombatActors.append(enemyLabel);
            }

            layout.layout();
        }

        function removeForOpponent(opponentId){
            _gui.destroy(mCombatActors[opponentId]);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(2);
        }
    };

    CombatStatsDisplay = class{
        mWindow_ = null;

        mDataDisplays_ = null;

        constructor(parentWin, combatData){
            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            mDataDisplays_ = [];

            local layoutLine = _gui.createLayoutLine();

            local title = mWindow_.createLabel();
            title.setText(" ");
            layoutLine.addCell(title);
            mDataDisplays_.append(title);

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
    };

    CombatMovesDisplay = class{
        mWindow_ = null;
        mLogic_ = null;

        mParentOptionsWidgets_ = null;
        mParentOptionsLayout_ = null;
        mMovesOptionsWidgets_ = null;
        mMovesOptionsLayout_ = null;

        constructor(parentWin, logic){
            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            mLogic_ = logic;

            //Parent window options
            {
                mParentOptionsWidgets_ = [];
                mMovesOptionsWidgets_ = [];

                mParentOptionsLayout_ = _gui.createLayoutLine();

                local buttonLabels = ["Fight", "Inventory", "Flee"];
                local buttonFunctions = [
                    function(widget, action){
                        setMovesVisible(true);
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
                    mLogic_.playerSpecialAttack(id);
                    setMovesVisible(false);
                }
                local buttonFunctions = [
                    function(widget, action){
                        mLogic_.playerRegularAttack();
                        setMovesVisible(false);
                    },
                    //TODO do this with
                    function(widget, action){ performSpecialAttack_(0); },
                    function(widget, action){ performSpecialAttack_(1); },
                    function(widget, action){ performSpecialAttack_(2); },
                    function(widget, action){ performSpecialAttack_(3); },
                    function(widget, action){
                        setMovesVisible(false);
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

            setMovesVisible(false);
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

        function setMovesVisible(visible){
            foreach(i in mParentOptionsWidgets_){
                i.setHidden(visible);
            }
            foreach(i in mMovesOptionsWidgets_){
                i.setHidden(!visible);
            }
        }
    };

    mWindow_ = null;
    mLogicInterface_ = null;
    mCombatDisplay_ = null;

    mStatsDisplay_ = null;

    constructor(logicInterface){
        mLogicInterface_ = logicInterface;
        mLogicInterface_.setGuiObject(this);
    }

    function setup(){
        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        mCombatDisplay_ = CombatDisplay(mWindow_, ::Base.mCurrentCombatData);
        mCombatDisplay_.addToLayout(layoutLine);

        mStatsDisplay_ = CombatStatsDisplay(mWindow_, ::Base.mCurrentCombatData);
        mStatsDisplay_.addToLayout(layoutLine);

        local movesDisplay = CombatMovesDisplay(mWindow_, mLogicInterface_);
        movesDisplay.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(20, 20);
        layoutLine.setSize(_window.getWidth(), _window.getHeight());
        layoutLine.layout();

        movesDisplay.notifyResize();
    }

    function update(){
        mLogicInterface_.tickUpdate();
    }

    function notifyOpponentStatsChange(combatData){
        mStatsDisplay_.notifyCombatChange(combatData);
    }

    function notifyOpponentDied(combatData){
        mStatsDisplay_.removeForOpponent(0);
        mCombatDisplay_.removeForOpponent(0);
    }

};