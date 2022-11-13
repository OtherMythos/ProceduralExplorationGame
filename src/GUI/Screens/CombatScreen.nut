::CombatScreen <- class extends ::Screen{

    mWindow_ = null;
    mLogicInterface_ = null;

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

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setText("Exploring");
        layoutLine.addCell(title);

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
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