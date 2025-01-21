::SceneEditorFramework.Actions[SceneEditorFramework_Action.USER_1] = class extends ::SceneEditorFramework.Action{

    mParentObj_ = null;
    mOldValues_ = null;
    mNewValues_ = null;

    mCurrentAction_ = null;

    constructor(parentObj){
        mParentObj_ = parentObj;
        mOldValues_ = {};
        mNewValues_ = {};
    }

    function populateForCoord(x, y, oldValue, newValue){
        local coord = (x << 32) | y;
        if(!mOldValues_.rawin(coord)){
            mOldValues_.rawset(coord, oldValue);
        }
        mNewValues_.rawset(coord, newValue);
    }

    #Override
    function performAction(){
        perform_(mNewValues_);
    }

    #Override
    function performAntiAction(){
        perform_(mOldValues_);
    }

    function perform_(targetData){
        foreach(c,i in targetData){
            local x = (c >> 32) & 0xFFFFFFFF;
            local y = c & 0xFFFFFFFF;

            mParentObj_.setTileToGrid_(x, y, i);
        }
    }
};
