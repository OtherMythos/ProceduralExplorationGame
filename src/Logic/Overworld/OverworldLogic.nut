enum OverworldStates{
    NONE,

    ZOOMED_OUT,
    ZOOMED_IN,

    MAX
};

::OverworldLogic <- {

    mWorld_ = null
    mParentSceneNode_ = null
    mCompositor_ = null
    mRenderableSize_ = null
    mStateMachine_ = null

    mOverworldRegionMeta_ = null

    mCurrentCameraPosition_ = null
    mCurrentCameraLookAt_ = null

    mActiveCount_ = 0

    function loadMeta(){
        local regionMeta = _system.readJSONAsTable("res://build/assets/overworld/overworld/meta.json");
        mOverworldRegionMeta_ = regionMeta;
    }

    function requestSetup(){
        local active = isActive();
        mActiveCount_++;
        if(active) return;

        setup_();
    }

    function requestShutdown(){
        mActiveCount_--;
        if(isActive()) return;

        shutdown_();
    }

    function requestState(state){
        mStateMachine_.setState(state);
    }

    function isActive(){
        return mActiveCount_ > 0;
    }

    function setup_(){

        print("Setting up overworld");

        mStateMachine_ = OverworldStateMachine(this);

        mParentSceneNode_ = _scene.getRootSceneNode().createChildSceneNode();
        /*
        local node = mParentSceneNode_.createChildSceneNode();
        local item = _gameCore.createVoxMeshItem("playerHead.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        node.attachObject(item);
        */
        //node.setScale(0.1, 0.1, 0.1);

        mRenderableSize_ = ::drawable * ::resolutionMult;
        setupCompositor_();

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        camera.setFarClipDistance(4000);

        local preparer = ::OverworldPreparer();
        mWorld_ = ::Overworld(0, preparer);
        //local dummy = _gameCore.getDummyMapGen();
        local dummy = _gameCore.loadOverworld("overworld");
        local nativeData = dummy.data;
        local data = nativeData.explorationMapDataToTable();
        data.rawset("placeData", []);
        data.playerStart <- 0;
        mWorld_.setup();
        mWorld_.resetSession(data, nativeData);
    }

    function getCompositorDatablock(){
        return ::CompositorManager.getDatablockForCompositor(mCompositor_);
    }

    function setRenderableSize(pos, size){
        mRenderableSize_ = size;
        if(!isActive()) return;

        local datablock = getCompositorDatablock();
        {
            local calcWidth = size.x / ::drawable.x;
            local calcHeight = size.y / ::drawable.y;

            local calcX = pos.x / ::drawable.x;
            local calcY = pos.y / ::drawable.y;

            local mAnimMatrix_ = [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ];

            mAnimMatrix_[0] = calcWidth;
            mAnimMatrix_[5] = calcHeight;
            mAnimMatrix_[3] = calcX;
            mAnimMatrix_[7] = calcY;
            datablock.setEnableAnimationMatrix(0, true);
            datablock.setAnimationMatrix(0, mAnimMatrix_);
        }
    }

    function setMapPositionFromPress(pos){
        if(pos == null) return;
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        local ray = camera.getCameraToViewportRay(pos.x, pos.y);
        local testPlane = Plane(::Vec3_UNIT_Y, ::Vec3_ZERO)
        local dist = ray.intersects(testPlane);
        if(dist != false){
            local worldPoint = ray.getPoint(dist);
            mWorld_.mCameraPosition_ = worldPoint;
        }
    }

    function unlockRegion(regionId){
        ::Base.mPlayerStats.incrementRegionIdDiscovery(regionId);
        mWorld_.animateRegionDiscovery(regionId);

        ::SaveManager.writeSaveAtPath("user://" + ::Base.mPlayerStats.getSaveSlot(), ::Base.mPlayerStats.getSaveData());
    }

    function shutdownCompositor_(){
        ::CompositorManager.destroyCompositorWorkspace(mCompositor_);
    }

    function setupCompositor_(){
        {
            local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
            local size = ::drawable * ::resolutionMult;
            _gameCore.setupCompositorDefs(size.x.tointeger(), size.y.tointeger());
        }
        mCompositor_ = ::CompositorManager.createCompositorWorkspace("renderWindowWorkspaceGameplayTexture", mRenderableSize_, CompositorSceneType.OVERWORLD, true, false);
    }

    function getCurrentSelectedRegion(){
        return mWorld_.getCurrentSelectedRegion();
    }

    function update(){
        if(!isActive()) return;
        mWorld_.update();
        mStateMachine_.update();
    }

    function shutdown_(){
        mParentSceneNode_.destroyNodeAndChildren();
        mWorld_.shutdown();

        print("Shutting down overworld");
    }

    function applyCameraDelta(delta){
        mStateMachine_.notify(delta);
    }

    function applyZoomDelta(delta){
        mWorld_.applyZoomDelta(delta);
    }

}
::OverworldLogic.OverworldStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(OverworldStates.MAX);
    function getLogic(){
        return mData_;
    }
    function getWorld(){
        return mData_.mWorld_;
    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.ZOOMED_OUT] = class extends ::Util.SimpleState{
    mAnim_ = 1.0;
    function start(data){
        mAnim_ = 0.0;
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        local camPos = Vec3(300, 700, 1500);
        local camLookAt = Vec3(300, 0, 200);

        if(data.getLogic().mCurrentCameraPosition_ == null){
            data.getLogic().mCurrentCameraPosition_ = camPos;
        }
        if(data.getLogic().mCurrentCameraLookAt_ == null){
            data.getLogic().mCurrentCameraLookAt_ = camLookAt;
        }

        mAnim_ = ::accelerationClampCoordinate_(mAnim_, 0.8, 0.02);
        local a = mAnim_ / 0.8;
        local animPos = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraPosition_, camPos, a);
        local animLookAt = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraLookAt_, camLookAt, a);
        camera.getParentNode().setPosition(animPos);
        camera.lookAt(animLookAt);

        if(mAnim_ >= 0.8){
            data.getLogic().mCurrentCameraPosition_ = camPos;
            data.getLogic().mCurrentCameraLookAt_ = camLookAt;
        }
    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.ZOOMED_IN] = class extends ::Util.SimpleState{
    mAnim_ = 1.0;
    function start(data){
        //local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        //camera.getParentNode().setPosition(0, 150, 300);
        //camera.lookAt(0, 0, 0);
        mAnim_ = 0.0;
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        local overworld = data.getWorld();
        local target = overworld.getTargetCameraPosition();
        local lookAtTarget = overworld.getCameraPosition();
        mAnim_ = ::accelerationClampCoordinate_(mAnim_, 0.8, 0.02);
        local a = mAnim_ / 0.8;
        local animPos = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraPosition_, target, a);
        local animLookAt = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraLookAt_, lookAtTarget, a);
        camera.getParentNode().setPosition(animPos);
        camera.lookAt(animLookAt);

        //data.getLogic().mCurrentCameraPosition_ = target;
        //data.getLogic().mCurrentCameraLookAt_ = lookAtTarget;

        if(mAnim_ >= 0.8){
            data.getLogic().mCurrentCameraPosition_ = target;
            data.getLogic().mCurrentCameraLookAt_ = lookAtTarget;
        }
    }

    function notify(obj, data){
        obj.getWorld().applyMovementDelta(data);
        //mWorld_.applyMovementDelta(delta);
    }
};

::OverworldLogic.loadMeta();