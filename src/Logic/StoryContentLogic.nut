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
    }

    function tickUpdate(){

    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }
};