//State enumeration
enum GeyserState{
    NONE,

    DORMANT,
    WARMING_UP,
    WARMED_UP,
    FIRING,
    COOLING_DOWN,

    MAX
};

::GeyserScript <- class{
    mParentNode_ = null;
    mFountainParticles_ = null;
    mInnerFountainParticles_ = null;
    mWarmingUpFountainParticles_ = null;
    mFrameCounter_ = 0;
    mWorld_ = null;
    mPosition_ = null;
    mCameraEffectCollisionPoint_ = null;
    mDamageCollisionPoint_ = null;

    //Native mesh particle emitters
    mWaterEmitter_ = null;
    mBaseEmitter_ = null;
    mPlumeEmitter_ = null;

    //State machine
    mStateMachine_ = null;
    mCurrentState_ = null;

    //Flags for particle emission
    mIsEmittingWater_ = false;
    mIsEmittingBase_ = false;

    //Tweakable parameters for water particle animation
    mWaterVelocityMin_ = 1.0;
    mWaterVelocityMax_ = 1.0;
    mWaterGravity_ = 0.03;
    mWaterAngleSpread_ = 25;
    mWaterEmissionRate_ = 1;
    mWaterMaxLifetime_ = 80;

    //Tweakable parameters for base particle animation
    mBaseVelocity_ = 0.15;
    mBaseGravity_ = 0.02;
    mBaseSpawnRadius_ = 3.0;
    mBaseEmissionRate_ = 4;
    mBaseMaxLifetime_ = 60;

    //State timing configuration (in frames)
    mDormantDuration_ = 225;
    mWarmingUpDuration_ = 300;
    mFiringDuration_ = 300;
    mCoolingDownDuration_ = 15;

    constructor(eid, parentNode, fountainParticles, innerFountainParticles, warmingUpFountainParticles, world, position){
        mParentNode_ = parentNode;
        mFountainParticles_ = fountainParticles;
        mInnerFountainParticles_ = innerFountainParticles;
        mWarmingUpFountainParticles_ = warmingUpFountainParticles;
        mWorld_ = world;
        mPosition_ = position;
        mCameraEffectCollisionPoint_ = null;
        mDamageCollisionPoint_ = null;

        //Initialise native mesh particle emitters
        mWaterEmitter_ = _gameCore.createMeshParticleEmitter(mParentNode_);
        mWaterEmitter_.addMeshVariant("gyserPieces.water1.voxMesh");
        mWaterEmitter_.addMeshVariant("gyserPieces.water2.voxMesh");
        mWaterEmitter_.addMeshVariant("gyserPieces.water3.voxMesh");
        mWaterEmitter_.setGravity(mWaterGravity_);
        mWaterEmitter_.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        mWaterEmitter_.setPoolSize(120);

        mBaseEmitter_ = _gameCore.createMeshParticleEmitter(mParentNode_);
        mBaseEmitter_.addMeshVariant("gyserPieces.water1.voxMesh");
        mBaseEmitter_.addMeshVariant("gyserPieces.water2.voxMesh");
        mBaseEmitter_.addMeshVariant("gyserPieces.water3.voxMesh");
        mBaseEmitter_.setGravity(mBaseGravity_);
        mBaseEmitter_.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        mBaseEmitter_.setPoolSize(360);

        mPlumeEmitter_ = _gameCore.createMeshParticleEmitter(mParentNode_);
        mPlumeEmitter_.addMeshVariant("gyserPieces.plume1.voxMesh");
        mPlumeEmitter_.addMeshVariant("gyserPieces.plume2.voxMesh");
        mPlumeEmitter_.addMeshVariant("gyserPieces.plume3.voxMesh");
        mPlumeEmitter_.setGravity(0);
        mPlumeEmitter_.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        mPlumeEmitter_.setPoolSize(10);

        //Initialise with particles off
        if(mFountainParticles_ != null) mFountainParticles_.setEmitting(false);
        if(mInnerFountainParticles_ != null) mInnerFountainParticles_.setEmitting(false);
        if(mWarmingUpFountainParticles_ != null) mWarmingUpFountainParticles_.setEmitting(false);

        //Initialise state machine
        mStateMachine_ = ::GeyserStateMachine(this);
        mStateMachine_.setState(GeyserState.DORMANT);
        this.mStateMachine_.mStateInstance_.mStateTime_ = _random.randInt(mDormantDuration_);
    }

    function update(eid){
        mFrameCounter_++;

        //Update state machine
        if(mStateMachine_ != null){
            mStateMachine_.update();
        }

        //Emit water particles
        if(mIsEmittingWater_){
            for(local i = 0; i < mWaterEmissionRate_; i++){
                spawnWaterParticle_();
            }
        }

        //Emit base particles
        if(mIsEmittingBase_){
            for(local i = 0; i < mBaseEmissionRate_; i++){
                spawnBaseParticle_();
            }
        }

        //Update all native emitters
        mWaterEmitter_.update();
        mBaseEmitter_.update();
        mPlumeEmitter_.update();
    }

    function setEmissionEnabled_(enabled){
        mIsEmittingWater_ = enabled;
        mIsEmittingBase_ = enabled;
        if(mFountainParticles_ != null) mFountainParticles_.setEmitting(enabled);
        if(mInnerFountainParticles_ != null) mInnerFountainParticles_.setEmitting(enabled);
    }

    function setWarmingUpEmissionEnabled_(enabled){
        if(mWarmingUpFountainParticles_ != null) mWarmingUpFountainParticles_.setEmitting(enabled);
    }

    function addCameraEffectCollisionPoint_(){
        if(mWorld_ == null) return;
        local triggerWorld = mWorld_.getTriggerWorld();
        if(triggerWorld == null) return;

        local effectData = {
            "effectId": CameraEffectId.SHAKE,
            "params": {
                "magnitude": 0.15,
                "duration": 30,
                "frequency": 5
            }
        };
        mCameraEffectCollisionPoint_ = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.CAMERA_EFFECT, effectData, mPosition_.x, mPosition_.z, 8, _COLLISION_PLAYER);
    }

    function removeCameraEffectCollisionPoint_(){
        if(mWorld_ == null || mCameraEffectCollisionPoint_ == null) return;
        local triggerWorld = mWorld_.getTriggerWorld();
        if(triggerWorld == null) return;

        triggerWorld.removeCollisionPoint(mCameraEffectCollisionPoint_);
        mCameraEffectCollisionPoint_ = null;
    }

    function addDamageCollisionPoint_(){
        if(mWorld_ == null) return;
        local damageWorld = mWorld_.getDamageWorld();
        if(damageWorld == null) return;

        mDamageCollisionPoint_ = damageWorld.addCollisionSender(CollisionWorldTriggerResponses.PASSIVE_DAMAGE, 20, mPosition_.x, mPosition_.z, 8, _COLLISION_PLAYER | _COLLISION_ENEMY);
    }

    function removeDamageCollisionPoint_(){
        if(mWorld_ == null || mDamageCollisionPoint_ == null) return;
        local damageWorld = mWorld_.getDamageWorld();
        if(damageWorld == null) return;

        damageWorld.removeCollisionPoint(mDamageCollisionPoint_);
        mDamageCollisionPoint_ = null;
    }

    function spawnGeyserPiece_(){
        //Add slight randomisation to the position and rotation
        local xOffset = (_random.rand() - 0.5) * 0.5;
        local zOffset = (_random.rand() - 0.5) * 0.5;
        local rotationAngle = _random.rand() * PI * 2.0;

        mPlumeEmitter_.emit(xOffset, 0, zOffset, 0, 0, 0, 5, 1.0, 1.0, 0, rotationAngle, 0);
    }

    function spawnWaterParticle_(){
        //Calculate initial velocity with angle spread
        local angleSpreadRad = (mWaterAngleSpread_ / 2.0) * (PI / 180.0);
        local verticalAngle = (_random.rand() - 0.5) * 2.0 * angleSpreadRad;
        local horizontalAngle = _random.rand() * PI * 2.0;

        //Random velocity between min and max
        local velocity = mWaterVelocityMin_ + (_random.rand() * (mWaterVelocityMax_ - mWaterVelocityMin_));

        //Create velocity vector with upward bias and horizontal spread
        local horizontalVelocity = sin(verticalAngle) * velocity;
        local velX = cos(horizontalAngle) * horizontalVelocity;
        local velY = cos(verticalAngle) * velocity;
        local velZ = sin(horizontalAngle) * horizontalVelocity;

        //Random rotation for visual variety
        local randomRotationX = _random.rand() * PI * 2.0;
        local randomRotationY = _random.rand() * PI * 2.0;
        local randomRotationZ = _random.rand() * PI * 2.0;

        mWaterEmitter_.emit(0, 0, 0, velX, velY, velZ, mWaterMaxLifetime_, 0.8, 0.0, randomRotationX, randomRotationY, randomRotationZ);
    }

    function spawnBaseParticle_(){
        //Spawn from radius around base
        local spawnAngle = _random.rand() * PI * 2.0;
        local spawnX = cos(spawnAngle) * mBaseSpawnRadius_;
        local spawnZ = sin(spawnAngle) * mBaseSpawnRadius_;
        local spawnY = _random.rand() * 0.5;

        //Calculate velocity towards centre and slightly upward
        local dirX = -spawnX * mBaseVelocity_;
        local dirY = 0.1;
        local dirZ = -spawnZ * mBaseVelocity_;

        //Random rotation for visual variety
        local randomRotationX = _random.rand() * PI * 2.0;
        local randomRotationY = _random.rand() * PI * 2.0;
        local randomRotationZ = _random.rand() * PI * 2.0;

        mBaseEmitter_.emit(spawnX, spawnY, spawnZ, dirX, dirY, dirZ, mBaseMaxLifetime_, 0.6, 0.0, randomRotationX, randomRotationY, randomRotationZ);
    }

    function destroyed(eid, reason){
        //Clean up native emitters
        mWaterEmitter_.destroy();
        mBaseEmitter_.destroy();
        mPlumeEmitter_.destroy();
    }
};

//State machine class
::GeyserStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(GeyserState.MAX);

    function getData(){
        return mData_;
    }
};

//DORMANT state - no effects, just waiting
::GeyserStateMachine.mStates_[GeyserState.DORMANT] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        data.mData_.setEmissionEnabled_(false);
        data.mData_.setWarmingUpEmissionEnabled_(false);
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mDormantDuration_){
            return GeyserState.WARMING_UP;
        }
    }
};

//WARMING_UP state - preparing for eruption
::GeyserStateMachine.mStates_[GeyserState.WARMING_UP] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        data.mData_.setWarmingUpEmissionEnabled_(true);
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mWarmingUpDuration_){
            return GeyserState.WARMED_UP;
        }
    }

    function end(data){
        //Keep warming particles on during WARMED_UP
    }
};

//WARMED_UP state - about to fire, complicated effect
::GeyserStateMachine.mStates_[GeyserState.WARMED_UP] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        //Warming up particles already enabled from previous state
    }
    function update(data){
        mStateTime_++;

        if(mStateTime_ >= 15){ //Assume WARMED_UP lasts briefly before FIRING
            return GeyserState.FIRING;
        }
    }

    function end(data){
        //Turn off warming particles when firing
        data.mData_.setWarmingUpEmissionEnabled_(false);
    }
};

//FIRING state - main geyser eruption with full effects
::GeyserStateMachine.mStates_[GeyserState.FIRING] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        data.mData_.setEmissionEnabled_(true);
        data.mData_.addCameraEffectCollisionPoint_();
        data.mData_.addDamageCollisionPoint_();
    }
    function update(data){
        mStateTime_++;

        //Spawn plume pieces
        if(data.mData_.mFrameCounter_ % 1 == 0){
            data.mData_.spawnGeyserPiece_();
        }

        if(mStateTime_ >= data.mData_.mFiringDuration_){
            return GeyserState.COOLING_DOWN;
        }
    }
    function end(data){
        //Stop particle emission when firing ends
        data.mData_.setEmissionEnabled_(false);
        data.mData_.removeCameraEffectCollisionPoint_();
        data.mData_.removeDamageCollisionPoint_();
    }
};

//COOLING_DOWN state - winding down the eruption
::GeyserStateMachine.mStates_[GeyserState.COOLING_DOWN] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mCoolingDownDuration_){
            return GeyserState.DORMANT;
        }
    }
};
