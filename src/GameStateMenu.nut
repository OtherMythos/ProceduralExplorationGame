enum MENUS{
    main,
    help,
};

::GameStateMenu <- class{

    mMainMenuWindow_ = null;
    mHelpMenuWindow_ = null;

    constructor(){

    }

    function createBackButton(window){
        local backButton = window.createButton();
        backButton.setText("back");
        backButton.setSize(buttonSize);
        backButton.setDefaultFontSize(backButton.getDefaultFontSize() * 1.5);
        backButton.setPosition(_window.getWidth() / 2 - buttonSize.x / 2, _window.getHeight() - buttonSize.y - 30);
        backButton.attachListener(function(widget, action){
            if(action != 2) return;
            switchToWindow(MENUS.main);
        }, this);
    }

    function createMainMenu(){
        mMainMenuWindow_ = _gui.createWindow();
        mMainMenuWindow_.setSize(_window.getWidth(), _window.getHeight());
        mMainMenuWindow_.setVisualsEnabled(false);

        local layoutLine = _gui.createLayoutLine();

        local buttonOptions = ["play", "help"];
        local buttonFunctions = [
            function(widget, action){
                print("Playing");
                ::startState(::GameStatePlaying);
            },
            function(widget, action){
                switchToWindow(MENUS.help);
            }
        ]

        local panelWidth = _window.getWidth() * 0.9;

        foreach(i,c in buttonOptions){
            local button = mMainMenuWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.setSize(buttonSize);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(_window.getWidth() / 2 - panelWidth / 2, 100);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();
    }

    function createHelpMenu(){
        mHelpMenuWindow_ = _gui.createWindow();
        mHelpMenuWindow_.setSize(_window.getWidth(), _window.getHeight());
        mHelpMenuWindow_.setVisualsEnabled(false);

        local layoutLine = _gui.createLayoutLine();

        local panelWidth = _window.getWidth() * 0.65;

        local text = @"A text based adventure game";
        local label = mHelpMenuWindow_.createLabel();
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setText(text);
        label.setSize(_window.getWidth() - 60, _window.getHeight());
        layoutLine.addCell(label);

        layoutLine.setMarginForAllCells(0, 40);
        layoutLine.setPosition(0, 100);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();

        createBackButton(mHelpMenuWindow_);
    }

    function start(){
        switchToWindow(MENUS.main);
    }

    function switchToWindow(window){
        destroyWindows();

        switch(window){
            case MENUS.help:{
                createHelpMenu();
                break;
            }
            case MENUS.main:{
                createMainMenu();
                break;
            }
        }
    }

    function destroyWindows(){
        if(mMainMenuWindow_ != null) _gui.destroy(mMainMenuWindow_);
        if(mHelpMenuWindow_ != null) _gui.destroy(mHelpMenuWindow_);

        mMainMenuWindow_ = null;
        mHelpMenuWindow_ = null;
    }

    function end(){
        destroyWindows();
    }

    function update(){

    }

    function notifyTouchInputBegan(fingerId){}
    function notifyTouchInputEnded(fingerId){}
    function notifyTouchInputMotion(fingerId){}
};