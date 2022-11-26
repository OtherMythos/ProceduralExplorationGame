/**
 * Logic interface for story.
 *
 */
::StoryContentLogic <- class{

    mGui_ = null;
    mPlace_ = Place.NONE;

    constructor(placeId){
        mPlace_ = placeId;

        /**
        Depending on what happens with the place id, there would be different things happening.
        */
       determineStoryContent();
    }

    function tickUpdate(){

    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }

    function determineStoryContent(){
        switch(mPlace_){
            case Place.HAUNTED_WELL:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 0);
                break;
            }
            case Place.DARK_CAVE:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 1);
                break;
            }
            case Place.GOBLIN_VILLAGE:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 2);
                break;
            }
            case Place.WIND_SWEPT_BEACH:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 3);
                break;
            }
        }
    }
};