::SceneEditorRightClickMenuManager <- class{

    mEntryId_ = null;
    mSceneTree_ = null;

    constructor(entryId, sceneTree){
        mEntryId_ = entryId;
        mSceneTree_ = sceneTree;

        local rightClickMenu = ::guiFrameworkBase.createToolbarMenu([
            ["Delete", deleteFunction.bindenv(this)],
            ["Rename", renameFunction.bindenv(this)],
        ], Vec2(_input.getMouseX(), _input.getMouseY()));

    }

    function deleteFunction(){
        printf("Deleting entry %i", mEntryId_);
        mSceneTree_.deleteCurrentSelection();
    }

    function renameFunction(){
        printf("Renaming entry %i", mEntryId_);
        //mSceneTree_.renameCurrentSelection();

        local constructionData = [
            [EditorGUIFramework_PopupConstructionData.DESCRIPTION, "Enter new node name"],
            [EditorGUIFramework_PopupConstructionData.CLOSE_BUTTON, "Close"],
            [EditorGUIFramework_PopupConstructionData.ACCEPT_BUTTON, "Accept"],
            [EditorGUIFramework_PopupConstructionData.INPUT_TEXT, ""],
        ];
        guiFrameworkBase.createPopup(123, "Rename", constructionData, function(popup, widget){
            local text = popup.mInputText_.getText();
            mSceneTree_.renameCurrentSelection(text);
        }.bindenv(this));
    }



};