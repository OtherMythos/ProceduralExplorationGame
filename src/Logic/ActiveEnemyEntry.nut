enum ActiveEnemyAnimationEvents{
    NONE,

    STARTED_MOVING,
    STOPPED_MOVING,
    WATER_STATE_CHANGE,
    REQUEST_DASH,

    EQUIPPABLE_PERFORMANCE_STATE_CHANGE,

    MAX
};
enum ActiveEnemyAnimationStage{
    NONE,

    IDLE,
    WALKING,
    SWIMMING,
    DASHING,

    MAX
};
::ActiveEnemyAnimationStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(ActiveEnemyAnimationStage.MAX);
    mModel_ = null;
    mInWater_ = false;
    mDashReturnState_ = null;
    mCount_ = 0;

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
            if(mCurrentEquippableAnim_ == CharacterModelAnimId.NONE){
                local anim = mEquippablePerformance_.getEquippableAttackAnim();
                mCurrentEquippableAnim_ = anim;
                mModel_.startAnimation(anim);
            }
            if(alternativeAnim != null){
                mModel_.stopAnimationBaseType(alternativeAnim);
            }
        }else{
            if(mCurrentEquippableAnim_ != CharacterModelAnimId.NONE){
                mModel_.stopAnimation(mCurrentEquippableAnim_);
                mCurrentEquippableAnim_ = CharacterModelAnimId.NONE;
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
        else if(event == ActiveEnemyAnimationEvents.REQUEST_DASH){
            return ActiveEnemyAnimationStage.DASHING;
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
        else if(event == ActiveEnemyAnimationEvents.REQUEST_DASH){
            return ActiveEnemyAnimationStage.DASHING;
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
        else if(event == ActiveEnemyAnimationEvents.REQUEST_DASH){
            return ActiveEnemyAnimationStage.DASHING;
        }
    }
    function end(ctx){
        //ctx.mModel_.stopAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
        ctx.mModel_.stopAnimationBaseType(CharacterModelAnimBaseType.UPPER_SWIM);
    }
};
//TODO note, this state machine is supposed to manage animations, but here is responsible for logic. This will need changing or the naming updated.
ActiveEnemyAnimationStateMachine.mStates_[ActiveEnemyAnimationStage.DASHING] = class extends ::Util.SimpleState{
    function start(ctx){
        ctx.mCount_ = 15;
        ctx.mDashReturnState_ = ctx.getPreviousState();
        if(ctx.mDashReturnState_ == null) ctx.mDashReturnState_ = ActiveEnemyAnimationStage.WALKING;
    }
    function update(ctx){
        ctx.mCount_--;
        print("dashing count" + ctx.mCount_);
        if(ctx.mCount_ <= 0){
            return ctx.mDashReturnState_;
        }
    }
    function notify(ctx, event){
        if(event == ActiveEnemyAnimationEvents.WATER_STATE_CHANGE){
            ctx.mDashReturnState_ = ctx.mInWater_ ? ActiveEnemyAnimationStage.SWIMMING : ActiveEnemyAnimationStage.WALKING;
        }
    }
    function end(ctx){
        ctx.mCount_ = 0;
        ctx.mDashReturnState_ = null;
    }
};

::ActiveEnemyEntry <- class{
    mCreatorWorld_ = null;
    mEnemy_ = EnemyId.NONE;
    mPos_ = null;
    mOrientation_ = null;
    mId_ = null;
    mEncountered_ = false;
    mModel_ = null;
    mStateMachineModel_ = null;
    mMoving_ = 0;
    //mGizmo_ = null;
    mCombatData_ = null;
    mTargetCollisionWorld_ = 0;
    mCollisionPoint_ = null;
    mModelsFirstFrame_ = true;

    mDashDirection_ = null;

    mVoxX_ = -1;
    mVoxY_ = -1;

    mEntity_ = null;

    mPerformingEquippable_ = null;

    mAttackers_ = null;
    mInWater_ = false;
    mAttackActive_ = false;

    constructor(creatorWorld, enemyType, enemyPos, entity){
        mCreatorWorld_ = creatorWorld;
        mEnemy_ = enemyType;
        mPos_ = enemyPos;
        mEntity_ = entity;
        mOrientation_ = ::Quat_IDENTITY.copy();
    }
    function getEID(){
        //if(typeof mEntity_ == "integer") return mEntity_;
        //return mEntity_.getId();
        return mEntity_;
    }
    function performDash(direction){
        print("Attempting dash");
        mStateMachineModel_.notify(ActiveEnemyAnimationEvents.REQUEST_DASH);
        mDashDirection_ = direction;
    }
    function checkVoxelChange(){
        local changed = false;
        local voxX = (mPos_.x).tointeger();
        local voxY = (mPos_.z).tointeger();
        changed = ((mVoxX_ != voxX) || (mVoxY_ != voxY));
        mVoxX_ = voxX;
        mVoxY_ = voxY;
        return changed;
    }
    function setPosition(pos){
        mPos_ = pos;

        local inWater = mCreatorWorld_.getIsWaterForPosition(mPos_);
        if(inWater != mInWater_ && mStateMachineModel_){
            mStateMachineModel_.notifyWaterState(inWater);
            //Trigger water splash effect when entering water
            if(inWater){
                mCreatorWorld_.spawnWorldEffect(WorldEffectId.WATER_SPLASH, mPos_);
            }
        }
        mInWater_ = inWater;

        mCreatorWorld_.mTargetManager_.notifyEntityPositionChange(this);
        mCreatorWorld_.mProjectileTargetManager_.notifyEntityPositionChange(this);
        if(mEntity_ != null){
            //if(typeof mEntity_ == "integer"){
                mCreatorWorld_.getEntityManager().setEntityPosition(mEntity_, pos);
            //}else{
            //    mEntity_.setPosition(SlotPosition(pos));
            //}
        }
        //if(mGizmo_) mGizmo_.setPosition(pos);
        if(mCollisionPoint_ != null) mCreatorWorld_.getTriggerWorld().mCollisionWorld_.setPositionForPoint(mCollisionPoint_, pos.x, pos.z);
    }
    function getSceneNode(){
        //if(typeof mEntity_ == "integer"){
            return mCreatorWorld_.getEntityManager().getComponent(mEntity_, EntityComponents.SCENE_NODE).mNode;
        //}
        //_component.sceneNode.getNode(mEntity_);
    }

    function getAABB(){
        if(mModel_ != null){
            return mModel_.determineAABB();
        }
        //Fallback to default AABB if no model
        return AABB();
    }

    function getPosition(){
        return mPos_;
    }
    function getOrientation(){
        return mOrientation_;
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
        if(mModel_){
            mModel_.equipDataToCharacterModel(combatData.mEquippedItems);
        }
    }
    function setWieldActive(active){
        if(!mModelsFirstFrame_ && mCombatData_.mWieldActive == active) return;
        mCombatData_.setWieldActive(active);
        if(mModel_ != null){
            mModel_.equipDataToCharacterModel(mCombatData_.mEquippedItems, active);
        }
        mModelsFirstFrame_ = false;
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
    function setDirection(dir){
        local orientation = Quat(atan2(dir.x, dir.y), ::Vec3_UNIT_Y);
        if(mModel_){
            mModel_.setOrientation(orientation);
        }
        mOrientation_ = orientation;
    }
    function move_(pos, amount){
        //Check for potential obstacles.
        local targetPos = pos;
        if(mEntity_ != null){
            local result = mCreatorWorld_.getEntityManager().checkEntityPositionPotential(mEntity_, pos);
            targetPos = result;
            //If we couldn't move at all (hard stop), return false
            if(result.x == mPos_.x && result.z == mPos_.z){
                return false;
            }
        }

        setPosition(targetPos);
        setDirection(Vec2(amount.x, amount.z));

        if(mMoving_ <= 0 && mStateMachineModel_){
            mStateMachineModel_.notify(ActiveEnemyAnimationEvents.STARTED_MOVING);
        }
        mMoving_ = 10;

        return true;
    }
    function checkPositionCollides(pos){
        if(mEntity_ == null) return false;

        local w = mCreatorWorld_.getCollisionDetectionWorld();
        local result = w.checkCollisionPoint(pos.x, pos.z, 1);
        return result;
    }
    function move(amount){
        local intended = mPos_ + amount;
        return move_(intended, amount);
    }
    function moveQueryZ(amount, inWater=false){
        local intended = mPos_ + amount;
        local zQuery = mCreatorWorld_.getZForPos(intended);
        intended.y = zQuery;
        if(inWater){
            if(::Enemies[mEnemy_].getAllowSwimState()) intended.y -= 1.8;
        }
        move_(intended, amount);
    }
    function moveToPoint(point, amount){
        local dir = point - mPos_;
        dir.normalise();

        moveToDirection(dir, amount);
    }
    function moveToDirection(dir, amount){
        local wieldActive = mCombatData_ == null ? false : mCombatData_.mWieldActive;
        dir *= (amount * getSlowFactor(mInWater_, wieldActive));
        moveQueryZ(dir, mInWater_);
    }
    function getSlowFactor(inWater, wieldActive){
        local slow = 1.0;
        if(inWater){
            slow *= ::Enemies[mEnemy_].getAllowSwimState() ? 0.5 : 1.0;
        }
        if(wieldActive){
            slow *= 0.6;
        }
        //Apply voxel-based speed modifier
        if(::currentNativeMapData != null){
            local voxelSpeedModifier = ::currentNativeMapData.getSpeedModifierForPos(mPos_);
            slow *= voxelSpeedModifier;
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
        //if(mGizmo_){
        //    mGizmo_.destroy();
        //    mGizmo_ = null;
        //}
        if(mModel_){
            mModel_.destroy();
            mModel_ = null;
        }
        if(mCollisionPoint_ != null){
            mCreatorWorld_.getTriggerWorld().removeCollisionPoint(mCollisionPoint_);
        }
        mCreatorWorld_.mTargetManager_.notifyEntityDestroyed(this);
        mCreatorWorld_.mProjectileTargetManager_.notifyEntityDestroyed(this);
    }
    function notifyNewHealth(newHealth, newPercentage, change){
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
                mCreatorWorld_.mGui_.mWorldMapDisplay_.mBillboardManager_.updateHealth(billboardIdx, newHealth);
            }
        }

        if(change < 0){
            //Apply the red flash effect.
            applyDatablockColourAnimation(Vec3(10, 0, 0));
        }
    }
    function applyDatablockColourAnimation(colour){
        local manager = mCreatorWorld_.getEntityManager();
        if(!manager.hasComponent(mEntity_, EntityComponents.DATABLOCK)){
            return;
        }
        local block = manager.getComponent(mEntity_, EntityComponents.DATABLOCK);

        local comp = null;
        if(manager.hasComponent(mEntity_, EntityComponents.DATABLOCK_ANIMATOR)){
            comp = manager.getComponent(mEntity_, EntityComponents.DATABLOCK_ANIMATOR);
        }else{
            comp = ::EntityManager.Components[EntityComponents.DATABLOCK_ANIMATOR]();
            manager.assignComponent(mEntity_, EntityComponents.DATABLOCK_ANIMATOR, comp);
        }

        block.mDiffuseOverride = Vec3(10, 0, 0);
        block.mDiffuseOverrideStrength = 1.0;
        comp.mAnim = 1.0;
        block.refreshDiffuseModifiers();
    }
    function setGizmo(gizmo){
        //if(mGizmo_ != null){
        //    mGizmo_.destroy();
        //}
        //mGizmo_ = gizmo;
    }
    function getGizmo(){
        //return mGizmo_;
    }

    function valid(){
        local manager = mCreatorWorld_.getEntityManager();
        return manager.entityValid(mEntity_);
    }

    function refreshLifetime(){
        local manager = mCreatorWorld_.getEntityManager();
        if(manager.hasComponent(mEntity_, EntityComponents.LIFETIME)){
            manager.getComponent(mEntity_, EntityComponents.LIFETIME).refresh();
        }
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
        if(isDashing()){
            local wieldActive = mCombatData_ == null ? false : mCombatData_.mWieldActive;
            local slowFactor = getSlowFactor(mInWater_, wieldActive);
            local DAMPER = 0.5;
            local speedValue = ((1 - DAMPER) + (slowFactor * DAMPER)) * 0.5;
            if(!wieldActive){
                speedValue *= 0.8;
            }
            moveToPoint(mPos_ + Vec3(mDashDirection_.x, 0, mDashDirection_.y), speedValue);
            mCreatorWorld_.notifyPlayerMoved();
        }
        if(isMidAttack()){
            performAttack();
        }
        if(mPerformingEquippable_){
            local result = mPerformingEquippable_.update(mPos_);
            if(!result){
                if(mStateMachineModel_ != null) mStateMachineModel_.notifyEquippablePerformance(null);
                mPerformingEquippable_ = null;
            }
        }

        if(mStateMachineModel_ != null){
            mStateMachineModel_.update();
        }

        //if(mGizmo_){
        //    mGizmo_.update();
        //}
    }
    function performAttack(){
        if(mPerformingEquippable_ != null) return;
        if(mId_ == -1) print(mPerformingEquippable_);
        if(mCombatData_ == null) return;

        local equippedItems = mCombatData_.mEquippedItems.mItems;
        local equipDef = ::ItemHelper.determineEquippableDefForEquipped(equippedItems, mEnemy_);
        if(equipDef == null){
            return;
        }

        local performance = ::EquippablePerformance(equipDef, this);
        if(mStateMachineModel_ != null){
            mStateMachineModel_.notifyEquippablePerformance(performance);
        }
        mPerformingEquippable_ = performance;
    }

    function checkAttackState(attacking){
        if(attacking && !mAttackActive_){
            beginAttack();
        }
        else if (!attacking && mAttackActive_){
            endAttack();
        }
    }
    function beginAttack(){
        mAttackActive_ = true;
    }
    function endAttack(){
        mAttackActive_ = false;
    }

    function isDashing(){
        if(mStateMachineModel_ == null) return;
        return mStateMachineModel_.mCurrentState_ == ActiveEnemyAnimationStage.DASHING;
    }

    function isMidAttack(){
        if(mCombatData_ != null){
            if(!mCombatData_.mWieldActive){
                return false;
            }
        }
        return mAttackers_ != null || mAttackActive_;
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

    function setRenderQueue(renderQueue){
        //Prefer to use the character model's method if available
        if(mModel_ != null){
            mModel_.setRenderQueue(renderQueue);
        }else if(mEntity_ != null){
            //Fallback for mesh-based entities (like hives)
            local manager = mCreatorWorld_.getEntityManager();
            if(manager.hasComponent(mEntity_, EntityComponents.SCENE_NODE)){
                local sceneNodeComp = manager.getComponent(mEntity_, EntityComponents.SCENE_NODE);
                local node = sceneNodeComp.mNode;
                local attachedCount = node.getNumAttachedObjects();
                for(local i = 0; i < attachedCount; i++){
                    local obj = node.getAttachedObject(i);
                    obj.setRenderQueueGroup(renderQueue);
                }
            }
        }
    }
}