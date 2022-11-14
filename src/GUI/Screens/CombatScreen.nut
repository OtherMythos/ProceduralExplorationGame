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
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Combat", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        local cellId = layoutLine.addCell(title);
        layoutLine.setCellExpandHorizontal(cellId, true);

        local description = mWindow_.createLabel();
        description.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        description.setText("Combat is not yet implemented.");
        local cellId = layoutLine.addCell(description);
        layoutLine.setCellExpandHorizontal(cellId, true);

        local button = mWindow_.createButton();
        button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
        button.setText("End combat");
        button.attachListenerForEvent(function(widget, action){
            ::ScreenManager.transitionToScreen(ExplorationScreen(ExplorationLogic()));
        }, _GUI_ACTION_PRESSED, this);
        local cellId = layoutLine.addCell(button);
        layoutLine.setCellExpandHorizontal(cellId, true);
        layoutLine.setCellMinSize(cellId, Vec2(0, 100));

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, 50);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
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