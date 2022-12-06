::SaveSelectionScreen <- class extends ::Screen{

    function saveSelectionCallback_(widget, action){
        print(format("Selected save %i", widget.getUserId()));

        //There is no implementation for saves yet, so just switch the screen.
        ::ScreenManager.transitionToScreenForId(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
    }

    function setup(data){
        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Select a save", false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);

        for(local i = 0; i < 3; i++){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(format("Save %i", i));
            button.setUserId(i);
            button.attachListenerForEvent(saveSelectionCallback_, _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
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