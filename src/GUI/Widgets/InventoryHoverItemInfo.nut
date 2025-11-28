::InventoryHoverItemInfo <- class{
    mHoverWin_ = null;

    mTitleLabel_ = null;
    mDescriptionLabel_ = null;
    mStatsLabel_ = null;

    mActive_ = false;

    constructor(overlayWindow){
        if(overlayWindow == null){
            mHoverWin_ = _gui.createWindow("InventoryHoverInfoWindow");
        }else{
            mHoverWin_ = overlayWindow.createWindow("InventoryHoverInfoWindow");
        }
        mHoverWin_.setSize(400, 200);
        mHoverWin_.setHidden(true);
        mHoverWin_.setPosition(0, 0);
        mHoverWin_.setZOrder(200);
        mHoverWin_.setClickable(false);
        mHoverWin_.setKeyboardNavigable(false);

        local layout = _gui.createLayoutLine();
        mTitleLabel_ = mHoverWin_.createLabel();
        mTitleLabel_.setText(" ");
        layout.addCell(mTitleLabel_);

        mDescriptionLabel_ = mHoverWin_.createLabel();
        mDescriptionLabel_.setText(" ");
        layout.addCell(mDescriptionLabel_);

        mStatsLabel_ = mHoverWin_.createLabel();
        mStatsLabel_.setText(" ");
        layout.addCell(mStatsLabel_);

        layout.layout();
    }

    function update(){
        if(mActive_){
            local xx = _input.getMouseX().tofloat() / ::drawable.x.tofloat();
            local yy = _input.getMouseY().tofloat() / ::drawable.y.tofloat();
            setPosition((::drawable.x*xx), (::drawable.y*yy));
        }
    }

    function destroy(){
        _gui.destroy(mHoverWin_);
    }

    function setVisible(vis){
        mActive_ = vis;
        mHoverWin_.setVisible(vis);
    }

    function setPosition(x, y){
        mHoverWin_.setPosition(x, y);
    }

    function getSize(){
        return mHoverWin_.getSize();
    }

    function setItem(item){
        mTitleLabel_.setText(item.getName());
        local descText = item.getDescription();

        mDescriptionLabel_.setText(descText);

        local stats = item.toStats();
        local richTextDesc = stats.getDescriptionWithRichText();
        mStatsLabel_.setText(richTextDesc[0]);
        mStatsLabel_.setRichText(richTextDesc[1]);

        mHoverWin_.setSize(mHoverWin_.calculateChildrenSize());
    }
};