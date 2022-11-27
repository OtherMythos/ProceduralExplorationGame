::CombatScreen <- class extends ::Screen{

    mWindow_ = null;
    mLogicInterface_ = null;

    CombatDisplay = class{
        mWindow_ = null;

        constructor(parentWin){
            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            local title = mWindow_.createLabel();
            title.setText("Combat display");
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

        constructor(parentWin, playerCombatStats){
            mWindow_ = _gui.createWindow(parentWin);
            mWindow_.setClipBorders(0, 0, 0, 0);

            local title = mWindow_.createLabel();
            title.setText("Health: " + playerCombatStats.mHealth);
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(1);
        }
    };

    CombatMovesDisplay = class{
        mWindow_ = null;

        constructor(parentWin){
            mWindow_ = _gui.createWindow(parentWin);

            local title = mWindow_.createButton();
            title.setText("Fight");
        }

        function addToLayout(layoutLine){
            layoutLine.addCell(mWindow_);
            mWindow_.setExpandVertical(true);
            mWindow_.setExpandHorizontal(true);
            mWindow_.setProportionVertical(1);
        }
    };

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

        local combatDisplay = CombatDisplay(mWindow_);
        combatDisplay.addToLayout(layoutLine);

        local statsDisplay = CombatStatsDisplay(mWindow_, ::Base.mPlayerStats.mPlayerCombatStats);
        statsDisplay.addToLayout(layoutLine);

        local movesDisplay = CombatMovesDisplay(mWindow_);
        movesDisplay.addToLayout(layoutLine);

        layoutLine.setMarginForAllCells(20, 20);
        layoutLine.setSize(_window.getWidth(), _window.getHeight());
        layoutLine.layout();
    }

    function update(){
        mLogicInterface_.tickUpdate();
    }

    function notifyExplorationPercentage(percentage){
        mExplorationProgressBar_.setPercentage(percentage);
    }

    function notifyItemFound(item, idx){
        mExplorationItemsContainer_.setItemForIndex(item, idx);
    }

    function notifyEnemyEncounter(enemy){
        ::ScreenManager.transitionToScreen(EncounterPopupScreen(), null, 2);
    }
};