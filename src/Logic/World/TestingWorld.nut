::TestingWorld <- class extends ::World{

    mWindStreakManager_ = null;

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);
    }

    function resetSession(){
        base.resetSession();

        mWindStreakManager_ = WindStreakManager(mParentNode_, 100, 100);

        callLogicScript();

        createScene();
    }

    #Override
    function getZForPos(pos){
        return 0;
    }

    #Override
    function getWorldType(){
        return WorldTypes.TESTING_WORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Testing";
    }

    #Override
    function notifyPreparationComplete_(){
        mReady_ = true;
        base.setup();
        resetSession();
    }

    #Override
    function processWorldCurrentChange_(current){
        if(mParentNode_ != null) mParentNode_.setVisible(current);
    }

    function createScene(){
        local floorNode = mParentNode_.createChildSceneNode();
        local floorItem = _scene.createItem("Plane.mesh");
        floorItem.setCastsShadows(false);
        floorItem.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        floorItem.setDatablock("testingFloor");
        floorNode.attachObject(floorItem);
        floorNode.setScale(150, 500, 150);
    }

    function updateCameraPosition(){
        local zPos = getZForPos(mPosition_);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local xPos = cos(mRotation_.x)*mCurrentZoomLevel_;
        local yPos = sin(mRotation_.x)*mCurrentZoomLevel_;
        local rot = Vec3(xPos, 0, yPos);
        yPos = sin(mRotation_.y)*mCurrentZoomLevel_;
        rot += Vec3(0, yPos, 0);

        parentNode.setPosition(Vec3(mPosition_.x, zPos, mPosition_.z) + rot );
        camera.lookAt(mPosition_.x, zPos, mPosition_.z);
    }

    function processCameraMove(x, y){
        mRotation_ += Vec2(x, y) * -0.05;
        local first = PI * 0.5;
        local second = PI * 0.1;
        if(mRotation_.y > first) mRotation_.y = first;
        if(mRotation_.y < second) mRotation_.y = second;

        local mouseScroll = _input.getMouseWheelValue();
        if(mouseScroll != 0){
            mCurrentZoomLevel_ += mouseScroll;
            if(mCurrentZoomLevel_ < MIN_ZOOM) mCurrentZoomLevel_ = MIN_ZOOM;
        }

        updateCameraPosition();
    }

    function update(){
        base.update();

        mWindStreakManager_.update();
    }

    #Override
    function getMapData(){
        return null;
    }

    #Override
    function checkForEnemyAppear(){
        //Stub to get enemies to stop spawning.
        return;
    }
    #Override
    function checkForDistractionAppear(){
        //Stub
        return
    }

    function callLogicScript(){
        //Check if we're running a test, in that case don't run this file.
        if(getroottable().rawin("_testSystem")) return;

        local scriptPath = "res://testingWorldScript.nut";
        if(_system.exists(scriptPath)){
            _doFile(scriptPath);
        }
    }

};