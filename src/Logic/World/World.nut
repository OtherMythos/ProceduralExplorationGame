::World <- class{

    mPlayerEntry_ = null;
    mActiveEnemies_ = null;
    mGui_ = null;
    mTargetManager_ = null;

    mSceneLogic_ = null;

    mCurrentHighlightEnemy_ = null;
    mPreviousHighlightEnemy_ = null;

    mRecentTargetEnemy_ = false;
    mPrevTargetEnemy_ = null;
    mCurrentTargetEnemy_ = null;

    mQueuedFlags_ = null;

    mActiveEXPOrbs_ = null;

    mOrientatingCamera_ = false;

    mPlacingMarker_ = false;

    mInputs_ = null;

    NUM_PLAYER_QUEUED_FLAGS = 1;

    constructor(activeEnemies, sceneLogic){
        //TODO get rid
        mActiveEnemies_ = activeEnemies;
        mSceneLogic_ = sceneLogic;

        mTargetManager_ = EntityTargetManager();
        mActiveEXPOrbs_ = {};

        mQueuedFlags_ = array(NUM_PLAYER_QUEUED_FLAGS, null);

        mInputs_ = {
            "move": _input.getAxisActionHandle("Move"),
            "camera": _input.getAxisActionHandle("Camera"),
            "playerMoves": [
                _input.getButtonActionHandle("PerformMove1"),
                _input.getButtonActionHandle("PerformMove2"),
                _input.getButtonActionHandle("PerformMove3"),
                _input.getButtonActionHandle("PerformMove4")
            ]
        };
    }

    function update(){
        checkHighlightEnemy();
        checkTargetEnemy();
        checkPlayerMove();
        checkForEnemyAppear();
        checkPlayerCombatMoves();

        mPlayerEntry_.update();
        foreach(i in mActiveEnemies_){
            i.update();
        }
    }

    function resetSession(){
        mPlayerEntry_ = ::ExplorationEntityFactory.constructPlayer(mGui_);
    }

    //-------
    function performPlayerAttack(){
        entityPerformAttack_(mPlayerEntry_);
    }
    function entityPerformAttack(eid){
        assert(mActiveEnemies_.rawin(eid));
        local enemy = mActiveEnemies_[eid];
        entityPerformAttack_(enemy);
    }
    function entityPerformAttack_(entityObject){
        //Determine which item the entity has equipped and determine the attack from there.
        //entityObject.performAttack();
    }

    function setGuiObject(guiObject){
        mGui_ = guiObject;
    }

    function performPlayerMove(moveId){
        local playerPos = mPlayerEntry_.mPos_.copy();
        performMove(moveId, playerPos, null, _COLLISION_ENEMY);
    }

    function performMove(moveId, pos, dir, collisionType){
        local moveDef = ::Moves[moveId];
        local targetProjectile = moveDef.getProjectile();
        if(targetProjectile != null){
            mProjectileManager_.spawnProjectile(targetProjectile, pos, dir, ::Combat.CombatMove(5), collisionType);
        }
    }

    function triggerPlayerMove(moveId){
        assert(moveId >= 0 && moveId < mPlayerMoves.len());
        local targetMoveId = mPlayerMoves[moveId];

        if(mGui_){
            //TODO in future store the cooldown data in the logic and communicate with the bus.
            local result = mGui_.notifyPlayerMove(moveId);
            if(result){
                performPlayerMove(targetMoveId);
            }
        }

    }

    function sceneSafeUpdate(){
        if(mGui_){
            local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
            if(inWindow != null){
                local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);

                local ray = camera.getCameraToViewportRay(inWindow.x, inWindow.y);
                local result = _scene.testRayForObject(ray, 1 << 4);
                if(result != null){
                    //TODO bit of a work around for the various nodes, probably not correct long term.
                    local parent = result.getParentNode().getParent().getParent();
                    assert(parent != null);

                    local enemy = getEntityForPosition(parent.getPositionVec3());
                    if(enemy != null){

                        if(_input.getMouseButton(0)){
                            setCurrentTargetEnemy_sceneSafe(enemy);
                        }else{
                            setCurrentHighlightEnemy(enemy);
                            return;
                        }
                    }
                }
            }
        }

        setCurrentHighlightEnemy(null);
    }
    //Bit of a work around, I just get the vector position and check through all entities.
    //TODO find a proper solution for this.
    function getEntityForPosition(pos){
        foreach(c,i in mActiveEnemies_){
            if(i.mPos_.x == pos.x && i.mPos_.y == pos.y){
                return c;
            }
        }
        return null;
    }

    function setCurrentHighlightEnemy(enemy){
        mPreviousHighlightEnemy_ = mCurrentHighlightEnemy_;
        mCurrentHighlightEnemy_ = enemy;
    }

    function setCurrentTargetEnemy_sceneSafe(currentEnemy){
        assert(currentEnemy != null);

        mPrevTargetEnemy_ = mCurrentTargetEnemy_;
        mCurrentTargetEnemy_ = currentEnemy;
        mRecentTargetEnemy_ = true;

        mTargetManager_.targetEntity(mActiveEnemies_[currentEnemy], mPlayerEntry_);
    }

    function notifyNewEntityHealth(entity, newHealth){
        local billboardIdx = -1;
        try{
            billboardIdx = _component.user[Component.MISC].get(entity, 0);
        }catch(e){ }

        if(billboardIdx >= 0){
            if(newHealth <= 0){
                mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(billboardIdx);
                return;
            }
            local maxHealth = _component.user[Component.HEALTH].get(entity, 1);
            local newPercentage = newHealth.tofloat() / maxHealth.tofloat();

            checkEntityHealthImportant(entity, newHealth, newPercentage);

            mGui_.mWorldMapDisplay_.mBillboardManager_.updateHealth(billboardIdx, newPercentage);
        }
    }

    function checkEntityHealthImportant(entity, newHealth, percentage){
        if(entity.getId() == mPlayerEntry_.getEntity().getId()){
            local data = {
                "health": newHealth,
                "percentage": percentage
            };
            _event.transmit(Event.PLAYER_HEALTH_CHANGED, data);
        }
    }

    function spawnEXPOrbs(pos, num, spread=4){
        for(local i = 0; i < num; i++){
            local randDir = (_random.rand()*2-1) * PI;

            //local targetPos = pos + (Vec3(_random.rand()-0.5, 0, _random.rand()-0.5) * spread);
            local targetPos = pos + (Vec3(sin(randDir) * spread, 0, cos(randDir) * spread));
            local newEntity = ::ExplorationEntityFactory.constructEXPOrb(targetPos);
            mActiveEXPOrbs_.rawset(newEntity.getId(), newEntity);
        }
    }

    function checkHighlightEnemy(){
        if(mCurrentHighlightEnemy_ == mPreviousHighlightEnemy_) return;

        assert(mCurrentHighlightEnemy_ != mPreviousHighlightEnemy_);
        print("Highlight enemy change");

        local enemy = null;
        if(mCurrentHighlightEnemy_ != null){
            if(mActiveEnemies_.rawin(mCurrentHighlightEnemy_)){
                enemy = mActiveEnemies_[mCurrentHighlightEnemy_].mEnemy_;
                print("===enemy " + enemy);
            }
        }
        if(mGui_) mGui_.notifyHighlightEnemy(enemy);
    }

    //Unfortunately as the scene is safe when the target enemy is registered I have to check this later.
    function checkTargetEnemy(){
        if(!mRecentTargetEnemy_) return;
        if(!mCurrentTargetEnemy_) return;

        setTargetEnemy(mCurrentTargetEnemy_);
    }
    function setTargetEnemy(target){
        if(mActiveEnemies_.rawin(mPrevTargetEnemy_)){
            mActiveEnemies_[mPrevTargetEnemy_].setGizmo(null);
        }

        local e = null;
        if(target != null){
            e = mActiveEnemies_[target];
            local gizmo = mSceneLogic_.createGizmo(e.getPosition(), ExplorationGizmos.TARGET_ENEMY);
            e.setGizmo(gizmo);
        }else{
            if(mActiveEnemies_.rawin(mCurrentTargetEnemy_)){
                local entity = mActiveEnemies_[mCurrentTargetEnemy_];
                entity.setGizmo(null);
            }
        }

        mCurrentTargetEnemy_ = target;
        mGui_.notifyPlayerTarget(e);
    }

    function checkPlayerMove(){
        //if(mEnemyEncountered_) return;
        //if(mExplorationPaused_) return;

        //TODO ewww clean this up.
        local moved = false;
        local xVal = _input.getAxisActionX(mInputs_.move, _INPUT_ANY);
        local yVal = _input.getAxisActionY(mInputs_.move, _INPUT_ANY);

        local dir = Vec2(xVal, yVal);
        moved = (xVal != 0 || yVal != 0);
        if(moved){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
            local targetForward = camera.getOrientation() * Vec3(xVal, 0, yVal);
            targetForward.y = 0;

            targetForward = Vec2(targetForward.x, targetForward.z);
            dir = Vec2(targetForward.x, targetForward.y) / 4;
        }

        //Try and walk to the queued position.
        local targetIdx = -1;
        local targetPos = null;
        //Perform first so the later checks will take precedent.
        if(mCurrentTargetEnemy_ != null){
            local targetEntity = mTargetManager_.getTargetForEntity(mPlayerEntry_);
            local enemyPos = targetEntity.getPosition();
            local playerPos = mPlayerEntry_.getPosition();
            if(!mTargetManager_.entityDetermineDistance(enemyPos, playerPos)){
                local dir = (mPlayerEntry_.getPosition() - enemyPos);
                dir.normalise();
                targetPos = enemyPos + (Vec3(4, 0, 4) * dir);
            }
        }


        if(_input.getMouseButton(0) && !mOrientatingCamera_ && !mRecentTargetEnemy_){
            if(mGui_){
                local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
                if(inWindow != null){
                    if(!mPlacingMarker_){
                        //The first touch of the mouse.
                        queuePlayerFlagForWindowTouch(inWindow);
                    }else{
                        updatePositionOfCurrentFlag(inWindow);
                    }
                    mPlacingMarker_ = true;

                    mGui_.notifyBlockInput(true);
                }
            }
        }else{
            mPlacingMarker_ = false;
            mGui_.notifyBlockInput(false);
        }
        if(moved){
            movePlayer(dir);
            return;
        }

        mRecentTargetEnemy_ = false;

        for(local i = 0; i < NUM_PLAYER_QUEUED_FLAGS; i++){
            if(mQueuedFlags_[i] != null){
                targetPos = mQueuedFlags_[i][0];
                targetIdx = i;
            }
        }
        if(targetPos == null){
            local disableAutoMove = _settings.getUserSetting("disableAutoMove");
            if(!disableAutoMove){
                //If no queued flags were found use the system intended location.
                targetPos = getSystemDeterminedFlag();
            }
        }
        if(targetPos != null){
            local finished = movePlayerToPos(targetPos);
            if(finished){
                //Remove the queued item.
                if(targetIdx < 0){
                    mDeterminedFlag_ = null;
                }else{
                    mSceneLogic_.removeLocationFlag(mQueuedFlags_[targetIdx][1]);
                    mQueuedFlags_[targetIdx] = null;
                }

                //if(mCurrentTargetEnemy_) performPlayerAttack();
            }
        }
    }

    function playerFlagBase_(touchCoords){
        local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
        if(inWindow != null){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
            assert(camera != null);
            local mTestPlane_ = Plane(Vec3(0, 1, 0), Vec3(0, 0, 0));
            local ray = camera.getCameraToViewportRay(touchCoords.x, touchCoords.y);
            local point = ray.intersects(mTestPlane_);
            if(point == false){
                return;
            }
            local worldPoint = ray.getPoint(point);

            return worldPoint;
        }
        return null;
    }
    function updatePositionOfCurrentFlag(touchCoords){
        local worldPoint = playerFlagBase_(touchCoords);

        if(mQueuedFlags_[0] == null) return;
        local flagId = mQueuedFlags_[0][1];
        mSceneLogic_.updateLocationFlagPos(flagId, worldPoint);
        mQueuedFlags_[0] = [worldPoint, flagId];
    }
    function queuePlayerFlagForWindowTouch(touchCoords){
        local worldPoint = playerFlagBase_(touchCoords);
        if(worldPoint == null) return;
        queuePlayerFlag(worldPoint);
    }
    function queuePlayerFlag(worldPos){
        //TODO this is all over the place, the data structure is a table so can't exactly shift things.
        local firstNull = mQueuedFlags_.find(null);
        if(firstNull == null){
            //There are no spaces in the list, so shift them all to the right.
            local queuedFlag = mQueuedFlags_.pop();
            mSceneLogic_.removeLocationFlag(queuedFlag[1]);
        }else{
            mQueuedFlags_.remove(firstNull);
        }
        local flagId = mSceneLogic_.queueLocationFlag(worldPos);
        mQueuedFlags_.insert(0, [worldPos, flagId]);
    }

    function movePlayerToPos(targetPos){
        mPlayerEntry_.moveToPoint(targetPos, 0.2, mSceneLogic_);

        notifyPlayerMoved();

        local newPos = mPlayerEntry_.mPos_.copy();
        local newTarget = targetPos.copy();
        newPos.y = 0;
        newTarget.y = 0;
        local distance = newTarget.distance(newPos);
        return distance < 0.4;
    }

    function notifyPlayerMoved(){
        local playerPos = Vec3(mPlayerEntry_.mPos_.x, 0, mPlayerEntry_.mPos_.z);
        mSceneLogic_.updatePlayerPos(playerPos);
        _world.setPlayerPosition(SlotPosition(playerPos));
        //TODO remove direct access.
        mGui_.mWorldMapDisplay_.mMapViewer_.setPlayerPosition(playerPos.x, playerPos.z);
    }

    function notifyEnemyDestroyed(eid){
        mActiveEnemies_[eid].notifyDestroyed();
        mActiveEnemies_.rawdelete(eid);
        if(eid == mCurrentTargetEnemy_){
            setTargetEnemy(null);
        }
    }

    function checkForEnemyAppear(){
        local foundSomething = _random.randInt(100) == 0;
        if(!foundSomething) return;
        if(mActiveEnemies_.len() >= 20){
            print("can't add any more enemies");
            return;
        }
        appearEnemy(_random.randInt(EnemyId.GOBLIN, EnemyId.MAX-1));
    }

    function getPositionForAppearEnemy_(){
        //TODO fix this
        return Vec3();
        //TODO in future have a more sophisticated method to solve this, for instance spawn locations stored in entity defs.
        if(enemyType == EnemyId.SQUID){
            return MapGenHelpers.findRandomPositionInWater(mCurrentMapData_, 0);
        }else{
            return MapGenHelpers.findRandomPointOnLand(mCurrentMapData_, mPlayerEntry_.getPosition(), 50);
        }
    }

    function appearEnemy(enemyType){
        local target = getPositionForAppearEnemy_();
        local enemyEntry = ::ExplorationEntityFactory.constructEnemy(enemyType, target, mGui_);
        mActiveEnemies_.rawset(enemyEntry.mEntity_.getId(), enemyEntry);
    }

    function moveEnemyToPlayer(enemyId){
        local enemyEntry = mActiveEnemies_[enemyId];
        if(enemyEntry == null) return;
        if(enemyEntry.isMidAttack()) return;

        enemyEntry.moveToPoint(mPlayerEntry_.mPos_, 0.05, mSceneLogic_);
    }



    function performPlayerAttack(){
        entityPerformAttack_(mPlayerEntry_);
    }
    function entityPerformAttack(eid){
        assert(mActiveEnemies_.rawin(eid));
        local enemy = mActiveEnemies_[eid];
        entityPerformAttack_(enemy);
    }
    function entityPerformAttack_(entityObject){
        //Determine which item the entity has equipped and determine the attack from there.
        //entityObject.performAttack();
    }

    function performPlayerMove(moveId){
        local playerPos = mPlayerEntry_.mPos_.copy();
        performMove(moveId, playerPos, null, _COLLISION_ENEMY);
    }

    function performMove(moveId, pos, dir, collisionType){
        local moveDef = ::Moves[moveId];
        local targetProjectile = moveDef.getProjectile();
        if(targetProjectile != null){
            mProjectileManager_.spawnProjectile(targetProjectile, pos, dir, ::Combat.CombatMove(5), collisionType);
        }
    }

    function notifyNewEntityHealth(entity, newHealth){
        local billboardIdx = -1;
        try{
            billboardIdx = _component.user[Component.MISC].get(entity, 0);
        }catch(e){ }

        if(billboardIdx >= 0){
            if(newHealth <= 0){
                mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(billboardIdx);
                return;
            }
            local maxHealth = _component.user[Component.HEALTH].get(entity, 1);
            local newPercentage = newHealth.tofloat() / maxHealth.tofloat();

            checkEntityHealthImportant(entity, newHealth, newPercentage);

            mGui_.mWorldMapDisplay_.mBillboardManager_.updateHealth(billboardIdx, newPercentage);
        }
    }

    function checkEntityHealthImportant(entity, newHealth, percentage){
        if(entity.getId() == mPlayerEntry_.getEntity().getId()){
            local data = {
                "health": newHealth,
                "percentage": percentage
            };
            _event.transmit(Event.PLAYER_HEALTH_CHANGED, data);
        }
    }

    function checkPlayerCombatMoves(){
        foreach(c,i in mInputs_.playerMoves){
            local buttonState = _input.getButtonAction(i, _INPUT_PRESSED);
            if(buttonState){
                triggerPlayerMove(c);
            }
        }
    }
};