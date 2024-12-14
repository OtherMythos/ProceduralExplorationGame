::GuiWidgets.ExplorationDiscoverLevelBarWidget <- class{

    mLabel_ = null;
    mBar_ = null;

    constructor(parent){
        mLabel_ = parent.createLabel();
        mLabel_.setText("test");

        mBar_ = ::GuiWidgets.TwoBarProgressBar(parent);
        mBar_.setPercentage(0);
        mBar_.setSecondaryPercentage(0);
        mBar_.setSize(200, 40);
    }

    function addToLayout(layout){
        layout.addCell(mLabel_);
        mBar_.addToLayout(layout);
    }

    function setLabel(text){
        mLabel_.setText(text);
    }

    function setCounter(current, total){
        mBar_.setLabel(format("%i/%i", current, total));
        mBar_.setLabelShadow(ColourValue(0, 0, 0), Vec2(2, 2));
    }

    function notifyLayout(){
        mBar_.notifyLayout();
    }

    function setSecondaryPercentage(percentage){
        mBar_.setSecondaryPercentage(percentage);
    }
    function setPercentage(percentage){
        mBar_.setPercentage(percentage);
    }
    function setText(text){
        mLabel_.setText(text);
    }

};