::BillboardManager.Billboard <- class{

    mPanel_ = null;
    mSize_ = null;

    constructor(parent){
    }

    function destroy(){

    }

    function posVisible(pos){
        return true;
    }

    function setPosition(pos){
        mPanel_.setPosition(pos);
    }

}