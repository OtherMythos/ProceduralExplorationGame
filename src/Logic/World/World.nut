::ExplorationGizmo <- class{
    mSceneNode_ = null;
    constructor(parent, pos){
        setup(parent);
        setPosition(pos);
    }
    function setPosition(pos){
        mSceneNode_.setPosition(pos);
    }
    function destroy(){
        mSceneNode_.destroyNodeAndChildren();
    }
    function setup(parent){}
};
::ExplorationGizmos <- array(ExplorationGizmos.MAX, null);

::ExplorationGizmos[ExplorationGizmos.TARGET_ENEMY] = class extends ::ExplorationGizmo{
    mAnim_ = null;
    function setup(parent){
        mSceneNode_ = parent.createChildSceneNode();
        local animNode = mSceneNode_.createChildSceneNode();

        local targetItem = _scene.createItem("enemyTargetMarker.mesh");
        targetItem.setRenderQueueGroup(30);
        animNode.attachObject(targetItem);
        animNode.setScale(0.5, 0.5, 0.5);
        animNode.setPosition(0, 1, 0);

        local animationInfo = _animation.createAnimationInfo([animNode]);
        mAnim_ = _animation.createAnimation("gizmoEnemyTarget", animationInfo);
    }
    function destroy(){
        mSceneNode_.destroyNodeAndChildren();
        mAnim_ = null;
    }
};


::World <- class{

    //TODO remove this at some point.
    mPlayerMoves = [
        MoveId.AREA,
        MoveId.FIREBALL,
        MoveId.AREA,
        MoveId.AREA
    ];

    CloudManager = class{
        mParentNode_ = null;
        NUM_CLOUDS = 9;
        mActiveClouds_ = null;
        mSize_ = null;
        constructor(parent, width, height){
            mSize_ = Vec3(width, 0, -height);
            mParentNode_ = parent;
            mActiveClouds_ = [];
            for(local i = 0; i < NUM_CLOUDS; i++){
                local newCloud = setupCloud();
                mActiveClouds_.append(newCloud);
            }
        }

        function update(){
            foreach(i in mActiveClouds_){
                local cloudPosition = i.getPositionVec3();
                cloudPosition.z -= 0.1;
                if(cloudPosition.z <= mSize_.z){
                    cloudPosition.z = 100;
                }
                i.setPosition(cloudPosition);
            }
        }

        function setupCloud(){
            local newNode = mParentNode_.createChildSceneNode();
            local item = _scene.createItem("cloud.mesh");
            item.setRenderQueueGroup(70);
            newNode.attachObject(item);
            local outPos = _random.randVec3() * mSize_;
            outPos.y = 50;
            newNode.setPosition(outPos);
            newNode.setScale(2, 2, 2);
            //newNode.setOrientation(Quat(_random.rand() * PI, Vec3(0, 0, 1)));
            return newNode;
        }
    };

    mParentNode_ = null;

    mWorldId_ = null;

    mHasEverBeenActive_ = false;
    mActive_ = false;

    mPlayerEntry_ = null;
    mActiveEnemies_ = null;
    mGui_ = null;
    mTargetManager_ = null;

    mEntityFactory_ = null;

    mCurrentHighlightEnemy_ = null;
    mPreviousHighlightEnemy_ = null;

    mProjectileManager_ = null;

    mRecentTargetEnemy_ = false;
    mPrevTargetEnemy_ = null;
    mCurrentTargetEnemy_ = null;

    mDamageCollisionWorld_ = null;
    mTriggerCollisionWorld_ = null;
    mEntityManager_ = null;

    mLocationFlagIds_ = 0;
    mLocationFlagNodes_ = null;

    mPosition_ = null;
    mRotation_ = null;
    mCurrentZoomLevel_ = 30;
    static MIN_ZOOM = 10;

    mQueuedFlags_ = null;

    mActiveGizmos_ = null;

    mOrientatingCamera_ = false;

    mPlacingMarker_ = false;

    mInputs_ = null;

    NUM_PLAYER_QUEUED_FLAGS = 1;

    constructor(worldId){
        mWorldId_ = worldId;
        mActiveEnemies_ = {};
        mLocationFlagNodes_ = {};
        mActiveGizmos_ = {};

        mRotation_ = Vec2(PI*0.5, PI*0.4);
        mPosition_ = Vec3();

        mTargetManager_ = EntityTargetManager();

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

    function getWorldType(){
        return WorldTypes.WORLD;
    }
    function getDamageWorld(){
        return mDamageCollisionWorld_;
    }
    function getTriggerWorld(){
        return mTriggerCollisionWorld_;
    }
    function getEntityManager(){
        return mEntityManager_;
    }
    function getWorldId(){
        return mWorldId_;
    }

    function shutdown(){
        foreach(i in mActiveEnemies_){
            i.notifyDestroyed();
        }
        mPlayerEntry_.notifyDestroyed();

        mActiveEnemies_.clear();

        clearAllLocationFlags();

        if(mParentNode_) mParentNode_.destroyNodeAndChildren();
        mParentNode_ = null;

        //_world.destroyWorld();
    }

    function setup(){
        //_world.createWorld();

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
        mEntityFactory_ = EntityFactory(this, mParentNode_, CharacterGenerator());
        //_developer.setRenderQueueForMeshGroup(30);

        mDamageCollisionWorld_ = CollisionWorldWrapper(this);
        mTriggerCollisionWorld_ = CollisionWorldWrapper(this);

        mEntityManager_ = EntityManager.createEntityManager();
    }


    function processEXPOrb(entityId){
        local sender = entityId;
        local receiver = mPlayerEntry_.mEntity_;
        if(!mEntityManager_.entityValid(sender) || !mEntityManager_.entityValid(receiver)) return;

        local senderPos = mEntityManager_.getPosition(sender);
        local senderFirst = senderPos.xz();
        local receiverFirst = mPlayerEntry_.getPosition().xz();
        local distance = senderFirst.distance(receiverFirst);
        if(distance >= 4) return;
        if(distance <= 0.8){
            ::Base.mExplorationLogic.notifyFoundEXPOrb();
            mEntityManager_.destroyEntity(entityId);
            return;
        }

        distance /= 4;

        local anim = sqrt(1 - pow(distance - 1, 2)) * 0.4;
        mEntityManager_.moveTowards(sender, mPlayerEntry_.getPosition(), anim);
    }

    function update(){
        checkHighlightEnemy();
        checkTargetEnemy();
        checkPlayerMove();
        checkForEnemyAppear();
        checkForDistractionAppear();
        checkPlayerCombatMoves();

        mProjectileManager_.update();
        mEntityManager_.update();

        mPlayerEntry_.update();
        foreach(i in mActiveEnemies_){
            i.update();
        }

        mDamageCollisionWorld_.processCollision();
        mTriggerCollisionWorld_.processCollision();
    }

    function setActive(active){
        mActive_ = active;
        if(active){
            if(!mHasEverBeenActive_){
                setup();
            }
            mHasEverBeenActive_ = true;
        }else{
            //TODO this whole section could do with being better.
            //destroyEnemyMap_(mActiveEnemies_);
            //mPlayerEntry_.notifyDestroyed();
            //::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackAllNodes();
        }

        mParentNode_.setVisible(active, true);
        processActiveChange_(active);

    }
    function destroyEnemyMap_(target){
        local enemies = [];
        //printf("%i current", target.len());
        foreach(i in target){
            enemies.append(i.mEntity_);
        }
        foreach(i in enemies){
            mEntityManager_.destroyEntity(i);
        }

        foreach(i in target){
            i.notifyDestroyed();
        }
        target.clear();
        //assert(target.len() == 0);
    }

    function processActiveChange_(active){
        //Stub
    }

    function resetSession(){
        mPlayerEntry_ = mEntityFactory_.constructPlayer(mGui_);

        if(mProjectileManager_ != null) mProjectileManager_.shutdown();
        mProjectileManager_ = ExplorationProjectileManager(mDamageCollisionWorld_);

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

    function notifyNewEntityHealth(entity, newHealth, newPercentage){
        //TODO the health node should notify all entities rather than doing it here.
        if(mActiveEnemies_.rawin(entity)){
            local enemy = mActiveEnemies_[entity];
            enemy.notifyNewHealth(newHealth, newPercentage);
        }

        checkEntityHealthImportant(entity, newHealth, newPercentage);
    }

    function checkEntityHealthImportant(entity, newHealth, percentage){
        if(entity == mPlayerEntry_.getEntity()){
            local data = {
                "health": newHealth,
                "percentage": percentage
            };
            mPlayerEntry_.notifyNewHealth(newHealth, percentage);
            _event.transmit(Event.PLAYER_HEALTH_CHANGED, data);

            if(newHealth <= 0){
                _event.transmit(Event.PLAYER_DIED, null);
            }
        }
    }

    function spawnEXPOrbs(pos, num, spread=4){
        for(local i = 0; i < num; i++){
            local randDir = (_random.rand()*2-1) * PI;

            //local targetPos = pos + (Vec3(_random.rand()-0.5, 0, _random.rand()-0.5) * spread);
            local targetPos = pos + (Vec3(sin(randDir) * spread, 0, cos(randDir) * spread));
            mEntityFactory_.constructEXPOrb(targetPos);
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
            local gizmo = createGizmo(e.getPosition(), ExplorationGizmos.TARGET_ENEMY);
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
                    removeLocationFlag(mQueuedFlags_[targetIdx][1]);
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
        updateLocationFlagPos(flagId, worldPoint);
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
            removeLocationFlag(queuedFlag[1]);
        }else{
            mQueuedFlags_.remove(firstNull);
        }
        local flagId = queueLocationFlag(worldPos);
        mQueuedFlags_.insert(0, [worldPos, flagId]);
    }

    function movePlayerToPos(targetPos){
        mPlayerEntry_.moveToPoint(targetPos, 0.2);

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
        updatePlayerPos(playerPos);
        //_world.setPlayerPosition(SlotPosition(playerPos));
        //TODO remove direct access.
        if(mGui_.mWorldMapDisplay_.mMapViewer_){
            mGui_.mWorldMapDisplay_.mMapViewer_.setPlayerPosition(playerPos.x, playerPos.z);
        }
    }

    function notifyEnemyDestroyed(eid){
        mActiveEnemies_[eid].notifyDestroyed();
        mActiveEnemies_.rawdelete(eid);
        if(eid == mCurrentTargetEnemy_){
            setTargetEnemy(null);
        }
    }

    function checkForDistractionAppear(){
        local foundSomething = _random.randInt(1000) == 0;
        if(!foundSomething) return;

        //TODO rename or alter the method call.
        local target = getPositionForAppearEnemy_(EnemyId.GOBLIN);
        mEntityFactory_.constructPercentageEncounter(target, mGui_);
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

    function getPositionForAppearEnemy_(enemyType){
        return Vec3();
    }

    function createEnemy(enemyType, pos){
        local enemyEntry = mEntityFactory_.constructEnemy(enemyType, pos, mGui_);
        mActiveEnemies_.rawset(enemyEntry.mEntity_, enemyEntry);
    }
    function appearEnemy(enemyType){
        local target = getPositionForAppearEnemy_(enemyType);
        createEnemy(enemyType, target);
    }

    function moveEnemyToPlayer(enemyId){
        local enemyEntry = mActiveEnemies_[enemyId];
        if(enemyEntry == null) return;
        if(enemyEntry.isMidAttack()) return;

        enemyEntry.moveToPoint(mPlayerEntry_.mPos_, 0.05);
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

    function checkPlayerCombatMoves(){
        foreach(c,i in mInputs_.playerMoves){
            local buttonState = _input.getButtonAction(i, _INPUT_PRESSED);
            if(buttonState){
                triggerPlayerMove(c);
            }
        }
    }

    //TODO remove flag logic at some point.
    function queueLocationFlag(pos){
        local flagNode = mParentNode_.createChildSceneNode();
        local flagItem = _scene.createItem("locationFlag.mesh");
        flagItem.setRenderQueueGroup(30);
        flagNode.attachObject(flagItem);
        pos.y = getZForPos(pos);
        flagNode.setPosition(pos);
        flagNode.setScale(0.5, 0.5, 0.5);
        local idx = (mLocationFlagIds_++).tostring();
        mLocationFlagNodes_[idx] <- flagNode;
        return idx;
    }
    function updateLocationFlagPos(idx, pos){
        local newPos = pos.copy();
        newPos.y = getZForPos(newPos);
        mLocationFlagNodes_[idx].setPosition(newPos);
    }
    function removeLocationFlag(idx){
        if(mLocationFlagNodes_[idx] == null) return;
        mLocationFlagNodes_[idx].destroyNodeAndChildren();
        mLocationFlagNodes_[idx] = null;
    }
    function clearAllLocationFlags(){
        foreach(c,i in mLocationFlagNodes_){
            if(i == null) continue;
            removeLocationFlag(c);
        }
    }
    //TODO the flags can be converted to use the gizmos as well.
    function createGizmo(pos, gizmoType){
        local newGizmo = ::ExplorationGizmos[gizmoType](mParentNode_, pos);
        return newGizmo;
    }

    function actuateSpoils(data){
        if(data.mType == SpoilsComponentType.PERCENTAGE){
            local percentage = _random.randInt(0, 100);
            local first = percentage >= 0 && percentage < data.mFirst;
            local targetData = first ? data.mSecond : data.mThird;
            if(targetData.mType == PercentageEncounterEntryType.EXP){
                spawnEXPOrbs(mPlayerEntry_.getPosition(), targetData.mAmount);
            }
            else if(targetData.mType == PercentageEncounterEntryType.ENEMY){
                for(local i = 0; i < targetData.mAmount; i++){
                    local playerPos = mPlayerEntry_.getPosition().copy();
                    local offset = ((_random.randVec3()-0.5) * 16);
                    offset.y = 0;
                    playerPos += offset;
                    createEnemy(targetData.mSecondaryType, playerPos);
                }
            }
        }
    }

    function updatePlayerPos(playerPos){
        mPosition_ = playerPos;
    }

    function getTraverseTerrainForPosition(pos){
        return 0xFF;
    }

    function getIsWaterForPosition(pos){
        return false;
    }
};

_doFile("res://src/Logic/World/CollisionWorldWrapper.nut");
_doFile("res://src/Logic/World/EntityFactory.nut");