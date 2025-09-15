::Overworld <- class extends ::ProceduralExplorationWorld{

    mCameraPosition_ = null;
    mZoomAmount_ = 0.0;
    MAX_ZOOM = 200;

    #Override
    function setup(){
        base.setup();

        local mapsDir = ::BaseHelperFunctions.getOverworldDir();

        local targetMap = "overworld";
        local path = mapsDir + targetMap + "/scene.avScene";
        local parsedFile = null;
        if(_system.exists(path)){
            printf("Loading scene file with path '%s'", path);
            parsedFile = _scene.parseSceneFile(path);
        }

        local animData = _gameCore.insertParsedSceneFileGetAnimInfo(parsedFile, mParentNode_, mCollisionDetectionWorld_);

        mCameraPosition_ = Vec3();
    }

    #Override
    function getWorldType(){
        return WorldTypes.OVERWORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Overworld";
    }

    #Override
    function notifyPlayerMoved(){

    }

    #Override
    function getWaterPlaneMesh(){
        return "simpleWaterPlaneMesh";
    }

    #Override
    function constructPlayerEntry_(){

    }

    function applyMovementDelta(delta){
        mCameraPosition_ += (Vec3(delta.x, 0, delta.y) * 0.1);
        updateCameraPosition();
    }

    function applyZoomDelta(delta){
        mZoomAmount_ += delta;
        if(mZoomAmount_ < 0.0) mZoomAmount_ = 0.0;
        if(mZoomAmount_ >= MAX_ZOOM) mZoomAmount_ = MAX_ZOOM;
    }

    #Override
    function processCameraMove(x, y){

    }

    function update(){
        mCloudManager_.update();
        mWindStreakManager_.update();

        _gameCore.update(mCameraPosition_);
        _gameCore.setCustomPassBufferValue(0, 0, 0);

        mAnimIncrement_ += 0.01;
        updateWaterBlock(mWaterDatablock_);
        updateWaterBlock(mOutsideWaterDatablock_);
    }

    #Override
    function isActive(){
        return true;
    }

    function updateCameraPosition(){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local xPos = cos(mRotation_.x)*mCurrentZoomLevel_;
        local yPos = sin(mRotation_.x)*mCurrentZoomLevel_;
        local rot = Vec3(xPos, 0, yPos);
        yPos = sin(mRotation_.y)*mCurrentZoomLevel_;
        rot += Vec3(0, yPos, 0);

        //parentNode.setPosition(Vec3(mPosition_.x, zPos, mPosition_.z) + rot );
        local zoom = Vec3(0, 50 + mZoomAmount_, 50 + mZoomAmount_);
        parentNode.setPosition(mCameraPosition_ + zoom);
        camera.lookAt(mCameraPosition_);
    }
};