enum CombatScreenState{
    PARENT_OPTIONS,
    SELECT_MOVE,
    SELECT_OPPONENT
}

enum CombatBusEvents{
    STATE_CHANGE,
    OPPONENT_SELECTED,
    OPPONENT_DIED,
    QUEUE_PLAYER_ATTACK,
    ALL_OPPONENTS_DIED
};

::ScreenManager.Screens[Screen.COMBAT_SCREEN] = class extends ::Screen{

    CombatInfoBus = class extends ::Screen.ScreenBus{
        mLogicInterface = null;
        mCombatData = null;

        constructor(logicInterface){
            base.constructor();

            mLogicInterface = logicInterface;
            mCombatData = logicInterface.mData_;
        }
    };

    mWindow_ = null;
    mLogicInterface_ = null;
    mCombatDisplay_ = null;
    mStatsDisplay_ = null;
    mMovesDisplay_ = null;
    mPlayerDialog_ = null;

    mCombatBus_ = null;
    mQueuedAttack_ = null;


    function shutdown(){
        base.shutdown();

        mCombatDisplay_.shutdown();

        mCombatBus_ = null;
        mQueuedAttack_ = null;
        mCombatDisplay_ = null;
        mStatsDisplay_ = null;
        mMovesDisplay_ = null;
        mPlayerDialog_ = null;

        ::Base.notifyEncounterEnded();
    }

    function setup(data){
        mLogicInterface_ = data.logic;
        mLogicInterface_.setupForScreen(this);
        mCombatBus_ = CombatInfoBus(mLogicInterface_);

        mCombatBus_.registerCallback(busCallback, this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        mCombatDisplay_ = CombatDisplay(mWindow_, mCombatBus_);
        mCombatDisplay_.addToLayout(layoutLine);

        local playerStatsLayout = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mPlayerDialog_ = CombatPlayerDialog(mWindow_, mCombatBus_);
        mPlayerDialog_.addToLayout(playerStatsLayout);
        mStatsDisplay_ = CombatStatsDisplay(mWindow_, mCombatBus_);
        mStatsDisplay_.addToLayout(playerStatsLayout);

        layoutLine.addCell(playerStatsLayout);

        mMovesDisplay_ = CombatMovesDisplay(mWindow_, mCombatBus_);
        mMovesDisplay_.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(20, 20);
        layoutLine.setSize(_window.getWidth(), _window.getHeight());
        layoutLine.layout();

        mMovesDisplay_.notifyResize();
        mStatsDisplay_.notifyResize();
        mPlayerDialog_.notifyResize();
        mCombatDisplay_.notifyResize();
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
        }else if(event == CombatBusEvents.ALL_OPPONENTS_DIED){
            ::ScreenManager.queueTransition(::ScreenManager.ScreenData(Screen.COMBAT_SPOILS_POPUP_SCREEN, {"logic": mLogicInterface_}), null, 1);
        }
    }


    function update(){
        mLogicInterface_.update();
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
        ::ScreenManager.transitionToScreen(Screen.MAIN_MENU_SCREEN);
    }

    function notifyAllOpponentsDied(){
        mCombatBus_.notifyEvent(CombatBusEvents.ALL_OPPONENTS_DIED, null);
    }

};

_doFile("res://src/GUI/Screens/Combat/CombatDisplay.nut");
_doFile("res://src/GUI/Screens/Combat/CombatMovesDisplay.nut");
_doFile("res://src/GUI/Screens/Combat/CombatStatsDisplay.nut");
_doFile("res://src/GUI/Screens/Combat/CombatPlayerDialog.nut");