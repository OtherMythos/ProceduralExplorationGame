::ScreenManager.Screens[Screen.SAVE_EDIT_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mTestRenderIcon_ = null;
    mCurrentDataLabel_ = null;

    mCurrentData_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow("SaveEditScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local label = mWindow_.createLabel();
        label.setText(" ");
        label.setSize(_window.getWidth() - 20, _window.getHeight());
        label.setPosition(0, 0);
        mCurrentDataLabel_ = label;

        local layoutLine = _gui.createLayoutLine();

        local buttonOptions = [
            "Parse save 0",
            "Save save 0",
        ];
        local buttonFunctions = [
            function(widget, action){
                mCurrentData_ = ::Base.mSaveManager.readSaveAtPath("user://0");
                mCurrentDataLabel_.setText(_prettyPrint(mCurrentData_));
            },
            function(widget, action){
                //Add a coin to show the change took place.
                mCurrentData_.playerCoins++;
                ::Base.mSaveManager.writeSaveAtPath("user://0", mCurrentData_);
            },
        ]

        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 50);
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