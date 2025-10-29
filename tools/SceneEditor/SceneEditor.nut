enum TerrainEditState{
    NONE,
    HEIGHT,
    COLOUR,
    REGION
};

enum SceneEditorMapType{
    MAP,
    PLACE,
    OVERWORLD,

    MAX
}

::SceneEditorWindowListener <- class extends ::EditorGUIFramework.WindowManagerListener{
    function resized(id, newSize){
        ::Base.mEditorBase.resizeGUIWindow(id, newSize);
    }

    function closed(id){
        ::Base.mEditorBase.closeGUIWindow(id);
    }
};

::Base <- {

    mEditorBase = null
    mParentNode = null
    mTargetMap = null
    mSceneTree = null

    mKeyCommands = null
    mPrevKeyCommands = null

    mAcceptHandle = null

    mTerrainChunkManager = null
    mTileGridPlacer = null
    mCurrentTileData = null
    mCurrentTileDataWidth = 0
    mCurrentTileDataHeight = 0
    mTileSceneNode = null
    mVisitedPlacesMapData = null
    mTileSize = 5
    mTerrainNodeParent_ = null

    mEditingTerrain = false
    mEditingTileGrid = false
    mEditingTerrainMode = TerrainEditState.NONE
    mEditTerrainColourValue = 0
    mEditTerrainHeightValue = 0
    mEditTerrainBrushSize = 1
    mEditTerrainRegionValue = 0
    mTileGridBoxNode_ = null
    mTileGridIndicatorNode_ = null
    mCurrentSceneRightClick_ = null
    mSceneButtons_ = null

    mWindowTileGrid_ = null
    mWindowTerrainTool_ = null

    mGuiInputStealerWindow_ = null
    mGuiInputStealer_ = null

    mTerrainEditActive_ = false

    mCurrentHitPosition = Vec3()
    mCurrentHitPositionPlane = Vec3()
    mTestPlane_ = Plane(::Vec3_UNIT_Y, Vec3(0, 0, 0))

    mEditTileData_ = {
        "tile": 1,
        "tileRotation": 0,
        "drawHoles": false
    }

    TargetMapType = class{
        mName_ = null;
        mMapType_ = null;
        constructor(name, mapType){
            mName_ = name;
            mMapType_ = mapType;
        }

        function getName(){
            return mName_;
        }
        function getMapType(){
            return mMapType_;
        }
    }

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
        mKeyCommands = array(KeyCommand.MAX);
        mPrevKeyCommands = array(KeyCommand.MAX);

        //Custom implementation of helper functions.
        ::SceneEditorFramework.HelperFunctions = {
            function sceneEditorInteractable(){
                //Stub to be implemented by the user.
                return !::guiFrameworkBase.mouseInteracting();
            }
            function sceneTreeConstructObjectForUserEntry(userId, parentNode, entryData){
                switch(userId){
                    case 0:{
                        local item = _gameCore.createVoxMeshItem(entryData.value);

                        item.setRenderQueueGroup(30);
                        item.setQueryFlags(1 << 20);
                        parentNode.attachObject(item);
                        break;
                    }
                    case 1:{
                        break;
                    }
                    case 2:{
                        local val = entryData.value.tointeger();
                        local item = _scene.createItem(val == 0 ? "lineSphere" : "lineBox");

                        item.setRenderQueueGroup(30);
                        item.setQueryFlags(1 << 20);
                        parentNode.attachObject(item);
                    }
                }
            }
            function getNameForUserEntry(userId, entry){
                switch(userId){
                    case 0:{
                        return entry.data.value;
                        return "mesh";
                        break;
                    }
                    case 1:{
                        return "userData";
                        break;
                    }
                    case 2:{
                        return "collider";
                        break;
                    }
                    default:
                        return "Unknown";
                        break;
                }
            }
            function raycastForMovementGizmo(){
                local result = ::Base.castRayForTerrain();
                if(result == null){
                    result = ::Base.castRayForPlane();
                }
                return result;
            }
            function basicMouseInteractionEnabled(){
                return !::Base.mEditingTerrain && !::Base.mEditingTileGrid;
            }
            function getObjectPropertiesEntryPanelForUserEntry(userId){
                if(userId == 0){
                    return ::SceneEditorFramework.SceneEditorGUIObjectPropertyEntryVoxMesh;
                }
                else if(userId == 1){
                    return ::SceneEditorFramework.SceneEditorGUIObjectPropertyEntryDataPoint;
                }
                else if(userId == 2){
                    return ::SceneEditorFramework.SceneEditorGUIObjectPropertyEntryCollider;
                }
                return null;
            }
        };

        local saveFunction = function(){
            mEditorBase.mBus_.transmitEvent(SceneEditorFramework_BusEvents.REQUEST_SAVE, null);
        }
        local undoFunction = function(){
            mEditorBase.mActionStack_.undo();
        }
        local redoFunction = function(){
            mEditorBase.mActionStack_.redo();
        }
        local positionFunction = function(){
            mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.POSITION);
        }
        local scaleFunction = function(){
            mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.SCALE);
        }
        local sceneQueryFunction = function(){
            mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.RAYCAST);
        }

        local showWindowSceneTreeFunction = function(){
            setupWindow(SceneEditorFramework_GUIPanelId.SCENE_TREE);
        }
        local showWindowObjectPropertiesFunction = function(){
            setupWindow(SceneEditorFramework_GUIPanelId.OBJECT_PROPERTIES);
        }
        local showWindowTerrainToolsFunction = function(){
            setupWindow(SceneEditorFramework_GUIPanelId.USER_CUSTOM_1);
        }
        local showWindowTileGridFunction = function(){
            setupWindow(SceneEditorFramework_GUIPanelId.USER_CUSTOM_2);
        }

        ::guiFrameworkBase <- ::EditorGUIFramework.Base();
        ::guiFrameworkBase.setToolbar(::EditorGUIFramework.Toolbar([
            ["File", [
                ["Save", saveFunction.bindenv(this)]
            ]],
            [ "Edit", [
                ["Undo", undoFunction.bindenv(this)],
                ["Redo", redoFunction.bindenv(this)],
                ["Position transform", positionFunction.bindenv(this)],
                ["Scale transform", scaleFunction.bindenv(this)],
                ["Terrain query transform", sceneQueryFunction.bindenv(this)],
            ]],
            ["Window", [
                ["Scene Tree", showWindowSceneTreeFunction.bindenv(this)],
                ["Object Properties", showWindowObjectPropertiesFunction.bindenv(this)],
                ["Terrain Tools", showWindowTerrainToolsFunction.bindenv(this)],
                ["Tile Grid", showWindowTileGridFunction.bindenv(this)],
            ]]
        ]));
        local windowListener = ::SceneEditorWindowListener();
        ::guiFrameworkBase.attachWindowManagerListener(windowListener);

        ::SceneEditorFPSCamera.start(Vec3(0, 20, 0), Vec3(319.55, -14.55, 0));

        createLights();

        mAcceptHandle = _input.getButtonActionHandle("Accept");
        _input.mapKeyboardInput(_K_SPACE, mAcceptHandle);

        mEditorBase = ::SceneEditorFramework.Base();
        mEditorBase.mBus_.subscribeObject(this);
        ::guiFrameworkBase.mBus_.subscribeObject(GUIEventWrapper(this));

        mGuiInputStealerWindow_ = _gui.createWindow("guiInputStealer");
        mGuiInputStealerWindow_.setSize(10, 20);
        mGuiInputStealer_ = mGuiInputStealerWindow_.createButton();
        mGuiInputStealer_.setSize(50, 50);
        mGuiInputStealerWindow_.setVisible(false);

        local sceneButtonsWindow = guiFrameworkBase.createWindow(200, "SceneEditorButtons", {borderless = true, saveWindowState = false});
        sceneButtonsWindow.setSaveWindowState(false);
        mSceneButtons_ = SceneEditorSceneWindowButtons(sceneButtonsWindow.getWin(), sceneButtonsWindow);
        sceneButtonsWindow.getWin().setVisualsEnabled(false);

        mParentNode = _scene.getRootSceneNode().createChildSceneNode();

        local targetMap = getTargetEditMap();
        if(targetMap == null){
            return;
        }
        mTargetMap = targetMap

        mSceneTree = attemptLoadSceneTree(targetMap);
        mEditorBase.setActiveSceneTree(mSceneTree);
        if(mSceneTree != null){
            mSceneTree.debugPrint();
        }

        _gameCore.setMapsDirectory(getMapTypeBasePath(mTargetMap));

        _gameCore.beginParseVisitedLocation(targetMap.getName());
        local mapClaim = null;
        while(mapClaim == null){
            mapClaim = _gameCore.checkClaimParsedVisitedLocation();
        }
        mVisitedPlacesMapData = mapClaim;
        mVisitedPlacesMapData.loadTileDataAsMeta(targetMap.getName(), "terrainRegion.txt");

        mTerrainChunkManager = ::SceneEditorTerrainChunkManager(0, targetMap.getMapType() == SceneEditorMapType.OVERWORLD);
        mTerrainChunkManager.setup(mapClaim, targetMap.getMapType() == SceneEditorMapType.PLACE ? 1 : 4);
        mTerrainChunkManager.generateInitialItems();
        local targetParent = _scene.getRootSceneNode().createChildSceneNode();
        mTerrainChunkManager.setupParentNode(targetParent);
        if(targetMap.getMapType() == SceneEditorMapType.PLACE){
            targetParent.setPosition(-0.75, 0, 0.75);
        }
        mTerrainNodeParent_ = targetParent;

        mTileGridPlacer = ::TileGridPlacer([
            "InteriorFloor.voxMesh", "InteriorWall.voxMesh", "InteriorWallCorner.voxMesh"
        ], mTileSize);
        mCurrentTileData = mVisitedPlacesMapData.getTileArray();
        mCurrentTileDataWidth = mVisitedPlacesMapData.getTilesWidth();
        mCurrentTileDataHeight = mVisitedPlacesMapData.getTilesHeight();
        regenerateTileGrid();

        setupWindow(SceneEditorFramework_GUIPanelId.SCENE_TREE);
        setupWindow(SceneEditorFramework_GUIPanelId.OBJECT_PROPERTIES);
        setupWindow(SceneEditorFramework_GUIPanelId.USER_CUSTOM_1);
        setupWindow(SceneEditorFramework_GUIPanelId.USER_CUSTOM_2);

        guiFrameworkBase.loadWindowStates("user://windowState.json");

        mTileGridBoxNode_ = mParentNode.createChildSceneNode();
        mTileGridBoxNode_.attachObject(_scene.createItem("lineBox"));
        mTileGridBoxNode_.setVisible(false);
        positionLineBox();

        ::generateFloorGrid();

        print(::guiFrameworkBase.getToolbar());
        local toolbarSize = ::guiFrameworkBase.getToolbar().getSize();
        toolbarSize.x = 10;
        toolbarSize.y += 10;
        sceneButtonsWindow.setPosition(toolbarSize);

        //::posMesh <- _mesh.create("cube");
        //posMesh.setPosition(mCurrentHitPosition);
    }

    function getTitleForWindow_(winType){
        switch(winType){
            case SceneEditorFramework_GUIPanelId.SCENE_TREE: return "Scene Tree";
            case SceneEditorFramework_GUIPanelId.OBJECT_PROPERTIES: return "Object Properties";
            case SceneEditorFramework_GUIPanelId.USER_CUSTOM_1: return "Terrain Tools";
            case SceneEditorFramework_GUIPanelId.USER_CUSTOM_2: return "Tile Grid";
            default: {
                return "Unknown Window"
            }
        }
    }
    function setupWindow(winType){
        if(guiFrameworkBase.windowForIdExists(winType)) return;
        local winTitle = getTitleForWindow_(winType);
        local guiWin = guiFrameworkBase.createWindow(winType, winTitle);

        if(winType == SceneEditorFramework_GUIPanelId.USER_CUSTOM_1){
            mWindowTerrainTool_ = mEditorBase.setupGUIWindowForClass(SceneEditorFramework_GUIPanelId.USER_CUSTOM_1, guiWin.getWin(), ::SceneEditorGUITerrainToolProperties);
        }else if(winType == SceneEditorFramework_GUIPanelId.USER_CUSTOM_2){
            mWindowTileGrid_ = mEditorBase.setupGUIWindowForClass(SceneEditorFramework_GUIPanelId.USER_CUSTOM_2, guiWin.getWin(), ::SceneEditorGUITileGridProperties);
        }else{
            mEditorBase.setupGUIWindow(winType, guiWin.getWin());
        }

        guiWin.setPosition(500, 500);
    }

    function processWindowClosed(winType){
        printf("Registering close for window %i", winType);
        mEditorBase.closeGUIWindow(winType);

        if(winType == SceneEditorFramework_GUIPanelId.USER_CUSTOM_1){
            mWindowTerrainTool_ = null;
        }else if(winType == SceneEditorFramework_GUIPanelId.USER_CUSTOM_2){
            mWindowTileGrid_ = null;
        }
    }

    function positionLineBox(){
        local width = mCurrentTileDataWidth * mTileSize;
        local height = mCurrentTileDataHeight * mTileSize;
        mTileGridBoxNode_.setScale(width / 2, 20, height / 2);
        mTileGridBoxNode_.setPosition(width / 2 + 0.5, 0, height / 2 + 0.5);
    }

    function resizeTileGrid(newWidth, newHeight){
        printf("Resizing tile grid from %i %i to %i %i", mCurrentTileDataWidth, mCurrentTileDataHeight, newWidth, newHeight);
        local oldWidth = mCurrentTileDataWidth;
        local oldHeight = mCurrentTileDataHeight;
        mCurrentTileDataWidth = newWidth;
        mCurrentTileDataHeight = newHeight;

        local newArray = array(newWidth * newHeight, TileGridMasks.HOLE);
        for(local y = 0; y < oldHeight; y++){
            for(local x = 0; x < oldWidth; x++){
                if(x >= mCurrentTileDataWidth || y >= mCurrentTileDataHeight) continue;
                local val = mCurrentTileData[x + y * oldWidth];
                newArray[x + y * newWidth] = val;
            }
        }

        mCurrentTileData = newArray;

        positionLineBox();
        regenerateTileGrid();
    }

    function getMapTypeBasePath(targetMap){
        local val = null;
        local mapType = targetMap.getMapType();
        if(mapType == SceneEditorMapType.MAP){
            val = "res://../../assets/maps/"
        }
        else if(mapType == SceneEditorMapType.PLACE){
            val = "res://../../assets/places/"
        }
        else if(mapType == SceneEditorMapType.OVERWORLD){
            val = "res://../../assets/overworld/"
        }
        if(val == null){
            throw "Map type could not be determined";
        }
        return val;
    }

    function getFileForMapTarget(targetMap, fileName){
        local rootPath = getMapTypeBasePath(targetMap) + "%s/%s";

        return format(rootPath, targetMap.getName(), fileName);
    }

    function attemptLoadSceneTree(targetMap){
        local targetPath = getFileForMapTarget(targetMap, "scene.avScene");
        //local targetPath = format(dir, targetMap.getName());
        if(!_system.exists(targetPath)){
            mEditorBase.createBaseSceneTreeFile(targetPath);
        }
        return mEditorBase.loadSceneTree(mParentNode, targetPath);
    }

    function checkKeyCommands(){
        if(_input.getRawKeyScancodeInput(KeyScancode.LCTRL)){
            if(_input.getRawKeyScancodeInput(KeyScancode.Z)){
                if(_input.getRawKeyScancodeInput(KeyScancode.LSHIFT)){
                    if(setKeyCommand(KeyCommand.REDO)){
                        mEditorBase.mActionStack_.redo();
                    }
                }else{
                    if(setKeyCommand(KeyCommand.UNDO)){
                        mEditorBase.mActionStack_.undo();
                    }
                }
            }
        }

        resetKeyCommands_();
    }

    function resetKeyCommands_(){
        for(local i = 0; i < mKeyCommands.len(); i++){
            mPrevKeyCommands[i] = mKeyCommands[i];
            mKeyCommands[i] = false;
        }
    }

    function setKeyCommand(command){
        if(!mKeyCommands[command]){
            mKeyCommands[command] = true;
            if(!mPrevKeyCommands[command]){
                //The state has just flipped to true so fire the event.
                return true;
            }
        }
        return false;
    }

    function getTerrainEditArray(value, width, height){
        local a = array(width * height, value);

        return a;
    }

    function update(){
        checkKeyCommands();
        ::SceneEditorFPSCamera.update();
        //_input.(i, _INPUT_PRESSED)

        local speedModifier = 1.0;
        if(_input.getRawKeyScancodeInput(KeyScancode.LSHIFT)){
            speedModifier = 3.0;
        }
        if(_input.getRawKeyScancodeInput(KeyScancode.LALT)){
            speedModifier = 16.0;
        }
        ::SceneEditorFPSCamera.setSpeedModifier(speedModifier);

        if(_input.getRawKeyScancodeInput(KeyScancode.NUMBER_1)){
            mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.POSITION);
        }
        if(_input.getRawKeyScancodeInput(KeyScancode.NUMBER_2)){
            mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.SCALE);
        }
        if(_input.getRawKeyScancodeInput(KeyScancode.NUMBER_3)){
            mEditorBase.getActiveSceneTree().setObjectTransformCoordinateType(SceneEditorFramework_BasicCoordinateType.RAYCAST);
        }

        //if(mCurrentHitPosition != null){
            //posMesh.setPosition(mCurrentHitPosition);
        //}

        mEditorBase.update();

        ::guiFrameworkBase.update();
        ::guiFrameworkBase.setMousePosition(_input.getMouseX(), _input.getMouseY());
        ::guiFrameworkBase.setMouseButton(0, _input.getMouseButton(_MB_LEFT));
        ::guiFrameworkBase.setMouseButton(1, _input.getMouseButton(_MB_RIGHT));

        if(!::guiFrameworkBase.mouseInteracting() && mEditingTerrain){
            //local mousePos = Vec2(_input.getMouseX(), _input.getMouseY())
            if(::SceneEditorFramework.HelperFunctions.sceneEditorInteractable()){
                //local mTestPlane_ = Plane(::Vec3_UNIT_Y, Vec3(0, 0, 0));
                //mousePos /= _window.getSize();
                //local ray = _camera.getCameraToViewportRay(mousePos.x, mousePos.y);
                //local point = ray.intersects(mTestPlane_);
                local point = mCurrentHitPosition;
                if(point == null){
                    point = mCurrentHitPositionPlane;
                }
                if(point != null){
                    //local worldPoint = ray.getPoint(point);
                    local offset = 0;
                    if(mTargetMap.getMapType() == SceneEditorMapType.PLACE){
                        offset = 0.75;
                    }

                    local chunkX = (point.x + offset).tointeger();
                    local chunkY = -((point.z - offset).tointeger());

                    if(_input.getMouseButton(_MB_LEFT)){
                        if(!mTerrainEditActive_){
                            mTerrainEditActive_ = true;
                            mTerrainChunkManager.notifyActionStart(getTerrainEditState() == TerrainEditState.HEIGHT);
                        }
                        local width = mEditTerrainBrushSize;
                        local height = mEditTerrainBrushSize;
                        local drawWidth = width * 2 + 1;
                        local drawHeight = height * 2 + 1;
                        if(getTerrainEditState() == TerrainEditState.HEIGHT){
                            local vals = getTerrainEditArray(mEditTerrainHeightValue, drawWidth, drawHeight);
                            mTerrainChunkManager.drawHeightValues(chunkX, chunkY, drawWidth, drawHeight, vals);
                        }
                        else if(getTerrainEditState() == TerrainEditState.COLOUR){
                            local vals = getTerrainEditArray(mEditTerrainColourValue, drawWidth, drawHeight);
                            mTerrainChunkManager.drawVoxTypeValues(chunkX, chunkY, drawWidth, drawHeight, vals);
                        }
                        else if(getTerrainEditState() == TerrainEditState.REGION){
                            local vals = getTerrainEditArray(mEditTerrainRegionValue, drawWidth, drawHeight);
                            mTerrainChunkManager.drawRegionValues(chunkX, chunkY, drawWidth, drawHeight, vals);
                        }
                    }
                }
            }
        }
        local drawTileIndicator = false;
        if(!::guiFrameworkBase.mouseInteracting() && mEditingTileGrid){
            if(::SceneEditorFramework.HelperFunctions.sceneEditorInteractable()){
                local chunkX = null;
                local chunkY = null;

                local point = mCurrentHitPositionPlane;
                if(point != null){
                    chunkX = (point.x / mTileSize).tointeger();
                    chunkY = (point.z / mTileSize).tointeger();

                    if(_input.getMouseButton(_MB_LEFT)){

                        local v = mEditTileData_.tile;
                        v = v | mEditTileData_.tileRotation << 5;
                        if(mEditTileData_.drawHoles){
                            v = TileGridMasks.HOLE;
                        }
                        setTileToGrid(chunkX, chunkY, v);

                    }

                    drawTileIndicator = true;
                    positionTileIndicator_(chunkX * mTileSize, chunkY * mTileSize);
                }
            }
        }
        if(mTileGridIndicatorNode_ != null) mTileGridIndicatorNode_.setVisible(drawTileIndicator);
        if(mTerrainEditActive_ && !_input.getMouseButton(_MB_LEFT)){
            mTerrainEditActive_ = false;
            mTerrainChunkManager.notifyActionEnd();
        }
    }

    function shutdown(){
        guiFrameworkBase.serialiseWindowStates("user://windowState.json");
        mEditorBase.shutdown();
    }

    function setTileToGrid(x, y, val){
        if(x < 0 || y < 0 || x >= mCurrentTileDataWidth || y >= mCurrentTileDataHeight) return;

        local idx = x + y * mCurrentTileDataWidth;
        local oldVal = mCurrentTileData[idx];
        if(oldVal == val) return;

        local A = ::SceneEditorFramework.Actions[SceneEditorFramework_Action.USER_1];
        local action = A(this);
        action.populateForCoord(x, y, oldVal, val);
        action.performAction();
        mEditorBase.pushAction(action);

    }

    function positionTileIndicator_(posX, posY){
        if(mTileGridIndicatorNode_ != null){
            mTileGridIndicatorNode_.destroyNodeAndChildren();
        }
        mTileGridIndicatorNode_ = mParentNode.createChildSceneNode();
        mTileGridIndicatorNode_.setVisible(true);

        mTileGridIndicatorNode_.setPosition(posX + 3, 0.02, posY + 3);

        local item = mTileGridPlacer.populateNodeForTile(mTileGridIndicatorNode_, mEditTileData_.tile, mEditTileData_.tileRotation << 5);
        if(item != null){
            item.setDatablock("SceneEditorTool/TileGridHighlight");
        }
    }

    function setTileToGrid_(x, y, val){
        local idx = x + y * mCurrentTileDataWidth;
        mCurrentTileData[idx] = val;
        regenerateTileGrid();
    }

    function regenerateTileGrid(){
        if(mTileSceneNode != null){
            mTileSceneNode.destroyNodeAndChildren();
        }
        mTileSceneNode = _scene.getRootSceneNode().createChildSceneNode();
        mTileSceneNode.setPosition(3, 0, 3);
        if(mCurrentTileData != null){
            mTileGridPlacer.insertGridToScene(mTileSceneNode, mCurrentTileData, mCurrentTileDataWidth, mCurrentTileDataHeight);
        }
    }

    function getTargetEditMap(){
        local editMap = _settings.getUserSetting("editMap");
        //print(editMap);
        if(editMap != null && typeof editMap == "string"){
            return TargetMapType(editMap, SceneEditorMapType.MAP);
        }

        local editPlace = _settings.getUserSetting("editPlace");
        //print(editPlace);
        if(editPlace != null && typeof editPlace == "string"){
            return TargetMapType(editPlace, SceneEditorMapType.PLACE);
        }

        local editPlace = _settings.getUserSetting("editOverworld");
        if(editPlace != null && typeof editPlace == "string"){
            return TargetMapType(editPlace, SceneEditorMapType.OVERWORLD);
        }

        return null;
    }

    function getTargetMapType(){
        return mTargetMap;
    }

    function sceneSafeUpdate(){
        mEditorBase.sceneSafeUpdate();

        mCurrentHitPosition = castRayForTerrain();
        mCurrentHitPositionPlane = castRayForPlane();
    }

    function castRay_(){
        local mousePos = Vec2(_input.getMouseX(), _input.getMouseY());
        local mouseTarget = mousePos / _window.getSize();
        local ray = _camera.getCameraToViewportRay(mouseTarget.x, mouseTarget.y);

        return ray;
    }

    function castRayForTerrain(){
        if(mVisitedPlacesMapData == null) return;
        local ray = castRay_();

        local outPos = mVisitedPlacesMapData.castRayForTerrain(ray, mTerrainNodeParent_.getPositionVec3());
        return outPos;
    }

    function castRayForPlane(){
        local ray = castRay_();

        local dist = ray.intersects(mTestPlane_);
        if(dist == false) return null;
        local worldPoint = ray.getPoint(dist);
        return worldPoint;
    }

    function notifyFPSBegan(){
        mGuiInputStealer_.setFocus();
    }

    function setEditTerrain(edit){
        mEditingTerrain = edit;
        mEditingTileGrid = false;

        if(mWindowTerrainTool_ != null) mWindowTerrainTool_.refreshButtons();
        //mWindowTileGrid_.refreshButtons();
    }
    function setEditTileGrid(edit){
        mEditingTileGrid = edit;
        mEditingTerrain = false;

        mTileGridBoxNode_.setVisible(edit);

        //mWindowTerrainTool_.refreshButtons();
        if(mWindowTileGrid_ != null) mWindowTileGrid_.refreshButtons();
    }
    function setEditTerrainHeight(edit){
        processEditModeChanged_(TerrainEditState.HEIGHT, mEditingTerrainMode);
        mEditingTerrainMode = edit ? TerrainEditState.HEIGHT : null;
    }
    function setEditTerrainColour(edit){
        processEditModeChanged_(TerrainEditState.COLOUR, mEditingTerrainMode);
        mEditingTerrainMode = edit ? TerrainEditState.COLOUR : null;
    }
    function setEditTerrainRegion(edit){
        processEditModeChanged_(TerrainEditState.REGION, mEditingTerrainMode);
        mEditingTerrainMode = edit ? TerrainEditState.REGION : null;
    }

    function processEditModeChanged_(current, prev){
        if(current == TerrainEditState.REGION){
            mTerrainChunkManager.setEditTerrainRegion(true);
        }else{
            if(prev == TerrainEditState.REGION){
                mTerrainChunkManager.setEditTerrainRegion(false);
            }
        }
    }

    function setEditTerrainColourValue(value){
        mEditTerrainColourValue = value;
        if(mWindowTerrainTool_ != null) mWindowTerrainTool_.refreshButtons();
    }

    function setEditTerrainHeightValue(height){
        mEditTerrainHeightValue = height;
    }

    function setEditTerrainBrushSize(size){
        mEditTerrainBrushSize = size;
    }

    function setEditTerrainRegionValue(region){
        mEditTerrainRegionValue = region;
    }

    function getEditTerrainRegionValue(){
        return mEditTerrainRegionValue;
    }

    function getEditingTerrain(){
        return mEditingTerrain;
    }
    function getEditingTileGrid(){
        return mEditingTileGrid;
    }
    function setEditingTile(tile){
        mEditTileData_.tile = tile;
    }
    function setTileDrawHoles(holes){
        mEditTileData_.drawHoles = holes;
    }
    function setEditingTileRotation(tileRotation){
        mEditTileData_.tileRotation = tileRotation;
    }

    function getTileEditData(){
        return mEditTileData_;
    }

    function getTerrainEditState(){
        return mEditingTerrainMode;
    }

    function getTerrainEditHeight(){
        return mEditTerrainHeightValue;
    }

    function getTerrainBrushSize(){
        return mEditTerrainBrushSize;
    }

    function getTerrainEditColour(){
        return mEditTerrainColourValue;
    }

    function writeEditorMetaFile_(path){
        local aabb = mSceneTree.determineAABB();

        local size = aabb.getSize();
        local centre = aabb.getCentre();
        local half = aabb.getHalfSize();
        local data = {
            "centreX": centre.x,
            "centreY": centre.y,
            "centreZ": centre.z,

            "halfX": half.x,
            "halfY": half.y,
            "halfZ": half.z,

            "radius": aabb.getRadius()
        };

        _system.writeJsonAsFile(path, data);
        printf("Writing editorMeta to path '%s'", path);
    }

    function notifyBusEvent(event, data){
        if(event == SceneEditorFramework_BusEvents.REQUEST_SAVE){
            if(mVisitedPlacesMapData.terrainActive()){
                mTerrainChunkManager.performAltitudeSave(getFileForMapTarget(mTargetMap, "terrain.txt"));
                mTerrainChunkManager.performBlendSave(getFileForMapTarget(mTargetMap, "terrainBlend.txt"));
                if(getTargetMapType().getMapType() == SceneEditorMapType.OVERWORLD){
                    mTerrainChunkManager.performMetaSave(getFileForMapTarget(mTargetMap, "terrainRegion.txt"));
                }
                //mTerrainChunkManager.performSave(mTargetMap.getName());
            }

            local filePath = getFileForMapTarget(mTargetMap, "dataPoints.txt");
            local writer = SceneEditorDataPointWriter();
            writer.performSave(filePath, mSceneTree);

            if(getTargetMapType().getMapType() == SceneEditorMapType.PLACE){
                filePath = getFileForMapTarget(mTargetMap, "editorMeta.json");
                writeEditorMetaFile_(filePath);
            }

            if(mCurrentTileData != null){
                local tileDataWriter = ::TileDataWriter();
                tileDataWriter.performSave(mTargetMap.getName(), mCurrentTileData, mCurrentTileDataWidth);
            }
        }
        else if(event == SceneEditorFramework_BusEvents.SCENE_TREE_OPTIONS_MENU_REQUEST){
            mCurrentSceneRightClick_ = ::SceneEditorRightClickMenuManager(data, mSceneTree);
        }
    }

    GUIEventWrapper = class{

        mParent_ = null;
        constructor(parent){
            mParent_ = parent;
        }

        function notifyBusEvent(event, data){
            if(event == EditorGUIFramework_BusEvent.WINDOW_CLOSED){
                mParent_.processWindowClosed(data);
            }
        }

    }

};