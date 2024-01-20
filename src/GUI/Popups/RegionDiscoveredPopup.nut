::PopupManager.Popups[Popup.REGION_DISCOVERED] = class extends ::Popup{

    mTotalFadeIn_ = 30;
    mFadeInTimer_ = 0;
    mCurrentFontSize_ = 0;

    mLabel_ = null;

    function setup(regionType){
        mLifespan = 150;
        mFadeInTimer_ = mTotalFadeIn_;
        mForceSingleInstance = true;

        mPopupWin_ = _gui.createWindow();
        mPopupWin_.setZOrder(150);
        mPopupWin_.setVisualsEnabled(false);
        mPopupWin_.setConsumeCursor(false);

        local label = mPopupWin_.createLabel();
        local currentFontSize = label.getDefaultFontSize() * 3;
        label.setDefaultFontSize(currentFontSize);
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setText(getLabelForRegionType(regionType));
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mLabel_ = label;
        mCurrentFontSize_ = currentFontSize;

        //local targetSize = Vec2(_window.getWidth() * 0.9, 200);
        local targetSize = Vec2(_window.getWidth(), _window.getHeight());
        label.setSize(targetSize)

        setSize(targetSize);
    }

    function getLabelForRegionType(regionType){
        if(regionType == RegionType.EXP_FIELDS) return "Discovered the EXP Fields";
        else if(regionType == RegionType.CHERRY_BLOSSOM_FOREST) return "Discovered the Cherry Blossom Forest";

        return "Discovered a place";
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
        local currentPercentage = 1.0-(mFadeInTimer_.tofloat() / mTotalFadeIn_.tofloat());
        mLabel_.setTextColour(ColourValue(1, 1, 1, currentPercentage));
        mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, currentPercentage), Vec2(2, 2));
        local animVal = 1.0-((pow(1 - currentPercentage, 2)));
        //print("anim val " + (animVal));
        mLabel_.setDefaultFontSize(mCurrentFontSize_ * animVal);
        mLabel_.sizeToFit(_window.getWidth());

        //Fade in position.
        //local pos = getIntendedPosition();
        //pos = Vec2(0, 500 - (currentPercentage * (20 * (mCurrentFontSize_ * labelOpacity))));
        local animVal = 1.0-((pow(1 - currentPercentage, 4)));
        local pos = Vec2(_window.getWidth() / 2, 500 - animVal * 200);
        mLabel_.setCentre(pos);
        //mPopupWin_.setPosition(pos);
        //mLabel_.setPosition(pos);

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