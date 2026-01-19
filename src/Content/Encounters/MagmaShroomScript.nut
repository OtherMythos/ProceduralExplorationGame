//State enumeration
enum MagmaShroomState{
    NONE,

    IDLE,
    BUILDING,
    EMITTING,
    COOLING_DOWN,

    MAX
};

::MagmaShroomScript <- class{
    mParentNode_ = null;
    mBuildingParticles_ = null;
    mEmittingParticles_ = null;
    mFrameCounter_ = 0;
    mWorld_ = null;
    mPosition_ = null;
    mDamageCollisionPoint_ = null;

    //State machine
    mStateMachine_ = null;
    mCurrentState_ = null;

    //State timing configuration (in frames)
    mIdleDuration_ = 400;
    mBuildingDuration_ = 200;
    mEmittingDuration_ = 250;
    mCoolingDownDuration_ = 30;

    constructor(eid, parentNode, buildingParticles, emittingParticles, world, position){
        mParentNode_ = parentNode;
        mBuildingParticles_ = buildingParticles;
        mEmittingParticles_ = emittingParticles;
        mWorld_ = world;
        mPosition_ = position;
        mDamageCollisionPoint_ = null;

        //Initialise with particles off
        if(mBuildingParticles_ != null) mBuildingParticles_.setEmitting(false);
        if(mEmittingParticles_ != null) mEmittingParticles_.setEmitting(false);

        //Initialise state machine
        mStateMachine_ = ::MagmaShroomStateMachine(this);
        mStateMachine_.setState(MagmaShroomState.IDLE);
        this.mStateMachine_.mStateInstance_.mStateTime_ = _random.randInt(mIdleDuration_);
    }

    function update(eid){
        mFrameCounter_++;

        //Update state machine
        if(mStateMachine_ != null){
            mStateMachine_.update();
        }
    }

    function setEmissionEnabled_(enabled){
        if(mBuildingParticles_ != null) mBuildingParticles_.setEmitting(enabled);
        if(mEmittingParticles_ != null) mEmittingParticles_.setEmitting(enabled);
    }

    function addDamageCollisionPoint_(){
        if(mDamageCollisionPoint_ != null) return;

        local damageWorld = mWorld_.getDamageWorld();
        local fireArea = ::Combat.CombatMove(10);
        fireArea.mStatusAffliction = StatusAfflictionType.ON_FIRE;
        fireArea.mStatusAfflictionLifetime = 100;
        mDamageCollisionPoint_ = damageWorld.addCollisionSender(CollisionWorldTriggerResponses.PROJECTILE_DAMAGE, fireArea, mPosition_.x, mPosition_.z, 3, _COLLISION_PLAYER);
    }

    function removeDamageCollisionPoint_(){
        if(mDamageCollisionPoint_ == null) return;

        local damageWorld = mWorld_.getDamageWorld();
        damageWorld.removeCollisionPoint(mDamageCollisionPoint_);
        mDamageCollisionPoint_ = null;
    }

    function shutdown(){
        //Clean up collision points
        removeDamageCollisionPoint_();

        //Clean up particle systems
        if(mBuildingParticles_ != null){
            mBuildingParticles_.setEmitting(false);
        }
        if(mEmittingParticles_ != null){
            mEmittingParticles_.setEmitting(false);
        }
    }

    function destroyed(eid, reason){
        //Clean up collision points and particles when entity is destroyed
        shutdown();
    }
};

//State machine class
::MagmaShroomStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(MagmaShroomState.MAX);

    function getData(){
        return mData_;
    }
};

//IDLE state - no effects, just waiting
::MagmaShroomStateMachine.mStates_[MagmaShroomState.IDLE] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        if(data.mData_.mBuildingParticles_ != null) data.mData_.mBuildingParticles_.setEmitting(false);
        if(data.mData_.mEmittingParticles_ != null) data.mData_.mEmittingParticles_.setEmitting(false);
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mIdleDuration_){
            return MagmaShroomState.BUILDING;
        }
    }
};

//BUILDING state - flamey building effect
::MagmaShroomStateMachine.mStates_[MagmaShroomState.BUILDING] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        if(data.mData_.mBuildingParticles_ != null) data.mData_.mBuildingParticles_.setEmitting(true);
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mBuildingDuration_){
            return MagmaShroomState.EMITTING;
        }
    }

    function end(data){
        //Keep building particles on during transition to emitting
    }
};

//EMITTING state - dramatic magma/flame effects
::MagmaShroomStateMachine.mStates_[MagmaShroomState.EMITTING] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
        if(data.mData_.mEmittingParticles_ != null) data.mData_.mEmittingParticles_.setEmitting(true);
        if(data.mData_.mBuildingParticles_ != null) data.mData_.mBuildingParticles_.setEmitting(false);
        data.mData_.addDamageCollisionPoint_();
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mEmittingDuration_){
            return MagmaShroomState.COOLING_DOWN;
        }
    }

    function end(data){
        //Stop particle emission when emitting ends
        if(data.mData_.mEmittingParticles_ != null) data.mData_.mEmittingParticles_.setEmitting(false);
        data.mData_.removeDamageCollisionPoint_();
    }
};

//COOLING_DOWN state - winding down the eruption
::MagmaShroomStateMachine.mStates_[MagmaShroomState.COOLING_DOWN] = class extends ::Util.SimpleState{
    mStateTime_ = 0;

    function start(data){
        mStateTime_ = 0;
    }

    function update(data){
        mStateTime_++;

        if(mStateTime_ >= data.mData_.mCoolingDownDuration_){
            return MagmaShroomState.IDLE;
        }
    }
};
