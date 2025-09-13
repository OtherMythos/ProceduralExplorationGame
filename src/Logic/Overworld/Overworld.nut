::Overworld <- class extends ::ProceduralExplorationWorld{

    mCameraPosition_ = null;
    mZoomAmount_ = 0.0;
    MAX_ZOOM = 50;

    #Override
    function setup(){
        base.setup();

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

    function createScene(){

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
    }

    #Override
    function processCameraMove(x, y){

    }

    function update(){
        mCloudManager_.update();
        mWindStreakManager_.update();

        _gameCore.update(mCameraPosition_);
        _gameCore.setCustomPassBufferValue(0, 0, 0);
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