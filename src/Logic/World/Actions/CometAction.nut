::CometAction <- class extends WorldAction{

    mStartPos_ = null;
    mLandingPos_ = null;
    mCometNode_ = null;
    mCometMesh_ = null;
    mParticleSystem_ = null;
    mBaseEffectParticleSystem_ = null;
    mFrameCount_ = 0;
    mTotalFrames_ = 180;
    mApproachAngle_ = 0.0;
    mLanded_ = false;
    mLandingFrames_ = 60;
    mFinalShutdownFrames_ = 300;
    mItemSpawned_ = false;

    mCometBaseScale_ = 0.25;

    constructor(creatorWorld, startPos, landingPos){
        base.constructor(creatorWorld);

        mLandingPos_ = landingPos.copy();
        mLandingPos_.y = creatorWorld.getZForPos(mLandingPos_);

        //Generate random approach angle (0 to 2*PI)
        mApproachAngle_ = _random.rand() * PI * 2.0;

        //Calculate offset from landing position based on approach angle
        local offsetDist = 80.0;
        local offsetX = cos(mApproachAngle_) * offsetDist;
        local offsetZ = sin(mApproachAngle_) * offsetDist;

        mStartPos_ = mLandingPos_.copy();
        mStartPos_.x += offsetX;
        mStartPos_.z += offsetZ;
        mStartPos_.y = startPos.y;

        //Create the comet visual
        setupVisuals_();
    }

    function setupVisuals_(){
        mCometNode_ = _scene.getRootSceneNode().createChildSceneNode();
        mCometNode_.setPosition(mStartPos_);

        //Create cube for the comet rock
        local cometItem = _gameCore.createVoxMeshItem("meteor.voxMesh");
        cometItem.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        mCometMesh_ = mCometNode_.createChildSceneNode();
        mCometMesh_.setScale(mCometBaseScale_, mCometBaseScale_, mCometBaseScale_);
        mCometMesh_.attachObject(cometItem);

        //Attach particle system for comet trail
        mParticleSystem_ = _scene.createParticleSystem("cometTrail");
        mCometNode_.attachObject(mParticleSystem_);

        //Attach particle system for comet base effect
        mBaseEffectParticleSystem_ = _scene.createParticleSystem("cometBaseEffect");
        mCometNode_.attachObject(mBaseEffectParticleSystem_);
    }

    function update(){
        if(!mLanded_){
            //Animate comet from start position to landing position at a constant speed
            local animProgress = mFrameCount_.tofloat() / mTotalFrames_.tofloat();

            //Calculate position along the curve without easing for constant speed
            local currentPos = ::calculateSimpleAnimation(mStartPos_, mLandingPos_, animProgress);

            //Add arc to the trajectory
            local arc = sin(animProgress * PI) * 15.0;
            currentPos.y += arc;

            mCometNode_.setPosition(currentPos);

            //Rotate the comet mesh during flight
            local rotationSpeed = 0.05;
            local currentRotation = Quat(mFrameCount_ * rotationSpeed, ::Vec3_UNIT_Y);
            currentRotation *= Quat(mFrameCount_ * rotationSpeed * 0.7, ::Vec3_UNIT_X);
            mCometMesh_.setOrientation(currentRotation);

            mFrameCount_++;

            //Check if landing animation is complete
            if(mFrameCount_ >= mTotalFrames_){
                //Landing sequence
                mLanded_ = true;
                mFrameCount_ = 0;
                onCometLanded_();
            }
        }else{
            //Animate comet shrinking after landing
            mFrameCount_++;

            //Shrink the comet mesh over the landing frames duration
            local shrinkProgress = (mFrameCount_.tofloat() / mLandingFrames_.tofloat());
            shrinkProgress = ::Easing.easeInQuad(shrinkProgress);
            shrinkProgress = 1.0 - shrinkProgress;
            shrinkProgress = ::clampValue(shrinkProgress, 0.0, 1.0);

            local currentScale = mCometBaseScale_ * shrinkProgress;
            mCometMesh_.setScale(currentScale, currentScale, currentScale);

            if(mFrameCount_ >= mLandingFrames_ && !mItemSpawned_){
                //Spawn the item once when fully shrunk
                spawnLandingItem_();
                mItemSpawned_ = true;
            }

            //Wait for particles to dissipate before final cleanup
            if(mFrameCount_ >= mFinalShutdownFrames_){
                cleanup_();
                return false;
            }
        }

        return true;
    }

    function onCometLanded_(){
        //Create damage effect at landing position
        local landPos = mLandingPos_.copy();
        landPos.y = mCreatorWorld_.getZForPos(landPos);

        //Spawn damage sender like in Equippables
        local attackValue = 10;
        mCreatorWorld_.mProjectileManager_.spawnProjectile(ProjectileId.AREA, landPos, ::Vec3_ZERO, ::Combat.CombatMove(attackValue), _COLLISION_ENEMY);

        //Stop the base effect particle system
        if(mBaseEffectParticleSystem_ != null){
            mBaseEffectParticleSystem_.setEmitting(false);
        }
    }

    function spawnLandingItem_(){
        local itemToSpawn = ::Item(ItemId.SIMPLE_SWORD);
        local entityFactory = mCreatorWorld_.getEntityFactory();
        local landPos = mLandingPos_.copy();
        landPos.y = mCreatorWorld_.getZForPos(landPos);

        //Drop the item at the landing position
        entityFactory.constructCollectableItemObject(landPos, itemToSpawn);
    }

    function cleanup_(){
        if(mCometNode_ != null){
            mCometNode_.destroyNodeAndChildren();
            mCometNode_ = null;
        }
    }

    function notifyStart(){

    }

    function notifyEnd(){
        cleanup_();
    }
};
