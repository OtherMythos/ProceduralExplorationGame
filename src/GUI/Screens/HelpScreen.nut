::ScreenManager.Screens[Screen.HELP_SCREEN] = class extends ::Screen{

    mWindow_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 1.5);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText(GAME_TITLE, false);
        title.sizeToFit(_window.getWidth() * 0.9);
        layoutLine.addCell(title);


        local text = @"A game attempting to encapsulate the feeling of exploring a large fantasy world into a simple gameplay loop.

        The game is being developed as part of a larger project to build an audience, develop the avEngine and practice game development.
        A simple idea was chosen initially as a concept to develop, however eventually the scope was increased to provide more of a challenge to the developer.
        Importantly the finished game should be a sizeable experience with a decent amount of replay value.

        The game will be released to the general public as part of its alpha development so feedback can be gathered, maybe that's why you're reading this now O.o
        ";
        local label = mWindow_.createLabel();
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setText(text);
        label.setSize(_window.getWidth() - 60, _window.getHeight());
        layoutLine.addCell(label);


        local backButton = mWindow_.createButton();
        //backButton.setSize(buttonSize);
        backButton.setDefaultFontSize(backButton.getDefaultFontSize() * 1.5);
        backButton.setText("back");
        local buttonSize = backButton.getSize();
        buttonSize.x = _window.getWidth() / 2;
        backButton.setSize(buttonSize);
        backButton.setPosition(_window.getWidth() / 2 - buttonSize.x / 2, _window.getHeight() - buttonSize.y - 30);
        backButton.attachListenerForEvent(function(widget, action){
            ::ScreenManager.transitionToScreen(Screen.MAIN_MENU_SCREEN);
        }, _GUI_ACTION_PRESSED, this);

        layoutLine.setMarginForAllCells(0, 100);
        layoutLine.setPosition(_window.getWidth() * 0.05, _window.getHeight() * 0.02);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * 0.9, _window.getHeight());
        layoutLine.layout();
    }


    function update(){

    }
};