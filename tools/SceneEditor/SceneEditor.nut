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

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local sceneTree = mEditorBase.loadSceneTree(mParentNode, "/Users/edward/Documents/turnBasedGame/assets/maps/testVillage/scene.avscene");
        mEditorBase.setActiveSceneTree(sceneTree);
        sceneTree.debugPrint();


                //TODO remove the duplication.
                function parseFileToData_(file){
                    local outArray = [];
                    local height = 0;
                    local width = 0;
                    local greatest = 0;
                    while(!file.eof()){
                        local line = file.getLine();
                        local vals = split(line, ",");
                        local len = vals.len();
                        if(len == 0) continue;
                        width = len;
                        foreach(i in vals){
                            local intVal = i.tointeger();
                            outArray.append(intVal);
                            if(intVal > greatest){
                                greatest = intVal;
                            }
                        }
                        height++;
                    }


                    return {
                        "width": width,
                        "height": height,
                        "greatest": greatest,
                        "data": outArray,
                    }
                }

                local mTargetMap_ = "testVillage";
                //Parse the terrain information.
                local file = File();
                local path = "res://../../build/assets/maps/" + mTargetMap_ + "/terrain.txt";
                file.open(path);
                local voxData = parseFileToData_(file);

                file = File();
                path = "res://../../build/assets/maps/" + mTargetMap_ + "/terrainBlend.txt";
                file.open(path);
                local colourData = parseFileToData_(file);

                //TODO temporary for now.
                local mMapData = {
                    "voxHeight": voxData,
                    "voxType": colourData,

                    "width": voxData.width,
                    "height": voxData.height,
                };

        mTerrainChunkManager = ::TerrainChunkManager();
        //function setup(parentNode, mapData, chunkDivisions, copyHeightData=false){
        local targetParent = _scene.getRootSceneNode().createChildSceneNode();
        mTerrainChunkManager.setup(targetParent, mMapData, 4, true);

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

};