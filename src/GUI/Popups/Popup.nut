enum PopupAnimType{
    LINEAR,

    EASE_IN_SINE,
    EASE_OUT_SINE,
    EASE_IN_OUT_SINE,
    EASE_IN_OUT_SINE,
    EASE_IN_QUAD,
    EASE_OUT_QUAD,
    EASE_IN_OUT_QUAD,

    EASE_OUT_QUART
};

::Popup <- class{
    mPopupData_ = null;
    mPopupWin_ = null;
    mPopupSize_ = null;
    mPopupId_ = null;

    mLifespan = 100;
    mTotalLifespan = 100;
    mForceSingleInstance = false;

    constructor(popupData, id){
        mPopupData_ = popupData;
        mPopupId_ = id;
    }

    function setLifespan(lifespan){
        mLifespan = lifespan;
        mTotalLifespan = lifespan;
    }

    function percentageForFramesAnim(start, end, anim){
        local val = percentageForFrames(start, end);
        if(anim == PopupAnimType.EASE_IN_SINE){
            val = 1 - cos((val * PI) / 2);
        }
        else if(anim == PopupAnimType.EASE_OUT_SINE){
            val = sin((val * PI) / 2);
        }
        else if(anim == PopupAnimType.EASE_IN_OUT_SINE){
            val = -(cos(PI * x) - 1) / 2;
        }
        else if(anim == PopupAnimType.EASE_IN_QUAD){
            val = val * val;
        }
        else if(anim == PopupAnimType.EASE_OUT_QUAD){
            val = 1 - (1 - val) * (1 - val);
        }
        else if(anim == PopupAnimType.EASE_IN_OUT_QUAD){
            val = val < 0.5 ? 2 * val * val : 1 - pow(-2 * val + 2, 2) / 2;
        }

        else if(anim == PopupAnimType.EASE_OUT_QUART){
            val = 1 - pow(1 - val, 8);
        }

        return val;
    }

    function percentageForFrames(start, end){
        local currentNegated = mTotalLifespan - mLifespan;
        if(currentNegated < start) return 0.0;
        if(currentNegated >= end) return 1.0;

        return ((currentNegated-start).tofloat() / (end-start).tofloat());
    }

    function getId(){
        return mPopupId_;
    }

    function createPopupBase_(){

    }

    function update(){

    }

    function getPopupData(){
        return mPopupData_;
    }

    function tickTimer(){
        mLifespan--;
        return mLifespan > 0;
    }

    function shutdown(){
        _gui.destroy(mPopupWin_);
    }

    function createBackgroundScreen_(){
        local win = _gui.createWindow("Popup");
        win.setSize(_window.getWidth(), _window.getHeight());
        win.setVisualsEnabled(false);

        return win;
    }

    function setZOrder(order){
        mPopupWin_.setZOrder(order);
    }
};