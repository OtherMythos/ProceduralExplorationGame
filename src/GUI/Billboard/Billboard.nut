enum BillboardZOrder{
    HEALTH_BAR = 70,
    BUTTON = 75
};

::BillboardManager.Billboard <- class{

    mPanel_ = null;
    mSize_ = null;
    mVisible_ = true;

    constructor(parent){
    }

    function destroy(){
        _gui.destroy(mPanel_);
    }

    function posVisible(pos){
        return true;
    }

    function setPosition(pos){
        mPanel_.setCentre(pos);
    }

    function setVisible(visible){
        mVisible_ = visible;
        mPanel_.setVisible(visible);
    }

}