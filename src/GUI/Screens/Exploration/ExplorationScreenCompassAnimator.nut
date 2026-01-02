::CompassIndicator <- class{
    mDistance_ = 0.0;
    mRadian_ = 0.0;
    mSceneNode_ = null;
    mPanelTrackNode_ = null;
    mWorldId_ = -1;

    constructor(worldId, distance, radian, parentNode, compassNode, window){
        mWorldId_ = worldId;
        local target = parentNode.createChildSceneNode();
        local indicatorPlane = _scene.createItem("plane");
        //indicatorPlane.setDatablock("guiExplorationCompassIndicator");

        indicatorPlane.setRenderQueueGroup(74);
        target.setScale(0.08, 0.08, 0.08);
        target.attachObject(indicatorPlane);
        mSceneNode_ = target;

        mPanelTrackNode_ = compassNode.createChildSceneNode();

        setPosition(distance, radian);
    }

    function setPosition(distance, radian){
        mDistance_ = distance;
        mRadian_ = radian;
        local x = cos(radian) * distance;
        local y = sin(radian) * distance;
        mSceneNode_.setPosition(x, y, 0);
        mPanelTrackNode_.setPosition(x, y, 0);
    }

    function setType(type){
        if(type == CompassIndicatorType.ENEMY){
            mSceneNode_.getAttachedObject(0).setDatablock("guiExplorationCompassIndicatorEnemy");
        }else if(type == CompassIndicatorType.NPC){
            mSceneNode_.getAttachedObject(0).setDatablock("guiExplorationCompassIndicatorNPC");
        }
    }

    function updatePanelPosition(){
        local derivedPos = mPanelTrackNode_.getDerivedPositionVec3();
        mSceneNode_.setPosition(derivedPos);
    }

    function shutdown(){
        mSceneNode_.destroyNodeAndChildren();
        mPanelTrackNode_.destroyNodeAndChildren();
        mSceneNode_ = null;
        mPanelTrackNode_ = null;
    }
};

::ExplorationScreenCompassAnimator <- class{
    mTexture_ = null;
    mStoredTexture_ = null;
    mDatablock_ = null;
    mShadowDatablock_ = null;

    mCompassWindow_ = null;
    mCompassPanel_ = null;
    mShadowPanels_ = null;
    mParentNode_ = null;
    mCompassNode_ = null;

    mRenderWorkspace_ = null;

    mDirectionNodes_ = null;
    mCompassIndicators_ = null;
    mCompassIndicatorPool_ = null;

    mWorldNodes_ = null;
    mCurrentWorldId_ = -1;

    constructor(window, size){

        mDirectionNodes_ = [];
        mCompassIndicators_ = [];
        mCompassIndicatorPool_ = ::VersionPool();

        mWorldNodes_ = {};

        local texture = _graphics.createTexture("explorationCompassTexture");
        texture.setResolution((size.x * ::resolutionMult.x).tointeger(), (size.y.tointeger() * ::resolutionMult.y).tointeger());
        texture.setPixelFormat(_PFG_RGBA8_UNORM);
        texture.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);

        mTexture_ = texture;
        mRenderWorkspace_ = _compositor.addWorkspace([texture], _camera.getCamera(), "compositor/GamplayExplorationCompassWorkspace", true);
        //mRenderWorkspace_.update();

        local blendBlock = _hlms.getBlendblock({
            "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
            "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
            "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
            "dst_alpha_blend_factor": _HLMS_SBF_ONE
        });
        local datablock = _hlms.unlit.createDatablock("gameplayExplorationCompassDatablock", blendBlock);
        datablock.setTexture(0, texture);
        //mIconBackground_.setDatablock(datablock);
        mDatablock_ = datablock;

        //Create shadow datablock with black diffuse colour
        local shadowDatablock = _hlms.unlit.createDatablock("gameplayExplorationCompassShadowDatablock", blendBlock);
        shadowDatablock.setTexture(0, texture);
        shadowDatablock.setColour(ColourValue(0, 0, 0, 1));
        mShadowDatablock_ = shadowDatablock;

        mCompassWindow_ = window.createWindow();
        mCompassWindow_.setClickable(false);
        mCompassWindow_.setPosition(0, ::drawable.y - 150);
        mCompassWindow_.setSize(400, 200);
        mCompassWindow_.setClipBorders(0, 0, 0, 0);
        mCompassWindow_.setVisualsEnabled(false);

        mShadowPanels_ = [];

        //Create four shadow panels with offsets
        local shadowOffsets = [
            Vec2(0.5, 0.5),
            Vec2(-0.5, 0.5),
            Vec2(0.5, -0.5),
            Vec2(-0.5, -0.5)
        ];

        for(local i = 0; i < 4; i++){
            local shadowPanel = mCompassWindow_.createPanel();
            shadowPanel.setClickable(false);
            shadowPanel.setSize(400, 300);
            shadowPanel.setPosition(shadowOffsets[i].x, shadowOffsets[i].y - 100);
            shadowPanel.setDatablock(mShadowDatablock_);
            mShadowPanels_.append(shadowPanel);
        }

        local compassPanel = mCompassWindow_.createPanel();
        //compassPanel.setPosition(0, ::drawable.y - 250);
        compassPanel.setClickable(false);
        compassPanel.setSize(400, 300);
        compassPanel.setPosition(0, -100);
        mCompassPanel_ = compassPanel;

        local node = _scene.getRootSceneNode().createChildSceneNode();
        local compassNode = node.createChildSceneNode();
        local item = _scene.createItem("plane");
        item.setRenderQueueGroup(74);
        compassNode.attachObject(item);
        compassNode.setOrientation(Quat(0, 0, 1, sqrt(0.1)));
        node.setPosition(0, 0, -3);
        item.setDatablock("guiExplorationCompass");
        mCompassNode_ = compassNode;
        mParentNode_ = node;
        compassPanel.setDatablock(mDatablock_);

        for(local i = 0; i < 4; i++){
            local target = node.createChildSceneNode();
            local track = mCompassNode_.createChildSceneNode();
            local dirPlane = _scene.createItem("plane");
            dirPlane.setDatablock(getDatablock_(i));
            dirPlane.setRenderQueueGroup(74);
            target.setScale(0.1, 0.1, 0.1);
            local pos = getDirection_(i);
            target.setPosition(pos);
            track.setPosition(pos);
            //target.setOrientation(Quat(PI * 0.75, ::Vec3_UNIT_X));
            //target.setPosition(0, 0, 0);
            target.attachObject(dirPlane);
            mDirectionNodes_.append([target, track]);
            //target.setScale(0.5, 0.5, 0.5);
        }

        mStoredTexture_ = ::CompositorManager.addExtraTexture(texture);
    }

    function setVisible(visible){
        mCompassWindow_.setVisible(visible);
    }

    function setCurrentWorld(worldId){
        mCurrentWorldId_ = worldId;
        foreach(id, node in mWorldNodes_){
            node.setVisible(id == worldId);
        }
    }

    function getWorldNode_(worldId){
        if(!mWorldNodes_.rawin(worldId)){
            local node = mParentNode_.createChildSceneNode();
            mWorldNodes_.rawset(worldId, node);

            node.setVisible(worldId == mCurrentWorldId_);
        }
        return mWorldNodes_[worldId];
    }

    function addCompassIndicator(worldId, distance, radian){
        local node = getWorldNode_(worldId);
        local indicator = CompassIndicator(worldId, distance, radian, node, mCompassNode_, mCompassWindow_);
        local id = mCompassIndicatorPool_.store(indicator);
        mCompassIndicators_.append(id);
        return id;
    }

    function removeCompassIndicator(id){
        if(!mCompassIndicatorPool_.valid(id)){
            return;
        }
        local indicator = mCompassIndicatorPool_.get(id);
        if(indicator != null){
            indicator.shutdown();
        }
        mCompassIndicatorPool_.unstore(id);
        mCompassIndicators_.remove(mCompassIndicators_.find(id));
    }

    function updateCompassIndicatorPosition(id, distance, radian){
        if(!mCompassIndicatorPool_.valid(id)){
            return;
        }
        local indicator = mCompassIndicatorPool_.get(id);
        if(indicator != null){
            indicator.setPosition(distance, radian);
        }
    }

    function setCompassIndicatorType(id, type){
        if(!mCompassIndicatorPool_.valid(id)){
            return;
        }
        local indicator = mCompassIndicatorPool_.get(id);
        if(indicator != null){
            indicator.setType(type);
        }
    }

    function getDatablock_(dir){
        switch(dir){
            case 0:
                return "guiExplorationCompassSouth";
            case 1:
                return "guiExplorationCompassEast";
            case 2:
                return "guiExplorationCompassNorth";
            case 3:
                return "guiExplorationCompassWest";
            default:
                assert(false);
        }
    }

    function getDirection_(dir){
        switch(dir){
            case 0:
                //North
                return Vec3(1, 0, 0);
            case 1:
                //East
                return Vec3(0, 1, 0);
            case 2:
                //South
                return Vec3(-1, 0, 0);
            case 3:
                //East
                return Vec3(0, -1, 0);

            default:
                return Vec3();
        }
    }

    function shutdown(){
        //Clean up all compass indicators
        foreach(indicatorId in mCompassIndicators_){
            if(mCompassIndicatorPool_.valid(indicatorId)){
                local indicator = mCompassIndicatorPool_.get(indicatorId);
                if(indicator != null){
                    indicator.shutdown();
                }
                mCompassIndicatorPool_.unstore(indicatorId);
            }
        }

        _compositor.removeWorkspace(mRenderWorkspace_);
        _gui.destroy(mCompassWindow_);
        _hlms.destroyDatablock(mDatablock_);
        _hlms.destroyDatablock(mShadowDatablock_);
        ::CompositorManager.removeExtraTexture(mStoredTexture_);
        _graphics.destroyTexture(mTexture_);
        mCompassNode_.destroyNodeAndChildren();
        mParentNode_.destroyNodeAndChildren();

        mCompassWindow_ = null;
        mCompassPanel_ = null;
        mShadowPanels_ = null;
        mTexture_ = null;
        mDatablock_ = null;
        mShadowDatablock_ = null;
        mParentNode_ = null;
        mCompassNode_ = null;
        mDirectionNodes_ = null;
        mCompassIndicators_ = null;
        mCompassIndicatorPool_ = null;
        mWorldNodes_ = null;
    }

    function getPosition(){
        return mCompassWindow_.getPosition();
    }

    function getSize(){
        return mCompassWindow_.getSize();
    }

    function update(){
        local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
        local currentRotation = currentWorld.mRotation_.x;
        local currentYRotation = currentWorld.mRotation_.y;

        //print(currentYRotation);

        local range =
            (PI * 0.5) - (PI * 0.1);
        local animOther = (currentYRotation - (PI * 0.1)) / range;
        //print(animOther);

        local compassOrientation = Quat();
        compassOrientation *= Quat(PI / 2 + 0.20, ::Vec3_UNIT_X);
        //compassOrientation *= Quat(animCount % 0.15, ::Vec3_UNIT_X);
        //compassOrientation *= Quat(PI * 2 * ::animCount, ::Vec3_UNIT_Z);
        compassOrientation *= Quat(animOther * 0.1, ::Vec3_UNIT_X);
        //if(currentRotation < 0) currentRotation = -currentRotation;
        //print(currentRotation);
        local an = (currentRotation % (PI * 2)) / (PI * 2);
        //print(an);
        compassOrientation *= Quat(PI * 2 * (-an), ::Vec3_UNIT_Z);

        // Camera "right" axis in world space
        local cameraNode = _camera.getCamera().getParentNode();
        local cameraRight = cameraNode.getOrientation() * Vec3(1,0,0);

        // Transform into plane local space
        local planeRightLocal = compassOrientation.inverse() * cameraRight;
        planeRightLocal.normalise();

        // Now build scale vector
        // Start at (1,1,1), then add extra scale along that local axis
        // We want 1.5 instead of 1.0 → factor = 0.5
        local extra = planeRightLocal * 0.5;
        local scale = Vec3(1,1,1) + extra.abs(); // abs to keep positive scale
        //print(extra);


        //mCompassNode_.setScale(1.5, 1, 1);
        mCompassNode_.setOrientation(compassOrientation);
        //mCompassNode_.setScale(scale.x, scale.z, 1);
        mCompassNode_.setScale(1.5, 1.5, 1);

        foreach(i in mDirectionNodes_){
            i[0].setPosition(i[1].getDerivedPositionVec3());
            //i[0].lookAt(_camera.getPosition());
        }

        //Update compass indicator positions
        foreach(indicatorId in mCompassIndicators_){
            if(mCompassIndicatorPool_.valid(indicatorId)){
                local indicator = mCompassIndicatorPool_.get(indicatorId);
                if(indicator != null && indicator.mWorldId_ == mCurrentWorldId_){
                    indicator.updatePanelPosition();
                }
            }
        }

    }
}
