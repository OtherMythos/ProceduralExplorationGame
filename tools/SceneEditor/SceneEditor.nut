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

    function createLights(){
        //TODO remove the copy and pasting from base.
        //Create lighting upfront so all objects can share it.
        local light = _scene.createLight();
        local lightNode = _scene.getRootSceneNode().createChildSceneNode();
        lightNode.attachObject(light);

        light.setType(_LIGHT_DIRECTIONAL);
        light.setDirection(0, -1, -1);
        //light.setPowerScale(PI * 2);
        light.setPowerScale(PI);
        //light.setPowerScale(PI * 0.8);

        local val = 2.0;
        _scene.setAmbientLight(ColourValue(val, val, val, 1.0), ColourValue(val, val, val, 1.0), ::Vec3_UNIT_Y);
    }

    function setup(){
        fpsCamera.start(Vec3(0, 20, 0), Vec3(319.55, -14.55, 0));

        createLights();

        mAcceptHandle = _input.getButtonActionHandle("Accept");
        _input.mapKeyboardInput(_K_SPACE, mAcceptHandle);

        mEditorBase = ::SceneEditorFramework.Base();
        mEditorBase.mBus_.subscribeObject(this);

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local targetMap = getTargetEditMap();
        if(targetMap == null){
            return;
        }

        local sceneTree = attemptLoadSceneTree(targetMap);
        mEditorBase.setActiveSceneTree(sceneTree);
        if(sceneTree != null){
            sceneTree.debugPrint();
        }

        local fileHandler = ::TerrainChunkFileHandler("res://../../assets/maps/");
        local outMapData = fileHandler.readMapData(targetMap);

        mTerrainChunkManager = ::SceneEditorTerrainChunkManager(0);
        mTerrainChunkManager.setup(outMapData, 4);
        mTerrainChunkManager.generateInitialItems();
        local targetParent = _scene.getRootSceneNode().createChildSceneNode();
        mTerrainChunkManager.setupParentNode(targetParent);

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

    function attemptLoadSceneTree(targetMap){
        local targetPath = format("res://../../assets/maps/%s/scene.avscene", targetMap);
        if(!_system.exists(targetPath)){
            return null;
        }
        return mEditorBase.loadSceneTree(mParentNode, targetPath);
    }

    function update(){
        fpsCamera.update();
        //_input.(i, _INPUT_PRESSED)
        fpsCamera.setSpeedModifier(_input.getButtonAction(mAcceptHandle));

        mEditorBase.update();

        if(mEditingTerrain){
            local mousePos = Vec2(_input.getMouseX(), _input.getMouseY())
            if(mEditorBase.checkMousePositionValid(mousePos)){
                local mTestPlane_ = Plane(::Vec3_UNIT_Y, Vec3(0, 0, 0));
                mousePos /= _window.getSize();
                local ray = _camera.getCameraToViewportRay(mousePos.x, mousePos.y);
                local point = ray.intersects(mTestPlane_);
                if(point != false){
                    local worldPoint = ray.getPoint(point);

                    local chunkX = worldPoint.x.tointeger();
                    local chunkY = -worldPoint.z.tointeger();

                    if(_input.getMouseButton(_MB_LEFT)){
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

    function getTargetEditMap(){
        local editMap = _settings.getUserSetting("editMap");
        print(editMap);
        if(editMap != null && typeof editMap == "string"){
            return editMap;
        }
        return null;
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