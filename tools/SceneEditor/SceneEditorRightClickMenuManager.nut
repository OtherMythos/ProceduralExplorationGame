::SceneEditorRightClickMenuManager <- class{

    mEntryId_ = null;
    mSceneTree_ = null;

    constructor(entryId, sceneTree){
        mEntryId_ = entryId;
        mSceneTree_ = sceneTree;

        local rightClickMenu = ::guiFrameworkBase.createToolbarMenu([
            ["Delete", deleteFunction.bindenv(this)]
        ], Vec2(_input.getMouseX(), _input.getMouseY()));

    }

    function deleteFunction(){
        printf("Deleting entry %i", mEntryId_);
        mSceneTree_.deleteCurrentSelection();
    }



};