::ScreenManager.Screens[Screen.SAVE_SELECTION_SCREEN] = class extends ::Screen{

    function saveSelectionCallback_(widget, action){
        print(format("Selected save %i", widget.getUserId()));

        local viableSaves = ::Base.mSaveManager.findViableSaves();
        local save = ::Base.mSaveManager.readSaveAtPath("user://" + viableSaves[widget.getUserId()].tostring());
        ::Base.mPlayerStats.setSaveData(save);

        //There is no implementation for saves yet, so just switch the screen.
        ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
    }
    function newSaveCallback_(widget, action){
        local save = ::Base.mSaveManager.produceSave();
        ::Base.mPlayerStats.setSaveData(save);

        ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
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

        local viableSaves = ::Base.mSaveManager.findViableSaves();

        for(local i = 0; i < viableSaves.len(); i++){
            createSaveEntry(i, mWindow_, layoutLine);
        }

        {
            local newSaveButton = mWindow_.createButton();
            newSaveButton.setDefaultFontSize(newSaveButton.getDefaultFontSize() * 1.5);
            newSaveButton.setText("Create new save");
            newSaveButton.attachListenerForEvent(newSaveCallback_, _GUI_ACTION_PRESSED, this);
            newSaveButton.setExpandHorizontal(true);
            newSaveButton.setMinSize(0, 100);
            layoutLine.addCell(newSaveButton);
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.layout();
    }

    function createSaveEntry(idx, window, layoutLine){
        local button = window.createButton();
        button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
        button.setText(format("Save %i", idx));
        button.setUserId(idx);
        button.attachListenerForEvent(saveSelectionCallback_, _GUI_ACTION_PRESSED, this);
        button.setExpandHorizontal(true);
        button.setMinSize(0, 100);
        layoutLine.addCell(button);
    }

    function update(){

    }
};