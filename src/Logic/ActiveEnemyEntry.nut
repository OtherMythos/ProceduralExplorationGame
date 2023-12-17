enum ActiveEnemyAnimationEvents{
    NONE,

    STARTED_MOVING,
    STOPPED_MOVING,
    WATER_STATE_CHANGE,

    EQUIPPABLE_PERFORMANCE_STATE_CHANGE,

    MAX
};
enum ActiveEnemyAnimationStage{
    NONE,

    IDLE,
    WALKING,
    SWIMMING,

    MAX
};
::ActiveEnemyAnimationStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(ActiveEnemyAnimationStage.MAX);
    mModel_ = null;
    mInWater_ = false;

    mEquippablePerformance_ = null;
    mCurrentEquippableAnim_ = CharacterModelAnimId.NONE;
    constructor(model){
        mModel_ = model;
    }
    function notifyWaterState(inWater){
        mInWater_ = inWater;
        notify(ActiveEnemyAnimationEvents.WATER_STATE_CHANGE);
    }
    function notifyEquippablePerformance(performance){
        mEquippablePerformance_ = performance;
        notify(ActiveEnemyAnimationEvents.EQUIPPABLE_PERFORMANCE_STATE_CHANGE);
    }

    function processPerformance_(alternativeAnim=null){
        if(mEquippablePerformance_ != null){
            local anim = mEquippablePerformance_.getEquippableAttackAnim();
            mCurrentEquippableAnim_ = anim;
            mModel_.startAnimation(anim);
            if(alternativeAnim != null){
                mModel_.stopAnimationBaseType(alternativeAnim);
            }
        }else{
            if(mCurrentEquippableAnim_ != CharacterModelAnimId.NONE){
                mModel_.stopAnimation(mCurrentEquippableAnim_);
                if(alternativeAnim != null){
                    mModel_.startAnimationBaseType(alternativeAnim);
                }
            }
        }
    }
}
ActiveEnemyAnimationStateMachine.mStates_[ActiveEnemyAnimationStage.IDLE] = class extends ::Util.SimpleState{
    function start(ctx){
    }
    function update(ctx){
    }
    function notify(ctx, event){
        if(event == ActiveEnemyAnimationEvents.STARTED_MOVING){
            return ctx.mInWater_ ? ActiveEnemyAnimationStage.SWIMMING : ActiveEnemyAnimationStage.WALKING;
        }
        else if(event == ActiveEnemyAnimationEvents.EQUIPPABLE_PERFORMANCE_STATE_CHANGE){
            ctx.processPerformance_(null);
        }
    }
    function end(ctx){
    }
};
ActiveEnemyAnimationStateMachine.mStates_[ActiveEnemyAnimationStage.WALKING] = class extends ::Util.SimpleState{
    function start(ctx){
        ctx.mModel_.startAnimationBaseType(CharacterModelAnimBaseType.UPPER_WALK);
        ctx.mModel_.startAnimationBaseType(CharacterModelAnimBaseType.LOWER_WALK);
    }
    function update(ctx){
    }
    function notify(ctx, event){
        if(event == ActiveEnemyAnimationEvents.STOPPED_MOVING) return ActiveEnemyAnimationStage.IDLE;

        if(event == ActiveEnemyAnimationEvents.WATER_STATE_CHANGE){
            //Assume if we're in the walking state we must be changing to in the water.
            if(ctx.mInWater_) return ActiveEnemyAnimationStage.SWIMMING;
        }
        else if(event == ActiveEnemyAnimationEvents.EQUIPPABLE_PERFORMANCE_STATE_CHANGE){
            ctx.processPerformance_(CharacterModelAnimBaseType.UPPER_WALK);
        }
    }
    function end(ctx){
        ctx.mModel_.stopAnimationBaseType(CharacterModelAnimBaseType.UPPER_WALK);
        ctx.mModel_.stopAnimationBaseType(CharacterModelAnimBaseType.LOWER_WALK);
    }
};
ActiveEnemyAnimationStateMachine.mStates_[ActiveEnemyAnimationStage.SWIMMING] = class extends ::Util.SimpleState{
    function start(ctx){
        //ctx.mModel_.startAnimationBaseType(CharacterModelAnimId.BASE_LEGS_WALK);
        ctx.mModel_.startAnimationBaseType(CharacterModelAnimBaseType.UPPER_SWIM);
    }
    function update(ctx){
    }
    function notify(ctx, event){
        if(event == ActiveEnemyAnimationEvents.STOPPED_MOVING) return ActiveEnemyAnimationStage.IDLE;

        if(event == ActiveEnemyAnimationEvents.WATER_STATE_CHANGE){
            if(!ctx.mInWater_) return ActiveEnemyAnimationStage.WALKING;
        }
        else if(event == ActiveEnemyAnimationEvents.EQUIPPABLE_PERFORMANCE_STATE_CHANGE){
            ctx.processPerformance_(CharacterModelAnimBaseType.UPPER_SWIM);
        }
    }
    function end(ctx){
        //ctx.mModel_.stopAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
        ctx.mModel_.stopAnimationBaseType(CharacterModelAnimBaseType.UPPER_SWIM);
    }
};

::ActiveEnemyEntry <- class{
    mCreatorWorld_ = null;
    mEnemy_ = EnemyId.NONE;
    mPos_ = null;
    mId_ = null;
    mEncountered_ = false;
    mModel_ = null;
    mStateMachineModel_ = null;
    mMoving_ = 0;
    mGizmo_ = null;
    mCombatData_ = null;
    mTargetCollisionWorld_ = 0;
    mCollisionPoint_ = null;

    mVoxX_ = -1;
    mVoxY_ = -1;

    mEntity_ = null;

    mPerformingEquippable_ = null;

    mAttackers_ = null;
    mInWater_ = false;

    constructor(creatorWorld, enemyType, enemyPos, entity){
        mCreatorWorld_ = creatorWorld;
        mEnemy_ = enemyType;
        mPos_ = enemyPos;
        mEntity_ = entity;
    }
    function getEID(){
        //if(typeof mEntity_ == "integer") return mEntity_;
        //return mEntity_.getId();
        return mEntity_;
    }
    function checkVoxelChange(){
        local changed = false;
        local voxX = (mPos_.x).tointeger();
        local voxY = (mPos_.y).tointeger();
        changed = mVoxX_ != voxX || mVoxY_ != voxY;
        mVoxX_ = voxX;
        mVoxY_ = voxY;
        return changed;
    }
    function setPosition(pos){
        mPos_ = pos;

        local inWater = mCreatorWorld_.getIsWaterForPosition(mPos_);
        if(inWater != mInWater_ && mStateMachineModel_){
            mStateMachineModel_.notifyWaterState(inWater);
        }
        mInWater_ = inWater;

        mCreatorWorld_.mTargetManager_.notifyEntityPositionChange(this);
        if(mEntity_ != null){
            //if(typeof mEntity_ == "integer"){
                mCreatorWorld_.getEntityManager().setEntityPosition(mEntity_, pos);
            //}else{
            //    mEntity_.setPosition(SlotPosition(pos));
            //}
        }
        if(mGizmo_) mGizmo_.setPosition(pos);
        if(mCollisionPoint_ != null) mCreatorWorld_.getTriggerWorld().mCollisionWorld_.setPositionForPoint(mCollisionPoint_, pos.x, pos.z);
    }
    function getSceneNode(){
        //if(typeof mEntity_ == "integer"){
            return mCreatorWorld_.getEntityManager().getComponent(mEntity_, EntityComponents.SCENE_NODE).mNode;
        //}
        //_component.sceneNode.getNode(mEntity_);
    }
    function getPosition(){
        return mPos_;
    }
    function getEntity(){
        return mEntity_;
    }
    function setModel(model){
        mModel_ = model;
        mStateMachineModel_ = ActiveEnemyAnimationStateMachine(mModel_);
        mStateMachineModel_.setState(ActiveEnemyAnimationStage.IDLE);
    }
    function getModel(){
        return mModel_;
    }
    function setCombatData(combatData){
        mCombatData_ = combatData;
    }
    function setCollisionPoint(point){
        mCollisionPoint_ = point;
    }
    function setTargetCollisionWorld(world){
        mTargetCollisionWorld_ = world;
    }
    function getTargetCollisionWorld(){
        return mTargetCollisionWorld_;
    }
    function isPositionWalkable(intended){
        local traverseTypes = ::Enemies[mEnemy_].getTraversableTerrain();
        local traverse = mCreatorWorld_.getTraverseTerrainForPosition(mPos_);

        return traverseTypes & traverse;
    }
    function move(amount){
        //First check if that section of the map is walkable.
        local intended = mPos_ + amount;
        if(!isPositionWalkable(intended)){
            return false;
        }

        setPosition(intended);
        if(mModel_){
            local orientation = Quat(atan2(amount.x, amount.z), Vec3(0, 1, 0));
            mModel_.setOrientation(orientation);
        }else{
            if(mEntity_ != null){
                local orientation = Quat(atan2(amount.x, amount.z), Vec3(0, 1, 0));
                getSceneNode().setOrientation(orientation);
            }
        }

        if(mMoving_ <= 0 && mStateMachineModel_){
            mStateMachineModel_.notify(ActiveEnemyAnimationEvents.STARTED_MOVING);
        }
        mPerformingEquippable_ = null;
        mMoving_ = 10;

        return true;
    }
    function moveQueryZ(amount, inWater=false){
        local zQuery = mCreatorWorld_.getZForPos(mPos_ + amount);
        mPos_.y = zQuery;
        if(inWater){
            if(::Enemies[mEnemy_].getAllowSwimState()) mPos_.y = -1.4;
        }
        move(amount);
    }
    function moveToPoint(point, amount){
        local dir = point - mPos_;
        dir.normalise();

        dir *= (amount * getSlowFactor(mInWater_));
        moveQueryZ(dir, mInWater_);
    }
    function getSlowFactor(inWater){
        local slow = 1.0;
        if(inWater){
            slow = ::Enemies[mEnemy_].getAllowSwimState() ? 0.5 : 1.0;
        }
        return slow;
    }
    function setId(id){
        mId_ = id;
    }
    function getId(){
        return mId_;
    }
    function notifyDestroyed(){
        if(mGizmo_){
            mGizmo_.destroy();
            mGizmo_ = null;
        }
        if(mModel_){
            mModel_.destroy();
            mModel_ = null;
        }
        if(mCollisionPoint_ != null){
            mCreatorWorld_.getTriggerWorld().removeCollisionPoint(mCollisionPoint_);
        }
        mCreatorWorld_.mTargetManager_.notifyEntityDestroyed(this);
    }
    function notifyNewHealth(newHealth, newPercentage){
        local entityManager = mCreatorWorld_.getEntityManager();
        local billboardIdx = -1;
        if(entityManager.hasComponent(mEntity_, EntityComponents.BILLBOARD)){
            local comp = entityManager.getComponent(mEntity_, EntityComponents.BILLBOARD);
            billboardIdx = comp.mBillboard;
        }

        if(billboardIdx >= 0){
            if(newHealth <= 0){
                mCreatorWorld_.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(billboardIdx);
            }else{
                mCreatorWorld_.mGui_.mWorldMapDisplay_.mBillboardManager_.updateHealth(billboardIdx, newPercentage);
            }
        }
    }
    function setGizmo(gizmo){
        if(mGizmo_ != null){
            mGizmo_.destroy();
        }
        mGizmo_ = gizmo;
    }
    function getGizmo(){
        return mGizmo_;
    }

    function update(){
        if(mMoving_ > 0){
            mMoving_--;
            if(mMoving_ <= 0){
                if(mStateMachineModel_){
                    mStateMachineModel_.notify(ActiveEnemyAnimationEvents.STOPPED_MOVING);
                    //mModel_.stopAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
                    ////mModel_.stopAnimation(CharacterModelAnimId.BASE_ARMS_WALK);
                    //mModel_.stopAnimation(mInWater_ ? CharacterModelAnimId.BASE_ARMS_SWIM : CharacterModelAnimId.BASE_ARMS_WALK);
                }
            }
        }
        if(isMidAttack()){
            performAttack();
        }
        if(mPerformingEquippable_){
            local result = mPerformingEquippable_.update(mPos_);
            if(!result){
                mStateMachineModel_.notifyEquippablePerformance(null);
                mPerformingEquippable_ = null;
            }
        }

        if(mStateMachineModel_ != null){
            mStateMachineModel_.update();
        }
    }
    function performAttack(){
        if(mPerformingEquippable_) return;
        if(mCombatData_ == null) return;
        //TODO determine which weapon takes presidence
        local equippedSword = mCombatData_.mEquippedItems.mItems[EquippedSlotTypes.LEFT_HAND];
        //TODO in future have some base attack.
        if(equippedSword == null){
            print("IS NULL");
            return;
        }

        local equippable = ::Equippables[equippedSword.getEquippableData()];
        local performance = ::EquippablePerformance(equippable, this);
        mStateMachineModel_.notifyEquippablePerformance(performance);
        mPerformingEquippable_ = performance;
    }

    function isMidAttack(){
        return mAttackers_ != null;
    }
    function isMidAttackWithAttacker(attackerId){
        if(mAttackers_ == null) return false;
        return mAttackers_.rawin(attackerId);
    }

    function notifyAttackBegan(attacker){
        local attackerId = attacker.getEntity();
        print("===attack began " + attackerId);
        //Register the new attacker.
        if(mAttackers_ == null){
            //Defer the creation until later to avoid having lots of lists for entities which don't need them.
            mAttackers_ = {};
        }
        mAttackers_[attackerId] <- attacker;
    }
    function notifyAttackEnded(attacker){
        local attackerId = attacker.getEntity();
        print("===attack ended " + attackerId);
        assert(mAttackers_ != null);
        assert(mAttackers_.rawin(attackerId));
        mAttackers_.rawdelete(attackerId);
        if(mAttackers_.len() == 0) mAttackers_ = null;
    }
}