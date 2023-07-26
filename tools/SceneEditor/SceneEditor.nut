function start(){
    _doFile("res://sceneEditorFramework/SceneEditorBase.nut");


}

function update(){

}

function end(){

}

::Base <- {

    mEditorBase = null

    function setup(){
        mEditorBase = ::SceneEditorFramework.Base();

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local sceneTree = mEditorBase.loadSceneTree(mParentNode, "path");
        mEditorBase.setActiveSceneTree(sceneTree);
    }

    function update(){

    }

};