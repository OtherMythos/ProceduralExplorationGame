::ScreenManager.Screens[Screen.NEW_SAVE_VALUES_SCREEN] = class extends ::Screen{

    mEditBox_ = null;

    function setup(data){
        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();

        mWindow_ = _gui.createWindow("NewSaveValuesScreen");
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setZOrder(61);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText("Information");
        title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        title.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(title);

        local editbox = mWindow_.createEditbox();
        editbox.setMinSize(winWidth, 100);
        editbox.setMargin(0, 10);
        mEditBox_ = editbox;
        layoutLine.addCell(editbox);

        local buttonOptions = ["Confirm", "Cancel"];
        local buttonFunctions = [
            function(widget, action){
                local name = obtainPlayerName();
                if(name == null){
                    _window.showMessageBox({
                        "message": "Invalid name provided.",
                        "flags": _MESSAGEBOX_ERROR
                    });
                    return;
                }
                local freeSlot = ::SaveManager.getFreeSaveSlot();
                local save = ::Base.mSaveManager.produceSave();
                save.playerName = name;
                ::Base.mPlayerStats.setSaveData(save, freeSlot);
                ::SaveManager.writeSaveAtPath("user://" + freeSlot, ::Base.mPlayerStats.getSaveData());

                ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            },
            function(widget, action){
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            }
        ];
        local endButtons = [];
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
            endButtons.append(button);
        }

        layoutLine.setSize(winWidth, winHeight);
        layoutLine.setPosition(0, 0);
        layoutLine.layout();
    }

    function obtainPlayerName(){
        local value = mEditBox_.getText();
        local parser = ::SaveManager.getMostRecentParser();
        if(!parser.validatePlayerName(value)) return null;

        return value;
    }
}