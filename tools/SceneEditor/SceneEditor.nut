::Base <- {

    mEditorBase = null
    mParentNode = null

    function setup(){
        fpsCamera.start(Vec3(10, 10, 20), Vec3(245.45, -15.9, 0));

        mEditorBase = ::SceneEditorFramework.Base();

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local sceneTree = mEditorBase.loadSceneTree(mParentNode, "/Users/edward/Documents/turnBasedGame/assets/maps/testVillage/scene.avscene");
        mEditorBase.setActiveSceneTree(sceneTree);
        sceneTree.debugPrint();

        local sceneTreeWindow = _gui.createWindow();
        sceneTreeWindow.setSize(500, 500);
        mEditorBase.setupGUIWindow(0, sceneTreeWindow);
    }

    function update(){
        fpsCamera.update();
    }

};