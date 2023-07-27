function start(){
    _doFile("res://sceneEditorFramework/SceneEditorBase.nut");

    ::Base.setup();
}

function update(){
    ::Base.update();
}

function end(){

}

::Base <- {

    mEditorBase = null
    mParentNode = null

    function setup(){
        mEditorBase = ::SceneEditorFramework.Base();

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local sceneTree = mEditorBase.loadSceneTree(mParentNode, "/Users/edward/Documents/turnBasedGame/assets/maps/testVillage/scene.avscene");
        mEditorBase.setActiveSceneTree(sceneTree);
        sceneTree.debugPrint();
    }

    function update(){

    }

};