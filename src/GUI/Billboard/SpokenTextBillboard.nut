::BillboardManager.SpokenTextBillboard <- class extends ::BillboardManager.Billboard{

    constructor(text, parent, mask){
        base.constructor(parent, mask);
        local label = parent.createLabel();
        label.setDefaultFontSize(label.getDefaultFontSize() * 0.9);
        label.setDefaultFont(6);
        label.setText(text);
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        label.setTextColour(1, 1, 0.1, 0.9);
        mPanel_ = label;

        mPanel_.setZOrder(BillboardZOrder.PLACE_DESCRIPTION);
    }

    function setText(text){
        mPanel_.setText(text);
    }

};
