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
    mMeshNodes_ = null;
    mWaterParticles_ = null;
    mBaseParticles_ = null;
    mFountainParticles_ = null;
    mInnerFountainParticles_ = null;
    mWarmingUpFountainParticles_ = null;
    mFrameCounter_ = 0;
    mWorld_ = null;
    mPosition_ = null;
    mCameraEffectCollisionPoint_ = null;
    mDamageCollisionPoint_ = null;

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
        mMeshNodes_ = [];
        mWaterParticles_ = [];
        mBaseParticles_ = [];
        mFountainParticles_ = fountainParticles;
        mInnerFountainParticles_ = innerFountainParticles;
        mWarmingUpFountainParticles_ = warmingUpFountainParticles;
        mWorld_ = world;
        mPosition_ = position;
        mCameraEffectCollisionPoint_ = null;
        mDamageCollisionPoint_ = null;

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

        //Update existing mesh nodes and remove old ones
        local nodesToRemove = [];
        foreach(idx, nodeData in mMeshNodes_){
            nodeData.age++;
            if(nodeData.age>=5){
                nodesToRemove.push(idx);
            }
        }

        //Remove old nodes in reverse order to maintain indices
        for(local i=nodesToRemove.len()-1; i>=0; i--){
            local idx = nodesToRemove[i];
            mMeshNodes_[idx].node.destroyNodeAndChildren();
            mMeshNodes_.remove(idx);
        }

        //Update water particles with gravity simulation
        updateWaterParticles_();

        //Update base particles
        updateBaseParticles_();
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
        //Select a random mesh piece from 1-3
        local pieceNum = 1 + _random.randInt(2);
        local meshName = "gyserPieces.plume" + pieceNum + ".voxMesh";

        //Create a new scene node for this piece
        local newNode = mParentNode_.createChildSceneNode();

        //Add slight randomisation to the position and rotation
        local xOffset = (_random.rand() - 0.5) * 0.5;
        local zOffset = (_random.rand() - 0.5) * 0.5;
        newNode.setPosition(xOffset, 0, zOffset);

        //Randomise rotation around Y axis
        local rotationAngle = _random.rand() * PI * 2.0;
        local quat = Quat(rotationAngle, ::Vec3_UNIT_Y);
        newNode.setOrientation(quat);

        //Create and attach the mesh
        local item = _gameCore.createVoxMeshItem(meshName);
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        newNode.attachObject(item);

        //Track this node with its age
        mMeshNodes_.push({node = newNode, age = 0});
    }

    function spawnWaterParticle_(){
        //Select a random water mesh piece from 1-3
        local waterNum = 1 + _random.randInt(2);
        local waterMeshName = "gyserPieces.water" + waterNum + ".voxMesh";

        //Create a new scene node for this water particle
        local waterNode = mParentNode_.createChildSceneNode();
        waterNode.setPosition(0, 0, 0);
        waterNode.setScale(0.8, 0.8, 0.8);

        //Create and attach the mesh
        local item = _gameCore.createVoxMeshItem(waterMeshName);
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        waterNode.attachObject(item);

        //Calculate initial velocity with angle spread
        local angleSpreadRad = (mWaterAngleSpread_ / 2.0) * (PI / 180.0);
        local verticalAngle = (_random.rand() - 0.5) * 2.0 * angleSpreadRad; //Angle from vertical (-angleSpreadRad to +angleSpreadRad)
        local horizontalAngle = _random.rand() * PI * 2.0; //Full 360 degrees around

        //Random velocity between min and max
        local velocity = mWaterVelocityMin_ + (_random.rand() * (mWaterVelocityMax_ - mWaterVelocityMin_));

        //Create velocity vector with upward bias and horizontal spread
        //The vertical component is based on verticalAngle deviation from straight up
        local horizontalVelocity = sin(verticalAngle) * velocity;
        local velX = cos(horizontalAngle) * horizontalVelocity;
        local velY = cos(verticalAngle) * velocity;
        local velZ = sin(horizontalAngle) * horizontalVelocity;

        //Random rotation for visual variety
        local randomRotationX = _random.rand() * PI * 2.0;
        local randomRotationY = _random.rand() * PI * 2.0;
        local randomRotationZ = _random.rand() * PI * 2.0;
        local quat = Quat(randomRotationX, ::Vec3_UNIT_X) * Quat(randomRotationY, ::Vec3_UNIT_Y) * Quat(randomRotationZ, ::Vec3_UNIT_Z);
        waterNode.setOrientation(quat);

        //Track water particle with physics data
        mWaterParticles_.push({
            node = waterNode,
            velX = velX,
            velY = velY,
            velZ = velZ,
            age = 0
        });
    }

    function spawnBaseParticle_(){
        //Select a random water mesh piece from 1-3
        local waterNum = 1 + _random.randInt(2);
        local waterMeshName = "gyserPieces.water" + waterNum + ".voxMesh";

        //Create a new scene node for this base particle
        local baseNode = mParentNode_.createChildSceneNode();
        baseNode.setScale(0.6, 0.6, 0.6);

        //Create and attach the mesh
        local item = _gameCore.createVoxMeshItem(waterMeshName);
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        baseNode.attachObject(item);

        //Spawn from radius around base
        local spawnAngle = _random.rand() * PI * 2.0;
        local spawnX = cos(spawnAngle) * mBaseSpawnRadius_;
        local spawnZ = sin(spawnAngle) * mBaseSpawnRadius_;
        local spawnY = _random.rand() * 0.5; //Slight variation in starting height
        baseNode.setPosition(spawnX, spawnY, spawnZ);

        //Calculate velocity towards centre and slightly upward
        local dirX = -spawnX * mBaseVelocity_;
        local dirY = 0.1; //Slight upward movement
        local dirZ = -spawnZ * mBaseVelocity_;

        //Random rotation for visual variety
        local randomRotationX = _random.rand() * PI * 2.0;
        local randomRotationY = _random.rand() * PI * 2.0;
        local randomRotationZ = _random.rand() * PI * 2.0;
        local quat = Quat(randomRotationX, ::Vec3_UNIT_X) * Quat(randomRotationY, ::Vec3_UNIT_Y) * Quat(randomRotationZ, ::Vec3_UNIT_Z);
        baseNode.setOrientation(quat);

        //Track base particle with physics data
        mBaseParticles_.push({
            node = baseNode,
            velX = dirX,
            velY = dirY,
            velZ = dirZ,
            age = 0
        });
    }

    function updateWaterParticles_(){
        //Emit new water particles based on emission rate if flag is set
        if(mIsEmittingWater_ && mFrameCounter_ % 1 == 0){
            for(local i = 0; i < mWaterEmissionRate_; i++){
                spawnWaterParticle_();
            }
        }

        //Update positions and remove old particles
        local particlesToRemove = [];
        foreach(idx, particle in mWaterParticles_){
            particle.age++;

            //Apply gravity to vertical velocity
            particle.velY -= mWaterGravity_;

            //Update position
            local currentPos = particle.node.getPositionVec3();
            currentPos.x += particle.velX;
            currentPos.y += particle.velY;
            currentPos.z += particle.velZ;
            particle.node.setPosition(currentPos);

            //Animate scale - shrink over lifetime
            local lifetimeRatio = 1.0 - (particle.age.tofloat() / mWaterMaxLifetime_.tofloat());
            particle.node.setScale(lifetimeRatio, lifetimeRatio, lifetimeRatio);

            //Remove if too old or fell below ground
            if(particle.age >= mWaterMaxLifetime_ || currentPos.y < -10){
                particlesToRemove.push(idx);
            }
        }

        //Remove old particles in reverse order to maintain indices
        for(local i = particlesToRemove.len() - 1; i >= 0; i--){
            local idx = particlesToRemove[i];
            mWaterParticles_[idx].node.destroyNodeAndChildren();
            mWaterParticles_.remove(idx);
        }
    }

    function updateBaseParticles_(){
        //Emit new base particles based on emission rate if flag is set
        if(mIsEmittingBase_ && mFrameCounter_ % 1 == 0){
            for(local i = 0; i < mBaseEmissionRate_; i++){
                spawnBaseParticle_();
            }
        }

        //Update positions and remove old particles
        local particlesToRemove = [];
        foreach(idx, particle in mBaseParticles_){
            particle.age++;

            //Apply gravity to vertical velocity
            particle.velY -= mBaseGravity_;

            //Update position
            local currentPos = particle.node.getPositionVec3();
            currentPos.x += particle.velX;
            currentPos.y += particle.velY;
            currentPos.z += particle.velZ;
            particle.node.setPosition(currentPos);

            //Animate scale - shrink over lifetime
            local lifetimeRatio = 1.0 - (particle.age.tofloat() / mBaseMaxLifetime_.tofloat());
            particle.node.setScale(0.6 * lifetimeRatio, 0.6 * lifetimeRatio, 0.6 * lifetimeRatio);

            //Remove if too old or fell below ground
            if(particle.age >= mBaseMaxLifetime_ || currentPos.y < -10){
                particlesToRemove.push(idx);
            }
        }

        //Remove old particles in reverse order to maintain indices
        for(local i = particlesToRemove.len() - 1; i >= 0; i--){
            local idx = particlesToRemove[i];
            mBaseParticles_[idx].node.destroyNodeAndChildren();
            mBaseParticles_.remove(idx);
        }
    }

    function destroyed(eid, reason){
        //Clean up all mesh nodes when the entity is destroyed
        foreach(nodeData in mMeshNodes_){
            nodeData.node.destroyNodeAndChildren();
        }
        mMeshNodes_.clear();

        //Clean up all water particles
        foreach(particle in mWaterParticles_){
            particle.node.destroyNodeAndChildren();
        }
        mWaterParticles_.clear();

        //Clean up all base particles
        foreach(particle in mBaseParticles_){
            particle.node.destroyNodeAndChildren();
        }
        mBaseParticles_.clear();
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
