enum OverworldStates{
    NONE,

    ZOOMED_OUT,
    ZOOMED_IN,
    REGION_UNLOCK,
    TITLE_SCREEN,

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

    //Optimal camera position calculated once at startup (never changes)
    mOptimalCameraPosition_ = null
    mOptimalCameraLookAt_ = null

    //Viewport positioning system
    mViewportPositioner_ = null

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

    function requestState(state, stateData = null){
        mStateMachine_.setState(state, stateData);
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

        //Initialise the viewport positioner with references to world and scene node
        mViewportPositioner_ = ::OverworldViewportPositioner;
        mViewportPositioner_.initialise(mWorld_, mParentSceneNode_);
    }

    function getCompositorDatablock(){
        return ::CompositorManager.getDatablockForCompositor(mCompositor_);
    }

    function setRenderableSize(pos, size){
        mRenderableSize_ = size;
        if(mViewportPositioner_){
            mViewportPositioner_.setPanelBounds(pos, size);
        }
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
        requestState(OverworldStates.REGION_UNLOCK);

        ::SaveManager.writeSaveAtPath("user://" + ::Base.mPlayerStats.getSaveSlot(), ::Base.mPlayerStats.getSaveData());
    }

    function setTitleScreenMode(skipWindupAnimation = false){
        requestState(OverworldStates.TITLE_SCREEN, {skipWindupAnimation = skipWindupAnimation});
    }

    function calculateOverworldCentre_(){
        //Calculate the merged AABB of all regions to find the center
        local minBounds = null;
        local maxBounds = null;

        foreach(c,i in mWorld_.mRegionEntries_){
            local aabb = i.calculateAABB();
            if(aabb == null) continue;

            local centre = aabb.getCentre();
            local halfSize = aabb.getHalfSize();
            local min = centre - halfSize;
            local max = centre + halfSize;

            if(minBounds == null){
                minBounds = min.copy();
                maxBounds = max.copy();
            }else{
                if(min.x < minBounds.x) minBounds.x = min.x;
                if(min.y < minBounds.y) minBounds.y = min.y;
                if(min.z < minBounds.z) minBounds.z = min.z;

                if(max.x > maxBounds.x) maxBounds.x = max.x;
                if(max.y > maxBounds.y) maxBounds.y = max.y;
                if(max.z > maxBounds.z) maxBounds.z = max.z;
            }
        }

        if(minBounds == null || maxBounds == null){
            return Vec3(0.0, 0.0, 0.0);
        }

        return (minBounds + maxBounds) * 0.5;
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
        shutdownCompositor_()

        print("Shutting down overworld");
    }

    function applyCameraDelta(delta){
        mStateMachine_.notify(delta);
    }

    function applyZoomDelta(delta){
        mWorld_.applyZoomDelta(delta);
    }

    function notifyTitleScreenAnimationReady(){
        //TODO magic number for now.
        mStateMachine_.notify(0xFF);
    }

    //Calculate the landmass AABB and return its centre and radius
    function calculateLandmassAABBData_(){
        local minBounds = null;
        local maxBounds = null;

        foreach(c,i in mWorld_.mRegionEntries_){
            local aabb = i.calculateAABB();
            if(aabb == null) continue;

            local centre = aabb.getCentre();
            local halfSize = aabb.getHalfSize();
            local min = centre - halfSize;
            local max = centre + halfSize;

            if(minBounds == null){
                minBounds = min.copy();
                maxBounds = max.copy();
            }else{
                if(min.x < minBounds.x) minBounds.x = min.x;
                if(min.y < minBounds.y) minBounds.y = min.y;
                if(min.z < minBounds.z) minBounds.z = min.z;

                if(max.x > maxBounds.x) maxBounds.x = max.x;
                if(max.y > maxBounds.y) maxBounds.y = max.y;
                if(max.z > maxBounds.z) maxBounds.z = max.z;
            }
        }

        if(minBounds == null || maxBounds == null){
            return {
                centre = Vec3(0.0, 0.0, 0.0),
                radius = 0.0
            };
        }

        local centre = (minBounds + maxBounds) * 0.5;
        local size = maxBounds - minBounds;
        local radius = (size.x + size.z) * 0.5;

        return {
            centre = centre,
            radius = radius
        };
    }

    //Calculate the optimal camera position for viewing the entire overworld
    //This is calculated once at startup and stored, never changing
    function calculateAndApplyOptimalCameraZoom_(){
        if(!isActive()) return;
        if(!mViewportPositioner_) return;

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        //Target height for the camera (adjust as needed)
        local targetHeight = 700.0;

        //Calculate optimal zoom using the viewport positioner
        local cameraData = mViewportPositioner_.calculateAndApplyOptimalCameraZoom_(camera, targetHeight);
        if(cameraData != null){
            mOptimalCameraPosition_ = cameraData.cameraPos;
            mOptimalCameraLookAt_ = cameraData.lookAtPos;
        }
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
        //Calculate optimal camera position if not yet cached
        if(data.getLogic().mOptimalCameraPosition_ == null){
            data.getLogic().calculateAndApplyOptimalCameraZoom_();
        }
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        camera.getParentNode().setPosition(data.getLogic().mCurrentCameraPosition_);
        camera.lookAt(data.getLogic().mCurrentCameraLookAt_);
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        //Use the cached optimal camera position
        local camPos = data.getLogic().mOptimalCameraPosition_;
        local camLookAt = data.getLogic().mOptimalCameraLookAt_;

        if(camPos == null){
            camPos = Vec3(300, 0, 1500);
        }
        if(camLookAt == null){
            camLookAt = Vec3(300, 0, 200);
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

        local overworld = data.getWorld();
        overworld.setOverworldSelectionActive(true);
    }

    function end(data){
        local overworld = data.getWorld();
        overworld.setOverworldSelectionActive(false);
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

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.REGION_UNLOCK] = class extends ::Util.SimpleState{
    mStage_ = 0;
    mAnim_ = 0.0;

    mAnimCamPos_ = null;
    mAnimCamLookAt_ = null;

    function start(data){
        local overworld = data.getWorld();
        mAnim_ = 0.0;

        local regionId = overworld.getCurrentSelectedRegion();
        local aabb = overworld.getAABBForRegion(regionId);
        local halfBounds = aabb.getHalfSize();
        local centre = aabb.getCentre();
        local targetPos = centre.copy();
        targetPos.z += halfBounds.z * 6;
        targetPos.y += 40 * 4;
        mAnimCamPos_ = targetPos;
        //mAnimCamPos_.z += 40;
        mAnimCamLookAt_ = centre;
    }

    function end(data){
        local overworld = data.getWorld();
    }

    function update(data){
        if(mStage_ == 0){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

            mAnim_ = ::accelerationClampCoordinate_(mAnim_, 1.0, 0.03);
            local a = ::Easing.easeInQuart(mAnim_);

            local animPos = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraPosition_, mAnimCamPos_, a);
            local animLookAt = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraLookAt_, mAnimCamLookAt_, a);
            camera.getParentNode().setPosition(animPos);
            camera.lookAt(animLookAt);

            if(mAnim_ >= 1.0){
                mAnim_ = 0.0;
                mStage_++;
            }
        }
        else if(mStage_ == 1){
            mAnim_ = ::accelerationClampCoordinate_(mAnim_, 1.0, 0.008);

            local overworld = data.getWorld();
            overworld.updateRegionDiscoveryAnimation(overworld.getCurrentSelectedRegion(), mAnim_);

            if(mAnim_ >= 1.0){
                mAnim_ = 0.0;
                mStage_++;
            }
        }
        else if(mStage_ == 2){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

            mAnim_ = ::accelerationClampCoordinate_(mAnim_, 1.0, 0.06);
            local animPos = ::calculateSimpleAnimation(mAnimCamPos_, data.getLogic().mCurrentCameraPosition_, mAnim_);
            local animLookAt = ::calculateSimpleAnimation(mAnimCamLookAt_, data.getLogic().mCurrentCameraLookAt_, mAnim_);
            camera.getParentNode().setPosition(animPos);
            camera.lookAt(animLookAt);

            if(mAnim_ >= 1.0){
                return OverworldStates.ZOOMED_IN;
            }
        }

    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.TITLE_SCREEN] = class extends ::Util.SimpleState{
    mStage_ = 0;
    mTime_ = 0.0;
    mOrbitRadius_ = 500.0;
    mOrbitHeight_ = 200.0;
    mOrbitSpeed_ = 1.0;
    mCentrePosition_ = null;
    mOrbitAngleRange_ = PI / 2.0;

    mTargetPosition_ = null;
    mMovementTime_ = 0.0;
    mMovementDuration_ = 5.0;
    mStartCentrePosition_ = null;

    mInitialOrbitRadius_ = 2000.0;
    mZoomInDuration_ = 6.0;
    mZoomAnimTime_ = 0.0;

    mCamPos_ = null;
    mLookAtPos_ = null;

    mTransitionInProgress_ = false;
    mTransitionTime_ = 0.0;
    mTransitionDuration_ = 2.0;
    mTransitionStartCamPos_ = null;
    mTransitionStartLookAt_ = null;

    mWaitingForAnimationReady_ = false;

    mStage0EndCamPos_ = null;
    mTransitionSetupDone_ = false;

    function start(data){
        mStage_ = -1;
        mTime_ = 0.0;
        mZoomAnimTime_ = 0.0;

        //Calculate landmass AABB data for positioning
        local aabbData = data.getLogic().calculateLandmassAABBData_();
        mCentrePosition_ = aabbData.centre;
        mStartCentrePosition_ = mCentrePosition_.copy();

        //Set initial orbit radius based on landmass size
        mOrbitRadius_ = aabbData.radius;
        mInitialOrbitRadius_ = aabbData.radius * 3.0;

        //Skip the windup animation if requested
        if(data.mStateData_ != null && data.mStateData_.skipWindupAnimation){
            mStage_ = 1;
            mTransitionInProgress_ = true;
            mTransitionTime_ = 0.0;
            mTransitionStartCamPos_ = data.getLogic().mCurrentCameraPosition_.copy();
            mTransitionStartLookAt_ = data.getLogic().mCurrentCameraLookAt_.copy();
            mWaitingForAnimationReady_ = false;
        }else{
            //Wait for the splash screen to finish before starting animation
            mWaitingForAnimationReady_ = true;
        }

        pickNewTargetRegion_(data);
    }

    function end(data){
        data.getLogic().mCurrentCameraPosition_ = mCamPos_;
        data.getLogic().mCurrentCameraLookAt_ = mLookAtPos_;
    }

    function notify(obj, data){
        if(mWaitingForAnimationReady_ && data == 0xFF){
            mWaitingForAnimationReady_ = false;
            mStage_ = 0;
        }
    }

    function pickNewTargetRegion_(data){
        local regionEntries = data.getWorld().mRegionEntries_;
        if(regionEntries.len() == 0){
            mTargetPosition_ = mCentrePosition_.copy();
            return;
        }

        //Update start position to current position for smooth transition (only if target exists)
        if(mStartCentrePosition_ != null && mTargetPosition_ != null){
            mStartCentrePosition_ = ::calculateSimpleAnimation(mStartCentrePosition_, mTargetPosition_, 1.0);
        }

        //Pick a random region
        local regionArray = [];
        foreach(c,i in regionEntries){
            if(i != null){
                regionArray.append(i);
            }
        }

        if(regionArray.len() > 0){
            local randomRegion = regionArray[_random.randIndex(regionArray)];
            local aabb = randomRegion.calculateAABB();
            if(aabb != null){
                mTargetPosition_ = aabb.getCentre();
            }else{
                mTargetPosition_ = mCentrePosition_.copy();
            }
        }else{
            mTargetPosition_ = mCentrePosition_.copy();
        }

        mMovementTime_ = 0.0;
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        //Stage -1: Waiting for animation ready signal
        if(mStage_ == -1){
            return;
        }
        //Stage 0: Zoom in from wide view to bird's eye position above landmass
        else if(mStage_ == 0){
            mZoomAnimTime_ += 0.02;

            local zoomProgress = mZoomAnimTime_ / mZoomInDuration_;
            local zoomProgressEasedX = ::Easing.easeInOutSine(zoomProgress);
            local zoomProgressEasedY = ::Easing.easeInOutCubic(zoomProgress);
            local zoomProgressEasedZ = ::Easing.easeInOutSine(zoomProgress);

            //Start from a far position on the negative X side
            local startCamX = mCentrePosition_.x - mInitialOrbitRadius_;
            local startCamZ = mCentrePosition_.z + mInitialOrbitRadius_;
            local startCamY = mCentrePosition_.y + mOrbitHeight_ * 0.2;
            local startCamPos = Vec3(startCamX, startCamY, startCamZ);

            //Target: bird's eye view with slight Z offset for better perspective
            local targetCamX = mCentrePosition_.x - mOrbitRadius_ * 0.1;
            local targetCamZ = mCentrePosition_.z + mOrbitRadius_ * 2.0;
            local targetCamY = mCentrePosition_.y + mOrbitRadius_ * 2.0;
            local targetCamPos = Vec3(targetCamX, targetCamY, targetCamZ);

            //Interpolate with different easing curves for each axis
            local finalCamX = ::mix(startCamPos.x, targetCamPos.x, zoomProgressEasedX);
            local finalCamY = ::mix(startCamPos.y, targetCamPos.y, zoomProgressEasedY);
            local finalCamZ = ::mix(startCamPos.z, targetCamPos.z, zoomProgressEasedZ);
            local finalCamPos = Vec3(finalCamX, finalCamY, finalCamZ);

            if(mZoomAnimTime_ >= mZoomInDuration_){
                mZoomAnimTime_ = mZoomInDuration_;
                mStage0EndCamPos_ = finalCamPos.copy();
                mStage_ = 1;
            }

            camera.getParentNode().setPosition(finalCamPos);
            camera.lookAt(mCentrePosition_);

            mCamPos_ = finalCamPos;
            mLookAtPos_ = mCentrePosition_.copy();

            mTime_ += 0.001;
        }
        //Stage 1: Move around and explore
        else if(mStage_ == 1){
            //If transition setup needed, do it first without updating animation
            if(mStage0EndCamPos_ != null && !mTransitionSetupDone_){
                mTransitionInProgress_ = true;
                mTransitionTime_ = 0.0;
                mTransitionStartCamPos_ = mStage0EndCamPos_;
                mTransitionStartLookAt_ = mCentrePosition_.copy();
                mStage0EndCamPos_ = null;
                mTransitionSetupDone_ = true;

                //Reset movement time so orbital animation starts fresh
                mMovementTime_ = 0.0;
                mTime_ = 0.0;

                //Keep camera at Stage 0 end position for this frame
                camera.getParentNode().setPosition(mTransitionStartCamPos_);
                camera.lookAt(mTransitionStartLookAt_);

                mCamPos_ = mTransitionStartCamPos_;
                mLookAtPos_ = mTransitionStartLookAt_;
                return;
            }

            mTime_ += 0.001;
            mMovementTime_ += 0.02;

            //Check if we need to pick a new target
            if(mMovementTime_ >= mMovementDuration_){
                pickNewTargetRegion_(data);
            }

            //Apply easing to the movement progress
            local movementProgress = mMovementTime_ / mMovementDuration_;
            movementProgress = ::Easing.easeInOutQuad(movementProgress);

            //Interpolate centre position towards target
            local currentCentre = ::calculateSimpleAnimation(mStartCentrePosition_, mTargetPosition_, movementProgress);

            //Apply sin wave for smooth oscillation within the segment
            local oscillation = sin(mTime_ * mOrbitSpeed_);
            local angle = oscillation * mOrbitAngleRange_ * 0.5;

            //Calculate camera position in an arc around the current centre
            local camX = sin(angle) * (mOrbitRadius_ * 0.8) + currentCentre.x;
            local camZ = cos(angle) * (mOrbitRadius_ * 0.8) + currentCentre.z;
            local camPos = Vec3(camX, currentCentre.y + (mOrbitHeight_ * 0.8), camZ);

            //Look at the current centre
            local lookAtPos = currentCentre.copy();

            //If transition is in progress, blend between transition and orbital positions
            if(mTransitionInProgress_){
                mTransitionTime_ += 0.02;
                local transitionProgress = mTransitionTime_ / mTransitionDuration_;
                if(transitionProgress >= 1.0){
                    transitionProgress = 1.0;
                    mTransitionInProgress_ = false;
                }

                //Apply easing for smoother transition: slow start then fast
                local transitionProgressEased = ::Easing.easeInQuad(transitionProgress);

                //Blend factor: 1.0 at start (full transition), 0.0 at end (full orbital)
                local blendFactor = 1.0 - transitionProgressEased;

                //Interpolate from Stage 0 end position to orbital position during transition
                local transitionCamPos = ::calculateSimpleAnimation(mTransitionStartCamPos_, camPos, transitionProgressEased);
                local transitionLookAt = ::calculateSimpleAnimation(mTransitionStartLookAt_, lookAtPos, transitionProgressEased);

                //Blend between the two states
                camPos = Vec3(
                    ::mix(transitionCamPos.x, camPos.x, transitionProgressEased),
                    ::mix(transitionCamPos.y, camPos.y, transitionProgressEased),
                    ::mix(transitionCamPos.z, camPos.z, transitionProgressEased)
                );
                lookAtPos = Vec3(
                    ::mix(transitionLookAt.x, lookAtPos.x, transitionProgressEased),
                    ::mix(transitionLookAt.y, lookAtPos.y, transitionProgressEased),
                    ::mix(transitionLookAt.z, lookAtPos.z, transitionProgressEased)
                );
            }

            camera.getParentNode().setPosition(camPos);
            camera.lookAt(lookAtPos);

            mCamPos_ = camPos;
            mLookAtPos_ = lookAtPos;
        }
    }
};

_doFile("res://src/Logic/Overworld/OverworldViewportPositioner.nut");

::OverworldLogic.loadMeta();