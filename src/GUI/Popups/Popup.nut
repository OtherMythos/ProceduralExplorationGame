::Popup <- class{
    mPopupData_ = null;
    mPopupWin_ = null;
    mPopupSize_ = null;
    mPopupId_ = null;

    mLifespan = 100;
    mForceSingleInstance = false;

    constructor(popupData, id){
        mPopupData_ = popupData;
        mPopupId_ = id;
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
        local win = _gui.createWindow();
        win.setSize(_window.getWidth(), _window.getHeight());
        win.setVisualsEnabled(false);

        return win;
    }

    function setZOrder(order){
        mPopupWin_.setZOrder(order);
    }
};