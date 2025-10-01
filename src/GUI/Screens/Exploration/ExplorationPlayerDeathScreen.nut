enum ExplorationPlayerDeathScreenComponents{
    NONE,
    TITLE,
    BUTTON,

    MAX
};

local ExplorationPlayerDeathScreenAnimStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(ExplorationPlayerDeathScreenComponents.MAX);
};

{
    ExplorationPlayerDeathScreenAnimStateMachine.mStates_[ExplorationPlayerDeathScreenComponents.TITLE] = class extends ::Util.State{
        mTotalCount_ = 20;
        mNextState_ = ExplorationPlayerDeathScreenComponents.BUTTON;
        mStartPos_ = null;
        mStartSize_ = null;
        function start(data){
            local title = data.components[ExplorationPlayerDeathScreenComponents.TITLE];
            title.setColour(ColourValue(1, 1, 1, 0));
            mStartPos_ = title.getCentre();
            mStartSize_ = title.getDefaultFontSize();

            data.components[ExplorationPlayerDeathScreenComponents.BUTTON].setColour(ColourValue(1, 1, 1, 0));
            data.components[ExplorationPlayerDeathScreenComponents.BUTTON].setTextColour(ColourValue(1, 1, 1, 0));
        }
        function update(p, data){
            local title = data.components[ExplorationPlayerDeathScreenComponents.TITLE];
            local animAmount = ::calculateSimpleAnimation(0.0, 1.0, p);
            title.setColour(ColourValue(1, 1, 1, animAmount));
            title.setDefaultFontSize(::calculateSimpleAnimation(mStartSize_ - 10, mStartSize_, p));
            local animStart = mStartPos_.copy();
            animStart.y -= 10;
            title.setCentre(::calculateSimpleAnimation(animStart, mStartPos_, p));
            title.setOrientation(::calculateSimpleAnimation(PI * -0.1, PI * -0.01, p));
            //title.setText("You Died!");
        }
    };
    ExplorationPlayerDeathScreenAnimStateMachine.mStates_[ExplorationPlayerDeathScreenComponents.BUTTON] = class extends ::Util.State{
        mTotalCount_ = 20;
        function start(data){
        }
        function update(p, data){
            local button = data.components[ExplorationPlayerDeathScreenComponents.BUTTON];
            local animCol = ColourValue(1, 1, 1, p);
            button.setColour(animCol);
            data.components[ExplorationPlayerDeathScreenComponents.BUTTON].setTextColour(animCol);
        }
    };

}

::ScreenManager.Screens[Screen.PLAYER_DEATH_SCREEN] = class extends ::Screen{

    mStateMachine_ = null;

    mScreenComponents_ = null;

    buttonOptions = ["Return to menu"];
    buttonFunctions = [
        function(widget, action){
            ::ScreenManager.queueTransition(null, null, mLayerIdx);
            ::ScreenManager.queueTransition(::BaseHelperFunctions.getTargetGameplayMainMenu());
            ::Base.mExplorationLogic.shutdown();
        }
    ];

    function setup(data){

        mScreenComponents_ = {};

        local winWidth = ::drawable.x;
        local winHeight = ::drawable.y;

        //Create a window to block inputs for when the popup appears.
        //createBackgroundScreen_();

        mWindow_ = _gui.createWindow("PlayerDeathScreen");
        //mWindow_.setSize(winWidth, winHeight);
        //mWindow_.setPosition(::drawable.x * 0.1, ::drawable.y * 0.1);
        mWindow_.setPosition(::Vec2_ZERO);
        mWindow_.setSize(::drawable);
        //mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setVisualsEnabled(false);

        //local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 4);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("You Died!");
        title.setSize(winWidth, title.getSize().y);
        mScreenComponents_[ExplorationPlayerDeathScreenComponents.TITLE] <- title;
        //title.setOrientation(PI * -0.01);
        //title.setTextColour(0, 0, 0, 1);
        //layoutLine.addCell(title);

        local insets = _window.getScreenSafeAreaInsets();

        //Add the buttons.
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            button.setSize(winWidth * 0.9, 100);
            button.setPosition(winWidth * 0.05, winHeight - 100 - winWidth * 0.05 - insets.bottom);
            //layoutLine.addCell(button);

            mScreenComponents_[ExplorationPlayerDeathScreenComponents.BUTTON] <- button;
        }

        //layoutLine.setSize(winWidth * 0.9, winHeight);
        //layoutLine.setPosition(winWidth * 0.05, ::drawable.y - mScreenComponents_[ExplorationPlayerDeathScreenComponents.BUTTON].getSize().y);
        //layoutLine.layout();

        mStateMachine_ = ExplorationPlayerDeathScreenAnimStateMachine({"components": mScreenComponents_});
        mStateMachine_.setState(ExplorationPlayerDeathScreenComponents.TITLE);
    }

    function update(){
        mStateMachine_.update();
    }
}