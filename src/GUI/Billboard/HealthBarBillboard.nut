::BillboardManager.HealthBarBillboard <- class extends ::BillboardManager.Billboard{

    constructor(parent, mask, totalHealth){
        base.constructor(parent, mask);
        local panel = ::GuiWidgets.GameplayProgressBar(parent);
        panel.setBorder(0);
        //panel.setHidden(false);
        //local width = 2 + ((totalHealth * totalHealth) *0.002);
        local width = 2 + (totalHealth / 2);
        panel.setSize(width.tointeger(), 6);
        mPanel_ = panel;

        setPercentage(1.0);

        panel.setZOrder(BillboardZOrder.HEALTH_BAR);

        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            mPanel_.setVisible(false);
        }
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