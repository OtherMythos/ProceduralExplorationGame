::BillboardManager.HealthBarBillboard <- class extends ::BillboardManager.Billboard{

    constructor(parent, mask){
        base.constructor(parent, mask);
        local panel = ::GuiWidgets.ProgressBar(parent);
        panel.setBorder(2);
        //panel.setHidden(false);
        panel.setSize(80, 10);
        mPanel_ = panel;

        setPercentage(1.0);

        panel.setZOrder(BillboardZOrder.HEALTH_BAR);
    }

    function destroy(){
        mPanel_.destroy();
    }

    function setPosition(pos){
        mPanel_.setCentre(pos.x, pos.y);
    }

    function setPercentage(percentage){
        mPanel_.setPercentage(percentage);
    }

}