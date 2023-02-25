::ExplorationGuiAnimation <- class{

    mData_ = null;
    mWidget_ = null;

    mCount_ = 0;
    mTotalCount_ = 20;

    constructor(widget, data){
        mWidget_ = widget;
        mData_ = data;
    }

    function start(){
        if(mData_.start == null){
            mWidget_.notifyStationary();
        }
    }

    function update(){
        performBasicArrival();
    }

    function performBasicArrival(){
        mCount_++;
        if(mCount_ == mTotalCount_){
            //Trigger the object arrival animation.
            local buttonCentre = mWidget_.getCentre();
            local size = mWidget_.getSize() / 2;

            local worldPos = ::EffectManager.getWorldPositionForWindowPos(buttonCentre);
            local worldPosExtends = ::EffectManager.getWorldPositionForWindowPos(buttonCentre + size);

            ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.FOUND_ITEM_EFFECT, {"centre": worldPos, "extents": worldPosExtends}));

            //Start the idle animation as well.
            ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.FOUND_ITEM_IDLE_EFFECT, {"centre": worldPos, "extents": worldPosExtends}));

            mWidget_.notifyStationary();
        }
        if(mCount_ > mTotalCount_ || mData_.start == null){
            mCount_--;
            performBasicIdle();
            return;
        }
        local currentPercentage = mCount_.tofloat() / mTotalCount_.tofloat()
        local start = mData_.start;
        local end = mData_.end - mData_.start;

        local scaleAmount = 0.8
        local sizerPercentage = (1 - scaleAmount) + scaleAmount * currentPercentage;
        local buttonSize = mData_.endSize * sizerPercentage;
        mWidget_.setSize(buttonSize);

        local c1 = 1.70158;
        local c2 = c1 * 1.525;
        
        local x = currentPercentage;
        local val = x < 0.5
          ? (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
          : (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;

        mWidget_.setCentre(start + end * val);
    }

    function performBasicIdle(){
        mCount_+=0.1;
        local anim = fabs(sin(mCount_));
        local percentage = 0.98 + 0.02 * anim;
        mWidget_.setSize(mData_.endSize * percentage);
        mWidget_.setCentre(mData_.end)
        mWidget_.updateIconOrientation();
    }
}