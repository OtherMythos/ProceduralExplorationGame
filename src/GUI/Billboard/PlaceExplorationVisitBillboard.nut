::BillboardManager.PlaceExplorationVisitBillboard <- class extends ::BillboardManager.Billboard{

    constructor(parent){
        local button = parent.createButton();
        button.setText("Visit");

        button.attachListenerForEvent(function(widget, action){
            //::Base.mExplorationLogic.gatewayEndExploration();
            ::Base.mExplorationLogic.pushWorld(ProceduralDungeonWorld());
            //pushWorld(ProceduralDungeonWorld());
        }, _GUI_ACTION_PRESSED, this);

        button.setZOrder(BillboardZOrder.BUTTON);

        mPanel_ = button;
    }


}