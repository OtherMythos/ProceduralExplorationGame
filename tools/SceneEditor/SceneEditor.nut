//TODO remove this.
::ExplorationCount <- 0;

::Base <- {

    mEditorBase = null
    mParentNode = null

    mTerrainChunkManager = null

    mEditingTerrain = false

    function setup(){
        fpsCamera.start(Vec3(0, 20, 0), Vec3(319.55, -14.55, 0));

        mEditorBase = ::SceneEditorFramework.Base();
        mEditorBase.mBus_.subscribeObject(this);

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local sceneTree = mEditorBase.loadSceneTree(mParentNode, "/Users/edward/Documents/turnBasedGame/assets/maps/testVillage/scene.avscene");
        mEditorBase.setActiveSceneTree(sceneTree);
        sceneTree.debugPrint();

        local fileHandler = ::TerrainChunkFileHandler("res://../../assets/maps/");
        local outMapData = fileHandler.readMapData("testVillage");

        mTerrainChunkManager = ::TerrainChunkManager();
        local targetParent = _scene.getRootSceneNode().createChildSceneNode();
        mTerrainChunkManager.setup(targetParent, outMapData, 4, true);

        local sceneTreeWindow = _gui.createWindow();
        sceneTreeWindow.setSize(500, 500);
        mEditorBase.setupGUIWindow(SceneEditorGUIPanelId.SCENE_TREE, sceneTreeWindow);

        local objectPropertiesWindow = _gui.createWindow();
        objectPropertiesWindow.setSize(500, 500);
        objectPropertiesWindow.setPosition(500, 0);
        mEditorBase.setupGUIWindow(SceneEditorGUIPanelId.OBJECT_PROPERTIES, objectPropertiesWindow);

        local terrainToolsWindow = _gui.createWindow();
        terrainToolsWindow.setSize(500, 500);
        terrainToolsWindow.setPosition(0, 500);
        mEditorBase.setupGUIWindowForClass(SceneEditorGUIPanelId.USER_CUSTOM_1, terrainToolsWindow, ::SceneEditorGUITerrainToolProperties);
    }

    function update(){
        fpsCamera.update();

        mEditorBase.update();

        if(mEditingTerrain){
            local mTestPlane_ = Plane(Vec3(0, 1, 0), Vec3(0, 0, 0));
            local mousePos = Vec2(_input.getMouseX(), _input.getMouseY()) / _window.getSize();
            local ray = _camera.getCameraToViewportRay(mousePos.x, mousePos.y);
            local point = ray.intersects(mTestPlane_);
            if(point != false){
                local worldPoint = ray.getPoint(point);

                local chunkX = worldPoint.x.tointeger();
                local chunkY = -worldPoint.z.tointeger();
                printf("Test %i %i", chunkX, chunkY);

                if(_input.getMouseButton(0)){
                    mTerrainChunkManager.drawHeightValues(chunkX, chunkY, 1, 1, [1]);
                }
            }
        }
    }

    function sceneSafeUpdate(){
        mEditorBase.sceneSafeUpdate();
    }

    function setEditTerrain(edit){
        mEditingTerrain = edit;
    }

    function notifyBusEvent(event, data){
        if(event == SceneEditorBusEvents.REQUEST_SAVE){
            mTerrainChunkManager.performSave("testVillage");
        }
    }

};