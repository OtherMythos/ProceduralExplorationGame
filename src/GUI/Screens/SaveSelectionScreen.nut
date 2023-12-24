::ScreenManager.Screens[Screen.SAVE_SELECTION_SCREEN] = class extends ::Screen{

    SaveEntryScreen = class{
        mWindow_ = null;
        mButton_ = null;
        mSaveData_ = null;

        mTitle_ = null;
        mPlaytimeLabel_ = null;
        mLevelLabel_ = null;

        function saveSelectionCallback_(widget, action){
            print(format("Selected save %i", widget.getUserId()));

            local viableSaves = ::Base.mSaveManager.findViableSaves();
            local save = ::Base.mSaveManager.readSaveAtPath("user://" + viableSaves[widget.getUserId()].tostring());
            ::Base.mPlayerStats.setSaveData(save);

            //There is no implementation for saves yet, so just switch the screen.
            ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
        }

        constructor(idx, window, data){
            mWindow_ = window;
            mSaveData_ = data;

            local button = window.createButton();
            button.setUserId(idx);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            mButton_ = button;
            //layoutLine.addCell(button);

            mTitle_ = mWindow_.createLabel();
            mTitle_.setText(data.playerName);
            mPlaytimeLabel_ = mWindow_.createLabel();
            local seconds = data.playtimeSeconds;
            mPlaytimeLabel_.setText(format("Playtime: %i:%i", (seconds / 60).tointeger(), seconds % 60));
            mLevelLabel_ = mWindow_.createLabel();
            mLevelLabel_.setText("Level " + data.playerLevel);

            mButton_.setUserId(data.saveId);
            button.attachListenerForEvent(saveSelectionCallback_, _GUI_ACTION_PRESSED);
        }

        function addToLayout(layout){
            layout.addCell(mButton_);
        }
        function notifyLayout(){
            local originPos = mButton_.getPosition();

            mTitle_.setPosition(originPos);
            local playtimeSize = mPlaytimeLabel_.getSize();
            local newPos = originPos + Vec2(0, playtimeSize.y);
            mPlaytimeLabel_.setPosition(newPos);
            mLevelLabel_.setPosition(newPos + Vec2(playtimeSize.x + 50, 0));
        }
    };

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

        //local viableSaves = ::Base.mSaveManager.findViableSaves();
        local viableSaves = ::Base.mSaveManager.obtainViableSaveInfo();

        local layoutWidgets = [];
        for(local i = 0; i < viableSaves.len(); i++){
            local widget = SaveEntryScreen(i, mWindow_, viableSaves[i]);
            widget.addToLayout(layoutLine);
            layoutWidgets.append(widget);
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

        foreach(i in layoutWidgets){
            i.notifyLayout();
        }
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