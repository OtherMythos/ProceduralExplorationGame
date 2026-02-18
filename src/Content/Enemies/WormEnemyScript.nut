//Attack type enum identifying which attack pattern the worm performs
enum WormAttackType{
    CHOMP,
    ARC_LEAP
}

::WormEnemyScript <- class{
    mEntity_ = null;
    mWorld_ = null;
    mStayDormant_ = false; //Whether the worm should remain in dormant phase
    mParticleSystem_ = null;
    mShrapnelParticles_ = null;
    mDustCloudParticles_ = null;
    mGroundDustParticles_ = null;
    mGroundDustNode_ = null;
    mGroundDustProximity_ = 3.0;     //Max height above ground to show dust
    mWormSegments_ = null;
    mWormHeadNode_ = null;
    mHeadMesh1Node_ = null;
    mHeadMesh2Node_ = null;
    mRootNode_ = null;
    mSetupComplete_ = false;

    //Current attack type and stage within that attack
    mCurrentAttackType_ = WormAttackType.CHOMP;
    mCurrentStage_ = 0;
    mStageTimer_ = 0;

    //Attack definitions table - maps attack type to its ordered stage list.
    //Each stage entry: {duration, transition, update}
    //Populated in constructor after methods exist.
    mAttackDefs_ = null;

    //Tracks which attack to perform next (cycles through available types)
    mAttackIndex_ = 0;
    mAttackOrder_ = null;

    //Chomp attack timings in frames (60 FPS)
    CHASE_STAGE_FRAMES = 180;
    PREPARE_STAGE_FRAMES = 60;
    RISE_STAGE_FRAMES = 20;
    CHOMP_STAGE_FRAMES = 120;
    DESCEND_STAGE_FRAMES = 80;

    //Arc leap attack tweakable values
    mArcLeapDistance_ = 40.0;        //Total horizontal distance of the arc
    mArcLeapHeight_ = 20.0;         //Peak height of the arc above ground
    mArcLeapFlightFrames_ = 360;    //Frames spent flying through the air
    mArcSegmentSpacing_ = 2.0;      //World-space distance between segments during arc flight
    mArcLeapStartPos_ = null;       //World position where the worm emerges
    mArcLeapEndPos_ = null;         //World position where the worm lands
    mArcLeapDirection_ = null;      //Normalised XZ direction of travel

    NUM_SEGMENTS = 5;
    SEGMENT_SCALE = 0.4;
    HEAD_SCALE = 0.5;

    constructor(eid){
        mEntity_ = eid;
        mWormSegments_ = [];

        //Define the order attacks cycle through
        mAttackOrder_ = [
            WormAttackType.CHOMP,
            WormAttackType.ARC_LEAP
        ];
    }

    function _buildAttackDefs(){
        mAttackDefs_ = {};

        //Chomp attack: chase -> prepare -> rise -> chomp -> descend -> dormant
        mAttackDefs_[WormAttackType.CHOMP] <- [
            {duration = 1,                    transition = _transitionToDormant.bindenv(this),         update = null},
            {duration = CHASE_STAGE_FRAMES,   transition = _transitionToChasing.bindenv(this),         update = _updateChasing.bindenv(this)},
            {duration = PREPARE_STAGE_FRAMES, transition = _transitionToPreparing.bindenv(this),       update = null},
            {duration = RISE_STAGE_FRAMES,    transition = _chompTransitionToRising.bindenv(this),     update = _chompUpdateRising.bindenv(this)},
            {duration = CHOMP_STAGE_FRAMES,   transition = _chompTransitionToChomping.bindenv(this),   update = _chompUpdateChomping.bindenv(this)},
            {duration = DESCEND_STAGE_FRAMES, transition = _chompTransitionToDescending.bindenv(this), update = _chompUpdateDescending.bindenv(this)}
        ];

        //Arc leap attack: chase -> prepare -> flight -> dormant
        mAttackDefs_[WormAttackType.ARC_LEAP] <- [
            {duration = 1,                      transition = _transitionToDormant.bindenv(this),           update = null},
            {duration = CHASE_STAGE_FRAMES,     transition = _transitionToChasing.bindenv(this),           update = _updateChasing.bindenv(this)},
            {duration = PREPARE_STAGE_FRAMES,   transition = _transitionToPreparing.bindenv(this),         update = null},
            {duration = mArcLeapFlightFrames_,  transition = _arcTransitionToFlight.bindenv(this),         update = _arcUpdateFlight.bindenv(this)}
        ];
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

        //Create particle system for ground dust on its own child node so it can be repositioned
        mGroundDustNode_ = mRootNode_.createChildSceneNode();
        mGroundDustNode_.setPosition(0, 0, 0);
        mGroundDustParticles_ = _scene.createParticleSystem("giantWormGroundDust");
        mGroundDustParticles_.setEmitting(false);
        mGroundDustNode_.attachObject(mGroundDustParticles_);

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

        _buildAttackDefs();

        mSetupComplete_ = true;
    }

    //=== Attack selection ===

    function _pickNextAttack(){
        mCurrentAttackType_ = mAttackOrder_[mAttackIndex_];
        mAttackIndex_ = (mAttackIndex_ + 1) % mAttackOrder_.len();
    }

    //=== Generic stage machine ===

    function update(frame){
        //Only proceed with animation if active
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

        local stages = mAttackDefs_[mCurrentAttackType_];
        local stageInfo = stages[mCurrentStage_];
        local duration = stageInfo.duration;

        //Handle dormant stage specially – it waits one frame then picks the next attack
        if(mCurrentStage_ == 0){
            if(mStageTimer_ >= duration && !mStayDormant_){
                _pickNextAttack();
                //Re-fetch stages for the newly chosen attack
                stages = mAttackDefs_[mCurrentAttackType_];
                mStageTimer_ = 0;
                mCurrentStage_ = 1;
                stages[1].transition();
            }
            return;
        }

        //Check if current stage has elapsed
        if(mStageTimer_ >= duration){
            mStageTimer_ = 0;
            local nextStage = mCurrentStage_ + 1;
            if(nextStage >= stages.len()){
                //Attack finished – return to dormant
                mCurrentStage_ = 0;
                _transitionToDormant();
            }else{
                mCurrentStage_ = nextStage;
                stages[nextStage].transition();
            }
        }else{
            //Run per-frame update for current stage if one exists
            if(stageInfo.update != null){
                stageInfo.update();
            }
        }
    }

    //=== Shared transitions (used by both attacks) ===

    function _transitionToChasing(){
        //Start particle system and begin chasing player
        mParticleSystem_.setEmitting(true);
        mDustCloudParticles_.setEmitting(false);
        mGroundDustParticles_.setEmitting(false);
    }

    function _updateChasing(){
        //Follow the player while particles are visible
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        world.moveEnemyToPlayer(mEntity_, 0.2);

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

    //Helper to reset all body parts to a clean default state
    function _resetWormBody(){
        for(local i = 0; i < mWormSegments_.len(); i++){
            mWormSegments_[i].setPosition(0, 0, 0);
            local baseRotationY = (i.tofloat() / NUM_SEGMENTS) * 0.3;
            mWormSegments_[i].setOrientation(Quat(baseRotationY, ::Vec3_UNIT_Y));
        }
        mWormHeadNode_.setPosition(0, 0, 0);
        mWormHeadNode_.setOrientation(Quat());
    }

    //Helper to show all body parts and enable emerging particles
    function _showWormBody(){
        _resetWormBody();
        for(local i = 0; i < mWormSegments_.len(); i++){
            mWormSegments_[i].setVisible(true);
        }
        mWormHeadNode_.setVisible(true);
        mParticleSystem_.setEmitting(false);
        mShrapnelParticles_.setEmitting(true);
        mDustCloudParticles_.setEmitting(true);
        mGroundDustNode_.setPosition(0, 0, 0);
        mGroundDustParticles_.setEmitting(true);
    }

    //Helper to animate alternating head meshes based on a time value
    function _animateHeadMeshes(time){
        local meshPhase = (time / PI) % 1.0;
        if(meshPhase < 0.5){
            mHeadMesh1Node_.setVisible(true);
            mHeadMesh2Node_.setVisible(false);
        }else{
            mHeadMesh1Node_.setVisible(false);
            mHeadMesh2Node_.setVisible(true);
        }
    }

    //Find the worm part closest to ground level and position the dust node there.
    //If nothing is close enough, disable emitting.
    function _updateGroundDustForArc(){
        local bestAbsY = 999.0;
        local bestWorldPos = null;
        local groundY = mArcLeapStartPos_.y;

        //Check head
        local headWorldPos = mWormHeadNode_.getDerivedPositionVec3();
        local headDistToGround = abs(headWorldPos.y - groundY);
        if(headDistToGround < bestAbsY){
            bestAbsY = headDistToGround;
            bestWorldPos = headWorldPos;
        }

        //Check segments
        for(local i = 0; i < mWormSegments_.len(); i++){
            local segWorldPos = mWormSegments_[i].getDerivedPositionVec3();
            local segDistToGround = abs(segWorldPos.y - groundY);
            if(segDistToGround < bestAbsY){
                bestAbsY = segDistToGround;
                bestWorldPos = segWorldPos;
            }
        }

        //Only emit dust if the closest part is near ground level
        if(bestWorldPos != null && bestAbsY <= mGroundDustProximity_){
            //Convert world position to local offset from root node
            mGroundDustNode_.setPosition(bestWorldPos.x - mArcLeapStartPos_.x, 0, bestWorldPos.z - mArcLeapStartPos_.z);
            mGroundDustParticles_.setEmitting(true);
        }else{
            mGroundDustParticles_.setEmitting(false);
        }
    }

    //==========================================================
    //  CHOMP ATTACK  (chase -> prepare -> rise -> chomp -> descend)
    //==========================================================

    function _chompTransitionToRising(){
        _showWormBody();
    }

    function _chompUpdateRising(){
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

    function _chompTransitionToChomping(){
        //Segments are already visible and positioned from rising stage
        //Chomping animation will be handled in _chompUpdateChomping
        mShrapnelParticles_.setEmitting(false);
    }

    function _chompUpdateChomping(){
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

        _animateHeadMeshes(time);
    }

    function _chompTransitionToDescending(){
        //Disable dust cloud particles and shrapnel during descent
        mShrapnelParticles_.setEmitting(false);
        mDustCloudParticles_.setEmitting(false);
    }

    function _chompUpdateDescending(){
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

    //==========================================================
    //  ARC LEAP ATTACK  (chase -> prepare -> rise -> flight -> land)
    //==========================================================

    //Fraction of the total arc distance that is underground at each end.
    //Cached per-flight by _arcTransitionToFlight so the sine curve lines up.
    mArcGroundFraction_ = 0.0;

    //Compute a position along the arc.
    //t in [0,1] where 0 = extended start (underground), 1 = extended end (underground).
    //The height curve is a sine that passes through ground level at t = mArcGroundFraction_
    //and t = 1 - mArcGroundFraction_, going negative (underground) outside that range.
    function _arcPositionAtT(t){
        local x = mArcLeapStartPos_.x + (mArcLeapEndPos_.x - mArcLeapStartPos_.x) * t;
        local z = mArcLeapStartPos_.z + (mArcLeapEndPos_.z - mArcLeapStartPos_.z) * t;
        //Map t into the sine so that the visible portion is [gf, 1-gf] -> [0, PI]
        local gf = mArcGroundFraction_;
        local visibleSpan = 1.0 - 2.0 * gf;
        local sineT = ((t - gf) / visibleSpan) * PI;
        local y = mArcLeapStartPos_.y + sin(sineT) * mArcLeapHeight_;
        return Vec3(x, y, z);
    }

    //Compute the tangent direction of the arc at parameter t.
    //Used to orient segments so the head faces the direction of travel.
    function _arcTangentAtT(t){
        local dx = mArcLeapEndPos_.x - mArcLeapStartPos_.x;
        local dz = mArcLeapEndPos_.z - mArcLeapStartPos_.z;
        local gf = mArcGroundFraction_;
        local visibleSpan = 1.0 - 2.0 * gf;
        local sineT = ((t - gf) / visibleSpan) * PI;
        local dy = cos(sineT) * (PI / visibleSpan) * mArcLeapHeight_;
        local tangent = Vec3(dx, dy, dz);
        tangent.normalise();
        return tangent;
    }

    //Build a quaternion that rotates the worm's default up (+Y) to face along a tangent.
    function _orientationFromTangent(tangent){
        //Worm model points along +Y by default (vertical column).
        //We need to rotate +Y to point along the tangent direction.
        local up = Vec3(0, 1, 0);
        local dot = up.dot(tangent);

        //Handle near-parallel and near-antiparallel cases
        if(dot > 0.9999){
            return Quat();
        }
        if(dot < -0.9999){
            return Quat(PI, ::Vec3_UNIT_X);
        }

        local axis = up.cross(tangent);
        axis.normalise();
        local angle = acos(::clampValue(dot, -1.0, 1.0));
        return Quat(angle, axis);
    }

    function _arcTransitionToFlight(){
        //Calculate start and end positions so the worm travels towards the player.
        //Start from the worm's current position and arc over/past the player.
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        local playerPos = world.getPlayerPosition().copy();
        local manager = world.getEntityManager();
        local wormPos = manager.getPosition(mEntity_);

        //Direction from worm to player
        local dirX = playerPos.x - wormPos.x;
        local dirZ = playerPos.z - wormPos.z;
        local dist = sqrt(dirX * dirX + dirZ * dirZ);
        if(dist > 0.001){
            dirX = dirX / dist;
            dirZ = dirZ / dist;
        }else{
            //Fallback to a random direction if on top of the player
            local angle = _random.rand() * PI * 2.0;
            dirX = cos(angle);
            dirZ = sin(angle);
        }

        //Extend start and end by the body length so the worm fully
        //emerges from and disappears into the ground.
        local bodyLength = (NUM_SEGMENTS + 1) * mArcSegmentSpacing_;
        mArcLeapStartPos_ = Vec3(
            wormPos.x - dirX * bodyLength,
            playerPos.y,
            wormPos.z - dirZ * bodyLength
        );
        mArcLeapEndPos_ = Vec3(
            wormPos.x + dirX * (mArcLeapDistance_ + bodyLength),
            playerPos.y,
            wormPos.z + dirZ * (mArcLeapDistance_ + bodyLength)
        );
        mArcLeapDirection_ = Vec3(dirX, 0, dirZ);

        //Calculate the ground fraction - the portion of the total arc that is underground at each end
        local totalDist = mArcLeapDistance_ + 2.0 * bodyLength;
        mArcGroundFraction_ = bodyLength / totalDist;

        //Move the root node to the start position and show the worm immediately
        mRootNode_.setPosition(mArcLeapStartPos_);
        _showWormBody();
        //Disable shrapnel for flight (only used during ground bursts)
        mShrapnelParticles_.setEmitting(false);

        //Position all pieces at t=0 (underground) so nothing flashes for a frame
        local trailStep = mArcSegmentSpacing_ / totalDist;
        local headPos = _arcPositionAtT(0.0);
        local headTangent = _arcTangentAtT(0.0);
        mWormHeadNode_.setPosition(headPos.x - mArcLeapStartPos_.x, headPos.y - mArcLeapStartPos_.y, headPos.z - mArcLeapStartPos_.z);
        mWormHeadNode_.setOrientation(_orientationFromTangent(headTangent));
        for(local i = 0; i < mWormSegments_.len(); i++){
            local segT = 0.0 - (i + 1) * trailStep;
            if(segT < 0.0) segT = 0.0;
            local segPos = _arcPositionAtT(segT);
            local segTangent = _arcTangentAtT(segT);
            mWormSegments_[i].setPosition(segPos.x - mArcLeapStartPos_.x, segPos.y - mArcLeapStartPos_.y, segPos.z - mArcLeapStartPos_.z);
            mWormSegments_[i].setOrientation(_orientationFromTangent(segTangent));
        }
    }

    function _arcUpdateFlight(){
        local progress = mStageTimer_.tofloat() / mArcLeapFlightFrames_;

        //Total body length in local units (segments + head)
        local bodyLength = (NUM_SEGMENTS + 1) * mArcSegmentSpacing_;
        local totalArcDist = mArcLeapDistance_ + 2.0 * bodyLength;

        //The head leads at parameter t = progress.
        //Each successive body segment trails behind by one segment spacing in arc parameter space.
        local trailStep = mArcSegmentSpacing_ / totalArcDist;

        //Position head
        local headT = progress;
        local headPos = _arcPositionAtT(headT);
        local headTangent = _arcTangentAtT(headT);
        mRootNode_.setPosition(mArcLeapStartPos_);
        mWormHeadNode_.setPosition(headPos.x - mArcLeapStartPos_.x, headPos.y - mArcLeapStartPos_.y, headPos.z - mArcLeapStartPos_.z);
        mWormHeadNode_.setOrientation(_orientationFromTangent(headTangent));

        //Position body segments trailing behind the head
        for(local i = 0; i < mWormSegments_.len(); i++){
            //Segment 0 is closest to head, last segment is the tail
            local segT = headT - (i + 1) * trailStep;
            //Clamp so segments that haven't emerged yet stay at the start
            if(segT < 0.0) segT = 0.0;
            if(segT > 1.0) segT = 1.0;

            local segPos = _arcPositionAtT(segT);
            local segTangent = _arcTangentAtT(segT);
            mWormSegments_[i].setPosition(segPos.x - mArcLeapStartPos_.x, segPos.y - mArcLeapStartPos_.y, segPos.z - mArcLeapStartPos_.z);
            mWormSegments_[i].setOrientation(_orientationFromTangent(segTangent));
        }

        //Animate head mesh alternation during flight
        local time = progress * PI * 3;
        _animateHeadMeshes(time);

        //Position ground dust near the lowest part close to the ground
        _updateGroundDustForArc();
    }


}
