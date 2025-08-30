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

    function attachListenerForEvent(func, id, context){
        mButton_.attachListenerForEvent(func, id, context);
    }

};