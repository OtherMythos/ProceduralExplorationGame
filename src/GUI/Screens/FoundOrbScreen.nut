enum FoundOrbScreenComponents{
    NONE,
    TITLE,
    DESCRIPTION,
    BUTTON,

    MAX
};

local FoundOrbScreenStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(FoundOrbScreenComponents.MAX);
};

{
    FoundOrbScreenStateMachine.mStates_[FoundOrbScreenComponents.TITLE] = class extends ::Util.State{
        mTotalCount_ = 20;
        mNextState_ = FoundOrbScreenComponents.DESCRIPTION;
        mStartPos_ = null;
        mStartSize_ = null;
        function start(data){
            local title = data.components[FoundOrbScreenComponents.TITLE];
            title.setColour(ColourValue(1, 1, 1, 0));
            mStartPos_ = title.getCentre();
            mStartSize_ = title.getDefaultFontSize();

            data.components[FoundOrbScreenComponents.BUTTON].setColour(ColourValue(1, 1, 1, 0));
            data.components[FoundOrbScreenComponents.BUTTON].setTextColour(ColourValue(1, 1, 1, 0));
            data.components[FoundOrbScreenComponents.DESCRIPTION].setTextColour(ColourValue(1, 1, 1, 0));
        }
        function update(p, data){
            local title = data.components[FoundOrbScreenComponents.TITLE];
            local animAmount = ::calculateSimpleAnimation(0.0, 1.0, p);
            title.setColour(ColourValue(1, 1, 1, animAmount));
            //title.setDefaultFontSize(::calculateSimpleAnimation(mStartSize_ - 10, mStartSize_, p));
            local animStart = mStartPos_.copy();
            animStart.y -= 10;
            title.setCentre(::calculateSimpleAnimation(animStart, mStartPos_, p));
            title.setOrientation(::calculateSimpleAnimation(PI * -0.1, PI * -0.01, p));
            //title.setText("You Died!");
        }
    };
    FoundOrbScreenStateMachine.mStates_[FoundOrbScreenComponents.DESCRIPTION] = class extends ::Util.State{
        mTotalCount_ = 20;
        mNextState_ = FoundOrbScreenComponents.BUTTON;
        function start(data){
        }
        function update(p, data){
            local button = data.components[FoundOrbScreenComponents.DESCRIPTION];
            data.components[FoundOrbScreenComponents.DESCRIPTION].setTextColour(1, 1, 1, p);
        }
    };
    FoundOrbScreenStateMachine.mStates_[FoundOrbScreenComponents.BUTTON] = class extends ::Util.State{
        mTotalCount_ = 20;
        function start(data){
        }
        function update(p, data){
            local button = data.components[FoundOrbScreenComponents.BUTTON];
            local animCol = ColourValue(1, 1, 1, p);
            button.setColour(animCol);
            data.components[FoundOrbScreenComponents.BUTTON].setTextColour(animCol);
        }
    };

}

::ScreenManager.Screens[Screen.FOUND_ORB_SCREEN] = class extends ::Screen{

    mStateMachine_ = null;

    mScreenComponents_ = null;

    function setup(data){

        mScreenComponents_ = {};

        local orbData = ::Orbs[data.orbId];

        local winWidth = ::drawable.x;
        local winHeight = ::drawable.y;
        local insets = _window.getScreenSafeAreaInsets();

        mWindow_ = _gui.createWindow("FoundOrbScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setVisualsEnabled(false);

        local title = mWindow_.createLabel();
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setSize(winWidth, title.getSize().y);
        title.setText("Orb found!");
        ::calculateFontWidth_(title, winWidth * 0.95);
        title.setCentre(winWidth / 2, 0);
        title.setPosition(title.getPosition().x, insets.top);
        title.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
        mScreenComponents_[FoundOrbScreenComponents.TITLE] <- title;

        local description = mWindow_.createLabel();
        description.setDefaultFontSize(description.getDefaultFontSize() * 1.5);
        description.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        description.setText(orbData.getDescription());
        description.sizeToFit(::drawable.x * 0.9);
        description.setSize(winWidth, description.getSize().y);
        description.setCentre(winWidth / 2, 0);
        description.setPosition(description.getPosition().x, title.getPosition().y + title.getSize().y);
        description.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
        mScreenComponents_[FoundOrbScreenComponents.DESCRIPTION] <- description;

        local button = mWindow_.createButton();
        button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
        button.setText("Claim");
        button.attachListenerForEvent(function(widget, action){
            ::ScreenManager.queueTransition(null, null, mLayerIdx);
            ::Base.mExplorationLogic.unPauseExploration();
        }, _GUI_ACTION_PRESSED, this);
        button.setExpandHorizontal(true);
        button.setMinSize(0, 100);
        button.setSize(winWidth * 0.9, 100);
        button.setPosition(winWidth * 0.05, winHeight - 100 - winWidth * 0.05 - insets.bottom);
        //layoutLine.addCell(button);

        mScreenComponents_[FoundOrbScreenComponents.BUTTON] <- button;

        mStateMachine_ = FoundOrbScreenStateMachine({"components": mScreenComponents_});
        mStateMachine_.setState(FoundOrbScreenComponents.TITLE);

        _window.grabCursor(false);
    }

    function update(){
        mStateMachine_.update();
    }

    function shutdown(){
        base.shutdown();

        _event.transmit(Event.EXPLORATION_SCREEN_HIDE_WIDGETS_FINISHED, null);
    }
};