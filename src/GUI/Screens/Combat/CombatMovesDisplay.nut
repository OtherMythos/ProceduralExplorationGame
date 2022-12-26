::ScreenManager.Screens[Screen.COMBAT_SCREEN].CombatMovesDisplay <- class{
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
                    ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN, {"inventory": ::Base.mInventory, "equipStats": ::Base.mPlayerStats.mPlayerCombatStats.mEquippedItems}));
                },
                function(widget, action){
                    print("Fleeing");
                    ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
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