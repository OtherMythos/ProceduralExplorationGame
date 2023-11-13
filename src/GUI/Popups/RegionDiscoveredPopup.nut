::PopupManager.Popups[Popup.REGION_DISCOVERED] = class extends ::Popup{

    mTotalFadeIn_ = 60;
    mFadeInTimer_ = 0;

    mLabel_ = null;

    function setup(data){
        mLifespan = 150;
        mFadeInTimer_ = mTotalFadeIn_;

        mPopupWin_ = _gui.createWindow();
        mPopupWin_.setZOrder(150);
        mPopupWin_.setVisualsEnabled(false);

        local label = mPopupWin_.createLabel();
        label.setDefaultFontSize(label.getDefaultFontSize() * 3);
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setText("Discovered a place");
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mLabel_ = label;

        local targetSize = Vec2(_window.getWidth() * 0.9, 200);
        label.setSize(targetSize)

        setSize(targetSize);
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
        mLabel_.setTextColour(ColourValue(1, 1, 1, 1 - currentPercentage));

        //Fade in position.
        local pos = getIntendedPosition();
        pos += Vec2(currentPercentage * 10, 0);
        mPopupWin_.setPosition(pos);

        mFadeInTimer_--;
        return false;
    }

    function setSize(size){
        mPopupSize_ = size;
        mPopupWin_.setSize(mPopupSize_);
    }

    function getIntendedPosition(){
        return Vec2(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
    }

};