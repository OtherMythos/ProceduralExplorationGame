::BillboardManager.SpokenTextBillboard <- class extends ::BillboardManager.Billboard{

    constructor(text, parent, mask){
        base.constructor(parent, mask);
        local label = parent.createLabel();
        label.setText(text);
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mPanel_ = label;

        mPanel_.setZOrder(BillboardZOrder.PLACE_DESCRIPTION);
    }

    function setText(text){
        mPanel_.setText(text);
    }

};
