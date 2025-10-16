::IconButton <- class{

    mButton_ = null;
    mIcon_ = null;

    constructor(window, iconDatablock){
        mButton_ = window.createButton();
        mIcon_ = window.createPanel();
        mIcon_.setClickable(false);
        mIcon_.setDatablock(iconDatablock);
    }

    function setSize(size){
        mButton_.setSize(size);
        mIcon_.setSize(size);
    }

    function setPosition(position){
        mButton_.setPosition(position);
        mIcon_.setPosition(position);
    }

    function getPosition(){
        return mButton_.getPosition();
    }

    function getSize(){
        return mButton_.getSize();
    }

    function attachListenerForEvent(func, id, context){
        mButton_.attachListenerForEvent(func, id, context);
    }

    function setButtonVisualsEnabled(enabled){
        mButton_.setVisualsEnabled(enabled);
    }

    function setVisible(vis){
        mButton_.setVisible(vis);
        mIcon_.setVisible(vis);
    }

    function setColour(colour){
        mIcon_.setColour(colour);
    }

    function setNextWidget(widget, dir){
        mButton_.setNextWidget(widget, dir);
    }

    function setFocus(){
        mButton_.setFocus();
    }

    function getWidget(){
        return mButton_;
    }

    function setZOrder(zOrder){
        mButton_.setZOrder(zOrder);
        mIcon_.setZOrder(zOrder);
    }

};

::IconButtonComplex <- class extends IconButton{

    mData_ = null;
    mLabel_ = null;

    constructor(window, data){
        mData_ = data;
        base.constructor(window, data.icon);

        if(data.rawin("label")){
            mLabel_ = window.createLabel();
            if(data.rawin("labelSizeModifier")){
                mLabel_.setDefaultFontSize(mLabel_.getDefaultFontSize() * data.rawget("labelSizeModifier"));
            }
            mLabel_.setText(data.label);
        }
    }

    function setSize(size){
        base.setSize(size);
        if(mData_.rawin("iconSize")){
            mIcon_.setSize(mData_.rawget("iconSize"));
        }
    }

    function setPosition(pos){
        base.setPosition(pos);
        if(mData_.rawin("iconPosition")){
            mIcon_.setPosition(pos + mData_.rawget("iconPosition"));
        }
        if(mLabel_ != null){
            local labelPos = Vec2();
            if(mData_.rawin("labelPosition")){
                labelPos = mData_.rawget("labelPosition");
            }
            mLabel_.setPosition(pos + labelPos);
        }
    }

};