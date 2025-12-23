::BillboardManager.PlaceDescriptionBillboard <- class extends ::BillboardManager.Billboard{

    mFramesRemaining_ = 0;
    mTotalFrames_ = 0;

    FADE_IN_FRAMES = 10;
    FULL_OPACITY_FRAMES = 120;
    FADE_OUT_FRAMES = 120;

    MIN_RADIUS = 10;
    MAX_RADIUS = 30;

    constructor(placeName, parent, mask, placeRadius=null){
        base.constructor(parent, mask);
        local label = parent.createLabel();
        label.setText(placeName);
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mPanel_ = label;

        mPanel_.setZOrder(BillboardZOrder.PLACE_DESCRIPTION);

        //Scale label size based on place radius
        if(placeRadius != null){
            local defaultSize = label.getDefaultFontSize();
            local sizeModifier = 1.0;

            if(placeRadius < MIN_RADIUS){
                sizeModifier = 1.0;
            }else if(placeRadius >= MAX_RADIUS){
                sizeModifier = 2.0;
            }else{
                //Interpolate between 1.0 and 2.0 for radii between 10 and 30
                local rangeSize = MAX_RADIUS - MIN_RADIUS;
                local progress = (placeRadius - MIN_RADIUS).tofloat() / rangeSize;
                sizeModifier = 1.0 + progress;
            }

            label.setDefaultFontSize(defaultSize * sizeModifier);
            label.setText(placeName);
        }

        mTotalFrames_ = FADE_IN_FRAMES + FULL_OPACITY_FRAMES + FADE_OUT_FRAMES;
        mFramesRemaining_ = 0;
    }

    function startAnimation(){
        mFramesRemaining_ = mTotalFrames_;
        setVisible(true);
    }

    function update(){
        if(mFramesRemaining_ <= 0) return;

        mFramesRemaining_--;

        local opacity = 1.0;
        if(mFramesRemaining_ > (FULL_OPACITY_FRAMES + FADE_OUT_FRAMES)){
            //Fade in phase
            local fadeInProgress = (FADE_IN_FRAMES - (mFramesRemaining_ - (FULL_OPACITY_FRAMES + FADE_OUT_FRAMES))).tofloat() / FADE_IN_FRAMES;
            opacity = ::Easing.easeInQuad(fadeInProgress);
        }else if(mFramesRemaining_ <= FADE_OUT_FRAMES){
            //Fade out phase
            local fadeProgress = (FADE_OUT_FRAMES - mFramesRemaining_).tofloat() / FADE_OUT_FRAMES;
            opacity = 1.0 - ::Easing.easeOutQuad(fadeProgress);
        }

        mPanel_.setTextColour(1, 1, 1, opacity);

        if(mFramesRemaining_ <= 0){
            setVisible(false);
        }
    }

}
