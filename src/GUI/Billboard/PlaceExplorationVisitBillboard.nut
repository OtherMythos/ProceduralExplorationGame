::BillboardManager.PlaceExplorationVisitBillboard <- class extends ::BillboardManager.Billboard{

    constructor(parent, mask){
        base.constructor(parent, mask);
        local button = parent.createButton();
        button.setText("Visit");

        button.attachListenerForEvent(function(widget, action){
            //::Base.mExplorationLogic.gatewayEndExploration();
            local worldInstance = ::Base.mExplorationLogic.createWorldInstance(WorldTypes.VISITED_LOCATION_WORLD);
            ::Base.mExplorationLogic.pushWorld(worldInstance);
        }, _GUI_ACTION_PRESSED, this);

        button.setZOrder(BillboardZOrder.BUTTON);

        mPanel_ = button;
    }


}