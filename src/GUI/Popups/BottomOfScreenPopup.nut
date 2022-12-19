::PopupManager.Popups[Popup.BOTTOM_OF_SCREEN] = class extends ::Popup{

    mTotalFadeIn_ = 10;
    mFadeInTimer_ = 0;

    function setup(data){
        mLifespan = 150;
        mFadeInTimer_ = mTotalFadeIn_;

        mPopupWin_ = _gui.createWindow();
        mPopupWin_.setZOrder(150);

        local label = mPopupWin_.createLabel();
        label.setText("A popup");

        setSize(Vec2(_window.getWidth() * 0.9, 200));
    }

    function update(){
        local doneFadeIn = animateFadeIn();
        if(doneFadeIn){
            return tickTimer();
        }
        return true;
    }

    function animateFadeIn(){
        if(mFadeInTimer_ <= 0) return true;

        //Fade in opacity.
        local currentPercentage = mFadeInTimer_.tofloat() / mTotalFadeIn_.tofloat();
        mPopupWin_.setColour(ColourValue(1, 1, 1, 1 - currentPercentage));

        //Fade in position.
        local pos = getIntendedPosition();
        pos += Vec2(0, currentPercentage * 10);
        mPopupWin_.setPosition(pos);

        mFadeInTimer_--;
        return false;
    }

    function setSize(size){
        mPopupSize_ = size;
        mPopupWin_.setSize(mPopupSize_);
    }

    function getIntendedPosition(){
        local winWidth = _window.getWidth();
        return Vec2(winWidth * 0.05, _window.getHeight() - mPopupSize_.y - winWidth * 0.05);
    }

};