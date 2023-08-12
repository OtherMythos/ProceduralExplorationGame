//TODO remove this.
::ExplorationCount <- 0;

enum TerrainEditState{
    NONE,
    HEIGHT,
    COLOUR
};

::Base <- {

    mEditorBase = null
    mParentNode = null

    mAcceptHandle = null

    mTerrainChunkManager = null

    mEditingTerrain = false
    mEditingTerrainMode = TerrainEditState.NONE

    function setup(){
        fpsCamera.start(Vec3(0, 20, 0), Vec3(319.55, -14.55, 0));

        mAcceptHandle = _input.getButtonActionHandle("Accept");
        _input.mapKeyboardInput(_K_SPACE, mAcceptHandle);

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
        //_input.(i, _INPUT_PRESSED)
        fpsCamera.setSpeedModifier(_input.getButtonAction(mAcceptHandle));

        mEditorBase.update();

        if(mEditingTerrain){
            local mousePos = Vec2(_input.getMouseX(), _input.getMouseY())
            if(mEditorBase.checkMousePositionValid(mousePos)){
                local mTestPlane_ = Plane(Vec3(0, 1, 0), Vec3(0, 0, 0));
                mousePos /= _window.getSize();
                local ray = _camera.getCameraToViewportRay(mousePos.x, mousePos.y);
                local point = ray.intersects(mTestPlane_);
                if(point != false){
                    local worldPoint = ray.getPoint(point);

                    local chunkX = worldPoint.x.tointeger();
                    local chunkY = -worldPoint.z.tointeger();

                    if(_input.getMouseButton(0)){
                        if(getTerrainEditState() == TerrainEditState.HEIGHT){
                            mTerrainChunkManager.drawHeightValues(chunkX, chunkY, 1, 1, [1]);
                        }
                        else if(getTerrainEditState() == TerrainEditState.COLOUR){
                            mTerrainChunkManager.drawVoxTypeValues(chunkX, chunkY, 1, 1, [1]);
                        }
                    }
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
    function setEditTerrainHeight(edit){
        mEditingTerrainMode = edit ? TerrainEditState.HEIGHT : null;
    }
    function setEditTerrainColour(edit){
        mEditingTerrainMode = edit ? TerrainEditState.COLOUR : null;
    }

    function getTerrainEditState(){
        return mEditingTerrainMode;
    }

    function notifyBusEvent(event, data){
        if(event == SceneEditorBusEvents.REQUEST_SAVE){
            mTerrainChunkManager.performSave("testVillage");
        }
    }

};