::ScreenManager.Screens[Screen.STORY_CONTENT_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mLogicInterface_ = null;

    function setup(data){
        mLogicInterface_ = data.logic;
        mLogicInterface_.setGuiObject(this);

        _event.subscribe(Event.STORY_CONTENT_FINISHED, receiveStoryContentFinished, this);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Story stuff for " + ::Places.placeToName(mLogicInterface_.mPlace_), false);
        title.sizeToFit(_window.getWidth() * 0.9);
        title.setExpandHorizontal(true);
    }

    function update(){
        mLogicInterface_.tickUpdate();
    }

    function shutdown(){
        base.shutdown();
        _event.unsubscribe(Event.STORY_CONTENT_FINISHED, receiveStoryContentFinished, this);
    }

    function receiveStoryContentFinished(id, data){
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
    }
};