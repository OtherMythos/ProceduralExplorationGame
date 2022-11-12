::EncounterPopupScreen <- class extends ::Screen{

    mWindow_ = null;

    mCount_ = 0;
    mBackgroundColour_ = false;

    constructor(){

    }

    function setup(){
        local winWidth = _window.getWidth() * 0.8;

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(winWidth, _window.getHeight() * 0.333);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.333);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Encounter");
        title.setSize(winWidth, title.getSize().y);
        title.setTextColour(0, 0, 0, 1);

        mWindow_.setSize(winWidth, title.getSize().y + 10*2);

        setBackground(mBackgroundColour_);
    }

    function update(){
        mCount_++;
        if(mCount_ % 50 == 0){
            mBackgroundColour_ = !mBackgroundColour_;
            setBackground(mBackgroundColour_);
        }
    }

    function setBackground(background){
        if(background) mWindow_.setDatablock("gui/encounterWindowFirstColour");
        else mWindow_.setDatablock("gui/encounterWindowSecondColour");
    }

    function shutdown(){
        _gui.destroy(mWindow_);
    }
}