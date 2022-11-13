::SaveSelectionScreen <- class extends ::Screen{

    constructor(){

    }

    function saveSelectionCallback_(widget, action){
        print(format("Selected save %i", widget.getUserId()));

        //There is no implementation for saves yet, so just switch the screen.
        ::ScreenManager.transitionToScreen(GameplayMainMenuScreen());
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
        title.setText("Select a save kfjsdlkf fskldjfsdkl", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);

        for(local i = 0; i < 3; i++){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(format("Save %i", i));
            button.setUserId(i);
            button.attachListenerForEvent(saveSelectionCallback_, _GUI_ACTION_PRESSED, this);
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