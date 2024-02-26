::PopupManager.Popups[Popup.SINGLE_TEXT] = class extends ::Popup{

    mTotalFadeIn_ = 10;
    mFadeInTimer_ = 0;

    mLabel_ = null;

    function setup(data){
        mLifespan = data.lifespan;
        mTotalFadeIn_ = data.fadeInTime;
        mFadeInTimer_ = data.fadeInTime;

        mPopupWin_ = _gui.createWindow();
        mPopupWin_.setZOrder(150);
        mPopupWin_.setVisualsEnabled(false);
        mPopupWin_.setConsumeCursor(false);
        mPopupWin_.setSkinPack("WindowSkinNoBorder");


        local label = mPopupWin_.createLabel();
        label.setDefaultFontSize(label.getDefaultFontSize() * data.fontMultiplier);
        label.setText(data.text);
        label.setCentre(data.posX, data.posY);
        mLabel_ = label;

        setSize(_window.getSize());
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

        local data = mPopupData_.data;
        local pos = Vec2(data.posX, data.posY);
        pos += Vec2(0, currentPercentage * 10);
        mLabel_.setCentre(pos);

        mFadeInTimer_--;
        return false;
    }

    function setSize(size){
        mPopupSize_ = size;
        mPopupWin_.setSize(mPopupSize_);
    }

};