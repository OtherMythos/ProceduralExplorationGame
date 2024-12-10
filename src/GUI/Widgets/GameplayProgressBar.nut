::GuiWidgets.GameplayProgressBar <- class extends ::GuiWidgets.ProgressBar{
    BACKGROUND_DATABLOCK = "gui/gameplayProgressBarBackground";
    BAR_DATABLOCK = "gui/gameplayProgressBarLevel1";

    function getDatablock(level){
        if(level < 0){
            return BACKGROUND_DATABLOCK;
        }
        switch(level){
            case 1:
                return "gui/gameplayProgressBarLevel2";
            case 0:
            default:
                return BAR_DATABLOCK;
        }
    }

    function setLevel(level){
        local target = getDatablock(level);
        local background = getDatablock(level-1);
        mChildBar_.setDatablock(target);
        mParentContainer_.setDatablock(background);
    }
};