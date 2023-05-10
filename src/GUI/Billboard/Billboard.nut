::BillboardManager.Billboard <- class{

    mPanel_ = null;

    constructor(parent){
        local panel = parent.createPanel();
        panel.setHidden(false);
        panel.setSize(10, 10);

        mPanel_ = panel;
    }

    function posVisible(pos){
        return true;
    }

    function setPosition(pos){
        mPanel_.setPosition(pos);
    }

}