::BillboardManager.PercentageEncounterBillboard <- class extends ::BillboardManager.Billboard{

    constructor(spoilsComponent, parent, mask){
        base.constructor(parent, mask);
        local label = parent.createLabel();
        label.setText(::PercentageEncounterHelper.getLabelForPercentageDataComponent(spoilsComponent));
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mPanel_ = label;

        mPanel_.setZOrder(BillboardZOrder.HEALTH_BAR);
    }

}