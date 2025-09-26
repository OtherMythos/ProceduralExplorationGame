::PopupManager.Popups[Popup.REGION_DISCOVERED] = class extends ::Popup{

    mTotalFadeIn_ = 30;
    mFadeInTimer_ = 0;
    mCurrentFontSize_ = 0;

    mLabel_ = null;
    mUnderline_ = null;
    mUnderlineShadow_ = null;
    mUnderlineDatablock_ = null;
    mUnderlineShadowDatablock_ = null;

    function setup(data){
        setLifespan(320);
        mFadeInTimer_ = mTotalFadeIn_;
        mForceSingleInstance = true;

        mPopupWin_ = _gui.createWindow("RegionDiscoveredPopup");
        mPopupWin_.setZOrder(150);
        mPopupWin_.setVisualsEnabled(false);
        mPopupWin_.setConsumeCursor(false);

        if(data.rawin("pos")){
            mPopupWin_.setPosition(data.pos);
        }

        local label = mPopupWin_.createLabel();
        local currentFontSize = label.getDefaultFontSize() * 2;
        label.setDefaultFontSize(currentFontSize);
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setText(getLabelForRegionType(data.biome));
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mLabel_ = label;
        mCurrentFontSize_ = currentFontSize;

        local underline = mPopupWin_.createPanel();
        mUnderlineShadowDatablock_ = ::DatablockManager.quickCloneDatablock("gui/basicTransparent");
        mUnderlineShadowDatablock_.setColour(0, 0, 0, 1);
        underline.setDatablock(mUnderlineShadowDatablock_);
        mUnderlineShadow_ = underline;

        underline = mPopupWin_.createPanel();
        mUnderlineDatablock_ = ::DatablockManager.quickCloneDatablock("gui/basicTransparent");
        mUnderlineDatablock_.setColour(1, 1, 1, 1);
        underline.setDatablock(mUnderlineDatablock_);
        mUnderline_ = underline;

        //local targetSize = Vec2(_window.getWidth() * 0.9, 200);
        local targetSize = Vec2(_window.getWidth(), _window.getHeight());
        label.setSize(targetSize)

        setSize(targetSize);
        mPopupWin_.setHidden(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE));
    }

    function shutdown(){
        base.shutdown();

        _event.transmit(Event.REGION_DISCOVERED_POPUP_FINISHED, null);
    }

    function getLabelForRegionType(biomeData){
        if(biomeData == null){
            return "Discovered a place";
        }
        return "Discovered " + biomeData.getName();
        /*
        if(regionType == RegionType.EXP_FIELDS) return "Discovered the EXP Fields";
        else if(regionType == RegionType.CHERRY_BLOSSOM_FOREST) return "Discovered the Cherry Blossom Forest";
        */
    }

    function update(){
        animateFadeIn();
        local result = tickTimer();

        return result;
    }

    function animateFadeIn(){
        //if(mFadeInTimer_ <= 0) return true;

        //Fade in opacity.
        //local currentPercentage = 1.0-(mFadeInTimer_.tofloat() / mTotalFadeIn_.tofloat());
        local currentPercentage = percentageForFramesAnim(0, 30, PopupAnimType.EASE_OUT_QUART);
        mLabel_.setTextColour(ColourValue(1, 1, 1, currentPercentage));
        mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, currentPercentage), Vec2(2, 2));
        local animVal = 1.0-((pow(1 - currentPercentage, 2)));
        //print("anim val " + (animVal));
        //mLabel_.setDefaultFontSize(mCurrentFontSize_ * animVal);
        mLabel_.sizeToFit(_window.getWidth());

        //Fade in position.
        //local pos = getIntendedPosition();
        //pos = Vec2(0, 500 - (currentPercentage * (20 * (mCurrentFontSize_ * labelOpacity))));
        //local animVal = 1.0-((pow(1 - currentPercentage, 4)));
        local pos = Vec2(_window.getWidth() / 2 - mLabel_.getSize().x / 2 - (20 - animVal * 20), -10);
        mLabel_.setPosition(pos);
        //mLabel_.setCentre(pos);
        //mPopupWin_.setPosition(pos);
        //mLabel_.setPosition(pos);

        local linePercentage = percentageForFramesAnim(0, 300, PopupAnimType.EASE_OUT_QUART);
        local s = mLabel_.getSize();
        local p = mLabel_.getPosition();
        local offset = (mLabel_.getSize().x) * 0.05;
        mUnderline_.setSize((mLabel_.getSize().x + offset * 2) * linePercentage, 4);
        mUnderline_.setPosition(p.x - offset, p.y + s.y*0.9);
        mUnderlineShadow_.setSize(mUnderline_.getSize());
        mUnderlineShadow_.setPosition(mUnderline_.getPosition() + 1);

        local fadeOutPercentage = percentageForFramesAnim(280, 320, PopupAnimType.EASE_OUT_QUART);
        if(fadeOutPercentage > 0){
            mLabel_.setTextColour(1, 1, 1, 1-fadeOutPercentage);
            mUnderlineDatablock_.setColour(1, 1, 1, 1-fadeOutPercentage);
            mUnderlineShadowDatablock_.setColour(0, 0, 0, 1-fadeOutPercentage);
        }

        //mFadeInTimer_--;
        return false;
    }

    function setSize(size){
        mPopupSize_ = size;
        mPopupWin_.setSize(mPopupSize_);
    }

    function getIntendedPosition(){
        return Vec2();
        //return Vec2(_window.getWidth() * 0.05, _window.getHeight() * 0.1);
    }

};