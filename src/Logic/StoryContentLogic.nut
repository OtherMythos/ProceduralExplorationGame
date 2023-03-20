/**
 * Logic interface for story.
 *
 */
::StoryContentLogic <- class{

    mGui_ = null;
    mPlace_ = PlaceId.NONE;

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
            case PlaceId.HAUNTED_WELL:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 0);
                break;
            }
            case PlaceId.DARK_CAVE:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 1);
                break;
            }
            case PlaceId.GOBLIN_VILLAGE:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 2);
                break;
            }
            case PlaceId.WIND_SWEPT_BEACH:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 3);
                break;
            }
            case PlaceId.ROTHERFORD:{
                ::Base.mDialogManager.beginExecuting("res://assets/dialog/test.dialog", 4);
                break;
            }
            default:{
                assert(false);
            }
        }
    }
};