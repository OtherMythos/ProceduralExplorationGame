::BillboardManager.GatewayExplorationEndBillboard <- class extends ::BillboardManager.Billboard{

    constructor(parent, mask){
        base.constructor(parent, mask);
        local button = parent.createButton();
        button.setText("End exploration");

        button.attachListenerForEvent(function(widget, action){
            ::Base.mExplorationLogic.gatewayEndExploration();
        }, _GUI_ACTION_PRESSED, this);

        button.setZOrder(BillboardZOrder.BUTTON);

        mPanel_ = button;
    }


}