::SceneEditorFramework.Actions[SceneEditorFramework_Action.USER_2] = class extends ::SceneEditorFramework.Action{

    mEntryId_ = null;
    mOldValue_ = null;
    mNewValue_ = null;

    mCurrentAction_ = null;

    function populate(entryId, oldValue, newValue){
        mEntryId_ = entryId;
        mOldValue_ = oldValue;
        mNewValue_ = newValue;
    }

    #Override
    function performAction(){
        perform_(mNewValue_);
    }

    #Override
    function performAntiAction(){
        perform_(mOldValue_);
    }

    function perform_(targetData){
        local sceneTree = ::Base.mSceneTree;
        //print(mEntryId_);
        local e = sceneTree.getEntryForId(mEntryId_);
        //print(e.nodeType);
        assert(e.data != null);
        e.data.value = targetData;
        sceneTree.regenerateSceneEntry(mEntryId_);
    }
};
