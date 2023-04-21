::ScreenManager.Screens[Screen.EXPLORATION_END_SCREEN] = class extends ::Screen{

    mCombatData_ = null;
    mEnemyStart_ = null;
    mEnemyEnd_ = null;

    mBackgroundWindow_ = null;

    function setup(data){

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        //Create a window to block inputs for when the popup appears.
        mBackgroundWindow_ = createBackgroundScreen_();
        mBackgroundWindow_.setZOrder(60);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Exploration Complete");
        title.setSize(winWidth, title.getSize().y);
        title.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(title);

        local descText = mWindow_.createLabel();
        descText.setText(getTextForExploration(data));
        //descText.setSize(winWidth, descText.getSize().y);
        //descText.setTextColour(0, 0, 0, 1);
        descText.sizeToFit(winWidth);
        descText.setExpandHorizontal(true);
        layoutLine.addCell(descText);

        //Add the buttons to either keep or scrap.
        local buttonOptions = ["Explore again", "Back"];
        local buttonFunctions = [
            function(widget, action){
            },
            function(widget, action){
            }
        ];
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
        }

        layoutLine.setSize(winWidth, winHeight);
        layoutLine.setPosition(0, 0);
        layoutLine.layout();
    }

    function wrapBulletText_(text){
        return "    • " + text + "\n";
    }
    function getTextForExploration(data){
        local outString = "Exploration completed in 1:24 minutes.\n";
        outString += format(wrapBulletText_("Found %i items"), data.totalFoundItems);
        outString += format(wrapBulletText_("Found %i places"), data.totalDiscoveredPlaces);
        outString += format(wrapBulletText_("Encountered %i enemies"), data.totalEncountered);
        outString += format(wrapBulletText_("Defeated %i enemies"), data.totalDefeated);

        return outString;
    }
}