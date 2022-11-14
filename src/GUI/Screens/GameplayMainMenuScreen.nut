::GameplayMainMenuScreen <- class extends ::Screen{

    constructor(){

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
        title.setText("Main Menu", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);

        local buttonOptions = ["Explore", "Inventory", "Visit"];
        local buttonFunctions = [
            function(widget, action){
                print("Explore");
                ::ScreenManager.transitionToScreen(ExplorationScreen(::Base.mExplorationLogic));
            },
            function(widget, action){
                print("Inventory");
            },
            function(widget, action){
                print("Visit");
            }
        ]

        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.setSize(_window.getWidth() * 0.9, button.getSize().y * 1.5);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            local cellId = layoutLine.addCell(button);
            layoutLine.setCellExpandHorizontal(cellId, true);
            layoutLine.setCellMinSize(cellId, Vec2(0, 100));
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.layout();
    }

    function update(){

    }
};