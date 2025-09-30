::GuiWidgets.GameplayProgressBar <- class extends ::GuiWidgets.ProgressBar{
    BACKGROUND_COLOUR = ColourValue(0.05, 0.05, 0.05, 0.8);
    BAR_LEVEL_1 = ColourValue(0.9, 0.1, 0.1, 1.0);
    BAR_LEVEL_2 = ColourValue(0.8, 0.6, 0.2, 1.0);

    function getDatablock(level){
        if(level < 0){
            return BACKGROUND_COLOUR;
        }
        switch(level){
            case 1:
                return BAR_LEVEL_2;
            case 0:
            default:
                return BAR_LEVEL_1;
        }
    }

    function setLevel(level){
        local target = getDatablock(level);
        local background = getDatablock(level-1);
        mChildBar_.setColour(target);
        mParentContainer_.setColour(background);
    }
};