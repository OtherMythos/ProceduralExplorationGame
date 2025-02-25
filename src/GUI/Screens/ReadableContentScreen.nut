::ScreenManager.Screens[Screen.READABLE_CONTENT_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mReadableContent_ = null;

    function setup(data){

        createBackgroundScreen_();

        if(data != null && data.rawin("content")){
            mReadableContent_ = data.content;
        }else{
            mReadableContent_ = [
                "test",
                "second line",
                "third line"
            ];
        }

        mWindow_ = _gui.createWindow("ReadableContentScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setSize(::drawable * 0.8);

        local layoutLine = _gui.createLayoutLine();

        foreach(i in mReadableContent_){
            local label = mWindow_.createLabel();
            label.setText(i);
            label.sizeToFit(mWindow_.getSize().x);
            layoutLine.addCell(label);
        }

        //layoutLine.setMarginForAllCells(0, 20);
        //layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(mWindow_.getSize());
        layoutLine.layout();

        constructButtons(mWindow_.getSize());

        ::InputManager.setActionSet(InputActionSets.MENU);
    }

    function shutdown(){
        base.shutdown();

        ::InputManager.setActionSet(InputActionSets.EXPLORATION);
    }

    function constructButtons(winSize){
        local mHorizontalLayout_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);

        local buttonLabels = [
            "Back",
            "Previous",
            "Next"
        ];
        local buttonFunctions = [
            function(widget, action){
                closeScreen();
            },
            function(widget, action){

            },
            function(widget, action){

            },
        ];

        local buttons = [];
        foreach(c,i in buttonLabels){
            local button = mWindow_.createButton();
            button.setText(i);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
            buttons.append(button);
            mHorizontalLayout_.addCell(button);
        }

        local maxHeight = ::evenOutButtonsForHeight(buttons);

        mHorizontalLayout_.setMarginForAllCells(10, 0);
        mHorizontalLayout_.setPosition(0, winSize.y - maxHeight - 10);
        mHorizontalLayout_.layout();
    }

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            if(::ScreenManager.isScreenTop(mLayerIdx)) closeScreen();
        }
    }

    function closeScreen(){
        ::ScreenManager.backupScreen(mLayerIdx);

        ::Base.mExplorationLogic.unPauseExploration();
    }
};