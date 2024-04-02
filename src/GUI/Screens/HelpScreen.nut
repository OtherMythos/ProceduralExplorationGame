::ScreenManager.Screens[Screen.HELP_SCREEN] = class extends ::Screen{

    mWindow_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow("HelpScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        local MULTIPLIER_PADDING = 0.15;
        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2.0);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText(GAME_TITLE, false);
        title.sizeToFit(_window.getWidth() * (1.0 - MULTIPLIER_PADDING));
        layoutLine.addCell(title);
        //title.setMargin(20, 20);


        //TODO separate form from style ;)
        local text = @"

This game is in development as part of the OtherMythos YouTube channel and project. At the moment it is more of a gameplay prototype than a complete game. It is being developed as part of a larger project, specifically to develop a game over the course of ten years by a single developer.

This game is intended to distill the feeling of exploring a large fantasy world into a bitesize gameplay model. The loop involves:
    •    Exploring a fantasy world
    •    Collecting items, killing monsters
    •    Finding the gateway to end the exploration and levelling up

From developing this game I intend to learn the following:
    •    Gain experience releasing commercial games, including distribution on Steam and the mobile app stores
    •    How to market a digital product, using YouTube primarily to do this
    •    Ensure the avEngine is stable and portable by releasing a game with it
    •    Skills for general game development including decent desktop and mobile interfaces, reliable code quality at scale, decent artistic design and appearance, etc

Gameplay sessions are intended to fit into 5-10 minute bursts and are generally targeted at mobile players.

This project is undertaken by Edward Herbert using the alias OtherMythos.
Contact: edward@OtherMythos.com
GitHub: @OtherMythos
YouTube: @OtherMythos
Engine: github.com/OtherMythos/avEngine
Game: github.com/OtherMythos/ProceduralExplorationGame
Join the discord
Bugs, issues and suggestions are best reported on discord, however email or GitHub issues will still be accepted.
        ";
        local label = mWindow_.createLabel();
        //label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setText(text);
        label.setSize(_window.getWidth() * (1.0 - MULTIPLIER_PADDING), _window.getHeight());
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

        //layoutLine.setMarginForAllCells(0, 200);
        layoutLine.setPosition(_window.getWidth() * (MULTIPLIER_PADDING / 2), _window.getHeight() * 0.02);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(_window.getWidth() * (1.0 - MULTIPLIER_PADDING), _window.getHeight());
        layoutLine.layout();
    }


    function update(){

    }
};