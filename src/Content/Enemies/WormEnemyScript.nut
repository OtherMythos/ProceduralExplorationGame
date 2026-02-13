::WormEnemyScript <- class{
    mEntity_ = null;
    mWorld_ = null;
    mParticleSystem_ = null;
    mShrapnelParticles_ = null;
    mDustCloudParticles_ = null;
    mGroundDustParticles_ = null;
    mWormSegments_ = null;
    mWormHeadNode_ = null;
    mHeadMesh1Node_ = null;
    mHeadMesh2Node_ = null;
    mRootNode_ = null;
    mSetupComplete_ = false;

    //Stage timings in frames (60 FPS)
    //0=dormant, 1=chasing, 2=preparing, 3=rising, 4=chomping, 5=descending
    mCurrentStage_ = 0;
    mStageTimer_ = 0;

    CHASE_STAGE_FRAMES = 180; //Time spent chasing player
    PREPARE_STAGE_FRAMES = 60; //Pause before emerging
    RISE_STAGE_FRAMES = 20;
    CHOMP_STAGE_FRAMES = 120;
    DESCEND_STAGE_FRAMES = 80;

    NUM_SEGMENTS = 5;
    SEGMENT_SCALE = 0.4;
    HEAD_SCALE = 0.5;

    constructor(eid){
        mEntity_ = eid;
        mWormSegments_ = [];
    }

    function setup(eid, rootNode){
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        local manager = world.getEntityManager();
        local pos = manager.getPosition(mEntity_);

        //Use the passed-in root node for the worm
        mRootNode_ = rootNode;
        mRootNode_.setPosition(pos);

        //Create particle system for the emerging stage
        mParticleSystem_ = _scene.createParticleSystem("giantWormEmerging");
        mParticleSystem_.setEmitting(false);
        mRootNode_.attachObject(mParticleSystem_);

        //Create particle system for shrapnel fountain effect
        mShrapnelParticles_ = _scene.createParticleSystem("giantWormShrapnel");
        mShrapnelParticles_.setEmitting(false);
        mRootNode_.attachObject(mShrapnelParticles_);

        //Create particle system for ground dust at base of worm
        mGroundDustParticles_ = _scene.createParticleSystem("giantWormGroundDust");
        mGroundDustParticles_.setEmitting(false);
        mRootNode_.attachObject(mGroundDustParticles_);

        //Create worm segments (will be hidden initially)
        for(local i = 0; i < NUM_SEGMENTS; i++){
            local segmentNode = mRootNode_.createChildSceneNode();
            segmentNode.setPosition(0, 0, 0);
            local cube = _gameCore.createVoxMeshItem("giantWorm.body.voxMesh");
            cube.setDatablock("baseVoxelMaterial");
            cube.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
            segmentNode.attachObject(cube);
            //Add slight random scale variation to prevent z-fighting
            local randomOffsetSegment = (_random.rand() - 0.5) * 0.02 * SEGMENT_SCALE * 2;
            local finalSegmentScale = SEGMENT_SCALE + randomOffsetSegment;
            segmentNode.setScale(finalSegmentScale, finalSegmentScale, finalSegmentScale);
            //Add slight Y-axis rotation for rippling effect
            local baseRotationY = (i.tofloat() / NUM_SEGMENTS) * 0.3; //Ripple through segments
            segmentNode.setOrientation(Quat(baseRotationY, ::Vec3_UNIT_Y));
            segmentNode.setVisible(false);
            mWormSegments_.push(segmentNode);
        }

        //Create worm head (slightly larger)
        mWormHeadNode_ = mRootNode_.createChildSceneNode();
        mWormHeadNode_.setPosition(0, 0, 0);
        //Add slight random scale variation to prevent z-fighting
        local randomOffsetHead = (_random.rand() - 0.5) * 0.02 * HEAD_SCALE * 2;
        local finalHeadScale = HEAD_SCALE + randomOffsetHead;
        mWormHeadNode_.setScale(finalHeadScale, finalHeadScale, finalHeadScale);
        //Add Y-axis rotation for rippling effect
        local headBaseRotationY = 0.0; //Head starts at neutral for full ripple range
        mWormHeadNode_.setOrientation(Quat(headBaseRotationY, ::Vec3_UNIT_Y));

        //Create particle system for dust cloud from worm body (attached to head)
        mDustCloudParticles_ = _scene.createParticleSystem("giantWormDustCloud");
        mDustCloudParticles_.setEmitting(false);
        local headParticleNode = mWormHeadNode_.createChildSceneNode();
        headParticleNode.setPosition(0, -8, 0);
        headParticleNode.attachObject(mDustCloudParticles_);

        //Create first head mesh variant
        mHeadMesh1Node_ = mWormHeadNode_.createChildSceneNode();
        local head1 = _gameCore.createVoxMeshItem("giantWorm.head.1.voxMesh");
        head1.setDatablock("baseVoxelMaterial");
        head1.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        mHeadMesh1Node_.attachObject(head1);
        mHeadMesh1Node_.setVisible(false);

        //Create second head mesh variant
        mHeadMesh2Node_ = mWormHeadNode_.createChildSceneNode();
        local head2 = _gameCore.createVoxMeshItem("giantWorm.head.2.voxMesh");
        head2.setDatablock("baseVoxelMaterial");
        head2.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        mHeadMesh2Node_.attachObject(head2);
        mHeadMesh2Node_.setVisible(false);

        mWormHeadNode_.setVisible(false);

        //manager.assignComponent(mEntity_, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](mRootNode_, true));
        mSetupComplete_ = true;
    }

    function update(frame){
        if(!mSetupComplete_){
            //Get root node from scene node component
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local manager = world.getEntityManager();
            local sceneNodeComponent = manager.getComponent(mEntity_, EntityComponents.SCENE_NODE);
            if(sceneNodeComponent != null){
                setup(mEntity_, sceneNodeComponent.mNode);
            }
        }
        mStageTimer_++;

        switch(mCurrentStage_){
            case 0:{ //Dormant stage
                if(mStageTimer_ >= 1){
                    mStageTimer_ = 0;
                    mCurrentStage_ = 1;
                    _transitionToChasing();
                }
                break;
            }
            case 1:{ //Chasing stage - follow player with particles visible
                if(mStageTimer_ >= CHASE_STAGE_FRAMES){
                    mStageTimer_ = 0;
                    mCurrentStage_ = 2;
                    _transitionToPreparing();
                }else{
                    _updateChasing();
                }
                break;
            }
            case 2:{ //Preparing stage - pause before emerging
                if(mStageTimer_ >= PREPARE_STAGE_FRAMES){
                    mStageTimer_ = 0;
                    mCurrentStage_ = 3;
                    _transitionToRising();
                }
                break;
            }
            case 3:{ //Rising stage
                if(mStageTimer_ >= RISE_STAGE_FRAMES){
                    mStageTimer_ = 0;
                    mCurrentStage_ = 4;
                    _transitionToChomping();
                }else{
                    _updateRising();
                }
                break;
            }
            case 4:{ //Chomping stage
                if(mStageTimer_ >= CHOMP_STAGE_FRAMES){
                    mStageTimer_ = 0;
                    mCurrentStage_ = 5;
                    _transitionToDescending();
                }else{
                    _updateChomping();
                }
                break;
            }
            case 5:{ //Descending stage
                if(mStageTimer_ >= DESCEND_STAGE_FRAMES){
                    mStageTimer_ = 0;
                    mCurrentStage_ = 0;
                    _transitionToDormant();
                }else{
                    _updateDescending();
                }
                break;
            }
        }
    }

    function _transitionToRising(){
        //Show all worm segments and head
        for(local i = 0; i < mWormSegments_.len(); i++){
            mWormSegments_[i].setVisible(true);
        }
        mWormHeadNode_.setVisible(true);
        mParticleSystem_.setEmitting(false);
        mShrapnelParticles_.setEmitting(true);
        mDustCloudParticles_.setEmitting(true);
        mGroundDustParticles_.setEmitting(true);
    }

    function _transitionToChasing(){
        //Start particle system and begin chasing player
        mParticleSystem_.setEmitting(true);
        mDustCloudParticles_.setEmitting(false);
        mGroundDustParticles_.setEmitting(false);
    }

    function _updateChasing(){
        //Follow the player while particles are visible
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        world.moveEnemyToPlayer(mEntity_);

        //Update root node position to match entity
        local manager = world.getEntityManager();
        local pos = manager.getPosition(mEntity_);
        mRootNode_.setPosition(pos);
    }

    function _transitionToPreparing(){
        //Particle system continues emitting, but worm pauses movement
    }

    function _transitionToDormant(){
        //Hide all worm segments
        for(local i = 0; i < mWormSegments_.len(); i++){
            mWormSegments_[i].setVisible(false);
        }
        mWormHeadNode_.setVisible(false);
        mParticleSystem_.setEmitting(false);
        mShrapnelParticles_.setEmitting(false);
        mDustCloudParticles_.setEmitting(false);
        mGroundDustParticles_.setEmitting(false);
    }

    function _transitionToChomping(){
        //Segments are already visible and positioned from rising stage
        //Chomping animation will be handled in _updateChomping
        mShrapnelParticles_.setEmitting(false);
    }

    function _transitionToDescending(){
        //Disable dust cloud particles and shrapnel during descent
        mShrapnelParticles_.setEmitting(false);
        mDustCloudParticles_.setEmitting(false);
    }

    function _updateRising(){
        //Rise from ground - progress from 0 to 1
        local progress = mStageTimer_.tofloat() / RISE_STAGE_FRAMES;

        //Position segments as a rising column
        for(local i = 0; i < mWormSegments_.len(); i++){
            local segmentY = (i * 1.5) * progress; //Each segment is 1.5 units apart
            mWormSegments_[i].setPosition(0, segmentY - HEAD_SCALE, 0);
        }

        //Position head above segments
        local headY = (NUM_SEGMENTS * 1.5) * progress;
        mWormHeadNode_.setPosition(0, headY - HEAD_SCALE, 0);
    }

    function _updateChomping(){
        //Segments already positioned at max height
        //Add sine wave animation to segments
        local progress = mStageTimer_.tofloat() / CHOMP_STAGE_FRAMES;
        local time = progress * PI * 3; //Four complete cycles during chomp - faster animation

        for(local i = 0; i < mWormSegments_.len(); i++){
            local baseY = (i * 1.5);
            local waveOffset = sin(time + (i * 0.3)) * 0.15; //Sine wave with phase offset per segment
            mWormSegments_[i].setPosition(waveOffset, baseY + waveOffset * 0.1 - HEAD_SCALE, 0);

            //Add rippling Y-axis rotation
            local baseRotationY = (i.tofloat() / NUM_SEGMENTS) * 0.3;
            local rippleRotation = sin(time + (i * 0.3)) * 0.15;
            mWormSegments_[i].setOrientation(Quat(baseRotationY + rippleRotation, ::Vec3_UNIT_Y));
        }

        //Head follows with more amplitude
        local baseHeadY = (NUM_SEGMENTS * 1.5);
        local headWave = sin(time) * 0.2;
        mWormHeadNode_.setPosition(headWave, baseHeadY + headWave * 0.1 - HEAD_SCALE, 0);
        //Add rippling Y-axis rotation to head
        local headBaseRotationY = 0.0;
        local headRippleRotation = sin(time) * 0.45;
        mWormHeadNode_.setOrientation(Quat(headBaseRotationY + headRippleRotation, ::Vec3_UNIT_Y));

        //Alternate head mesh variants based on animation phase
        local meshPhase = (time / (PI)) % 1.0; //0 to 1 over each cycle
        if(meshPhase < 0.5){
            mHeadMesh1Node_.setVisible(true);
            mHeadMesh2Node_.setVisible(false);
        }else{
            mHeadMesh1Node_.setVisible(false);
            mHeadMesh2Node_.setVisible(true);
        }
    }

    function _updateDescending(){
        //Descend back into ground - progress from 1 to 0
        local progress = 1.0 - (mStageTimer_.tofloat()) / DESCEND_STAGE_FRAMES;

        //Position segments descending
        for(local i = 0; i < mWormSegments_.len(); i++){
            local segmentY = (i * 1.5) * progress;
            mWormSegments_[i].setPosition(0, segmentY - HEAD_SCALE, 0);
        }

        //Position head
        local headY = (NUM_SEGMENTS * 1.5) * progress;
        mWormHeadNode_.setPosition(0, headY - HEAD_SCALE, 0);
    }
}
