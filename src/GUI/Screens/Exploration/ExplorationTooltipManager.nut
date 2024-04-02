::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].TooltipManager <- class{

    mParentWin_ = null;
    mLabel_ = null;

    mVisible_ = false;
    mTooltip_ = " ";

    constructor(){
        local window = _gui.createWindow("ExplorationTooltip");
        window.setSize(200, 200);
        window.setZOrder(160);
        window.setVisualsEnabled(false);

        local label = window.createLabel();

        label.setText(mTooltip_);
        label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));

        mParentWin_ = window;
        mLabel_ = label;
    }

    function update(){
        if(!mVisible_) return;
        mParentWin_.setPosition(_input.getMouseX(), _input.getMouseY());
    }

    function setTooltip(tooltip){
        mLabel_.setText(tooltip);
        mTooltip_ = tooltip;
    }

    function setVisible(visible){
        mVisible_ = visible;
        mParentWin_.setHidden(!visible);
    }

};