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

enum WorldMousePressContexts{
    TARGET_ENEMY,
    PLACING_FLAG,
    ORIENTING_CAMERA,
    //In the case of a window that takes the full screen with exploration in the back, ensure clicks to leave don't result in a flag press.
    POPUP_WINDOW,
};

::World <- class{

    //TODO remove this at some point.
    mPlayerMoves = [
        MoveId.AREA,
        MoveId.FIREBALL,
        MoveId.AREA,
        MoveId.AREA
    ];

    FoundObjectLogic = class{

        mDataCount_ = null;
        mData_ = null;

        constructor(data){
            mDataCount_ = array(data.len(), 0);
            mData_ = data;
        }
        function update(){
            for(local i = 0; i < mDataCount_.len(); i++){
                mDataCount_[i]++;
            }
        }
        function checkAppearForObject(object){
            local maxIncrease = mData_[object].maxIncrease;
            local maxEncounter = mData_[object].maxEncounter;

            local targetIncrease = mDataCount_[object] >= maxIncrease ? maxIncrease : mDataCount_[object];
            local rate = maxEncounter - targetIncrease;

            local foundSomething = _random.randInt(rate) == 0;
            if(foundSomething){
                mDataCount_[object] = 0;
            }
            return foundSomething;
        }
    };

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
    /**
     * A state machine to manage logic relating to mouse presses.
     * If the player clicks an enemy the system shouldn't place location flags.
     * Similarly if placing a flag the system shouldn't erroneously trigger a target.
     */
    MousePressContext = class{
        mCurrentState_ = null;
        mGui_ = null;

        constructor(){

        }
        function update(){
            //print("Mouse state: " + mCurrentState_);
        }
        function beginState_(state){
            if(mCurrentState_ != null) return false;
            mCurrentState_ = state;
            if(mGui_) mGui_.notifyBlockInput(true);
            return true;
        }
        function requestTargetEnemy(){
            return beginState_(WorldMousePressContexts.TARGET_ENEMY);
        }
        function requestFlagLogic(){
            return beginState_(WorldMousePressContexts.PLACING_FLAG);
        }
        function requestOrientingCamera(){
            return beginState_(WorldMousePressContexts.ORIENTING_CAMERA);
        }
        function requestPopupWindow(){
            return beginState_(WorldMousePressContexts.POPUP_WINDOW);
        }
        function notifyMouseEnded(){
            if(mCurrentState_ == null) return;
            mCurrentState_ = null;
            if(mGui_) mGui_.notifyBlockInput(false);
        }
        function getCurrentState(){
            return mCurrentState_;
        }
        //TODO I don't like this, consider re-architecting
        function setGuiObject(guiObj){
            mGui_ = guiObj;
        }
    };

    mParentNode_ = null;

    mWorldId_ = null;

    mWorldPreparer_ = null;
    mCurrent_ = false;
    mReady_ = false;

    mPlayerEntry_ = null;
    mActiveEnemies_ = null;
    mActiveWorldActions_ = null;
    mGui_ = null;
    mTargetManager_ = null;

    mEntityFactory_ = null;

    mCurrentHighlightEnemy_ = null;
    mPreviousHighlightEnemy_ = null;

    mProjectileManager_ = null;

    mPrevTargetEnemy_ = null;
    mCurrentTargetEnemy_ = null;

    mDamageCollisionWorld_ = null;
    mTriggerCollisionWorld_ = null;
    mEntityManager_ = null;

    mLocationFlagIds_ = 0;
    mLocationFlagNodes_ = null;

    mAppearDistractionLogic_ = null;

    mPosition_ = null;
    mRotation_ = null;
    mCurrentZoomLevel_ = 30;
    static MIN_ZOOM = 10;

    mQueuedFlags_ = null;

    mActiveGizmos_ = null;

    mPrevMouseX_ = null;
    mPrevMouseY_ = null;
    mMouseContext_ = null;

    mInputs_ = null;

    NUM_PLAYER_QUEUED_FLAGS = 1;

    constructor(worldId, preparer){
        mWorldId_ = worldId;
        mWorldPreparer_ = preparer;
        mActiveEnemies_ = {};
        mLocationFlagNodes_ = {};
        mActiveGizmos_ = {};
        mActiveWorldActions_ = [];

        mAppearDistractionLogic_ = FoundObjectLogic([
            {
                "maxIncrease": 200,
                "maxEncounter": 1000
            },
            {
                "maxIncrease": 200,
                "maxEncounter": 500
            },
            {
                "maxIncrease": 100,
                "maxEncounter": 500
            },
            WorldDistractionType.PERCENTAGE_ENCOUNTER
        ]);

        mMouseContext_ = MousePressContext();

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
            ],
            "canceltarget": _input.getButtonActionHandle("CancelTarget"),
            "showInventory": _input.getButtonActionHandle("ShowInventory"),
            "pauseGame": _input.getButtonActionHandle("PauseGame"),
        };
    }

    function getWorldType(){
        return WorldTypes.WORLD;
    }
    function getWorldTypeString(){
        return "World";
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
    function getPlayerPosition(){
        return mPlayerEntry_.getPosition();
    }

    function processPreparation(){
        local result = mWorldPreparer_.processPreparation();
        if(result){
            notifyPreparationComplete_();
        }
        return result;
    }
    function preparationComplete(){
        return mWorldPreparer_.preparationComplete();
    }
    #Stub
    function notifyPreparationComplete_(){
    }

    function shutdown(){
        printf("Shutting down world of type %i with id %i", getWorldType(), getWorldId());

        foreach(i in mActiveEnemies_){
            i.notifyDestroyed();
        }
        mEntityManager_.destroyAllEntities();
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

        mEntityManager_ = EntityManager.createEntityManager(this);
    }

    function playerHealthChanged(data){
        //TODO remove this duplication.
        //Have a single place to store health and make sure it's set from a single function.
        local component = mEntityManager_.getComponent(mPlayerEntry_.getEntity(), EntityComponents.HEALTH);
        component.mHealth = data.health;
        mPlayerEntry_.notifyNewHealth(data.health, data.percentage);
    }
    function playerEquipChanged(data){
        printf("Player equip changed '%s'", data.tostring());
        mPlayerEntry_.getModel().equipDataToCharacterModel(data);
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

    function checkDebugBodges(){
        if(_input.getMousePressed(1)){
            //::Base.mExplorationLogic.spawnEXPOrbs(mPlayerEntry_.getPosition(), 4);
            //mCurrentWorld_.spawnEXPOrbs(mCurrentWorld_.mPlayerEntry_.getPosition(), 1);

            //::Base.mExplorationLogic.gatewayEndExploration();
            //::Base.mExplorationLogic.pushWorld(::Base.mExplorationLogic.createWorldInstance(WorldTypes.PROCEDURAL_EXPLORATION_WORLD));

            ::_applyDamageOther(mEntityManager_, mPlayerEntry_.getEID(), 10000);

            //spawnDroppedItem(mPlayerEntry_.getPosition() + Vec3(5, 0, 0), ::Item(ItemId.SIMPLE_SWORD));
        }
    }

    function update(){
        checkCameraChange();
        checkOrientatingCamera();
        checkHighlightEnemy();
        checkPlayerMove();
        checkTargetEnemy();
        checkForFlagPlacement();
        checkForFlagUpdate();
        checkForEnemyAppear();
        checkForDistractionAppear();
        checkPlayerInputs();

        if(::Base.isProfileActive(GameProfile.ENABLE_RIGHT_CLICK_WORKAROUNDS)){
            checkDebugBodges();
        }

        mProjectileManager_.update();
        mEntityManager_.update();

        if(!_input.getMouseButton(0)){
            mMouseContext_.notifyMouseEnded();
        }
        mMouseContext_.update();

        mPlayerEntry_.update();
        foreach(i in mActiveEnemies_){
            i.update();
        }
        updateWorldActions();

        mDamageCollisionWorld_.processCollision();
        mTriggerCollisionWorld_.processCollision();
    }

    function setCurrentWorld(current){
        mCurrent_ = current;
        processWorldCurrentChange_(current);
    }

    function notifyReady_(){
        setup();
    }

    #Stub
    function processWorldCurrentChange_(current){
    }
    #Stub
    function processWorldActiveChange_(active){
    }

    function resetSession(){
        mPlayerEntry_ = mEntityFactory_.constructPlayer(mGui_, ::Base.mPlayerStats);
        local data = {
            "health": ::Base.mPlayerStats.mPlayerCombatStats.mMaxHealth,
            "percentage": ::Base.mPlayerStats.mPlayerCombatStats.getHealthPercentage()
        };
        _event.transmit(Event.PLAYER_HEALTH_CHANGED, data);

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
        mMouseContext_.setGuiObject(guiObject);
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
        if(!isActive()) return;
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
                        setCurrentHighlightEnemy(enemy);
                        return;
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
            ::Base.mPlayerStats.setPlayerHealth(newHealth);
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

    function spawnMoney(pos, num, spread=4){
        for(local i = 0; i < num; i++){
            local randDir = (_random.rand()*2-1) * PI;

            local targetPos = pos + (Vec3(sin(randDir) * spread, 0, cos(randDir) * spread));
            mEntityFactory_.constructMoneyObject(targetPos);
        }
    }

    function spawnDroppedItem(pos, wrappedItem){
        mEntityFactory_.constructCollectableItemObject(pos, wrappedItem);
    }

    function spawnEnemies(pos, num, spread=4){
        for(local i = 0; i < num; i++){
            local randDir = (_random.rand()*2-1) * PI;

            local targetPos = pos + (Vec3(sin(randDir) * spread, 0, cos(randDir) * spread));
            createEnemy(EnemyId.GOBLIN, targetPos);
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

    function setTargetEnemy(target){
        if(mActiveEnemies_.rawin(mPrevTargetEnemy_)){
            mActiveEnemies_[mPrevTargetEnemy_].setGizmo(null);
        }

        local e = null;
        if(target != null){
            e = mActiveEnemies_[target];
            local gizmo = createGizmo(e.getPosition(), ExplorationGizmos.TARGET_ENEMY);
            e.setGizmo(gizmo);

            mTargetManager_.targetEntity(mActiveEnemies_[target], mPlayerEntry_);
        }else{
            if(mActiveEnemies_.rawin(mCurrentTargetEnemy_)){
                local entity = mActiveEnemies_[mCurrentTargetEnemy_];
                entity.setGizmo(null);
            }
        }

        mCurrentTargetEnemy_ = target;
        mGui_.notifyPlayerTarget(e);
    }

    function checkTargetEnemy(){
        if(!_input.getMouseButton(0) || mMouseContext_.getCurrentState() != null) return;
        if(mCurrentHighlightEnemy_ == null) return;

        setTargetEnemy(mCurrentHighlightEnemy_);

        local result = mMouseContext_.requestTargetEnemy();
        //Just because we've gone to the effort to check if the state is null.
        assert(result);

        mPrevTargetEnemy_ = mCurrentTargetEnemy_;
        mCurrentTargetEnemy_ = mCurrentHighlightEnemy_;
    }
    function checkForFlagPlacement(){
        if(!mGui_) return;
        if(!_input.getMouseButton(0) || mMouseContext_.getCurrentState() != null) return;

        local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
        if(inWindow != null){
            //The first touch of the mouse.
            queuePlayerFlagForWindowTouch(inWindow);
            local result = mMouseContext_.requestFlagLogic();
            assert(result);
        }
    }
    function checkForFlagUpdate(){
        if(mMouseContext_.getCurrentState() == WorldMousePressContexts.PLACING_FLAG){
            if(mGui_){
                local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
                if(inWindow != null){
                    updatePositionOfCurrentFlag(inWindow);
                }
            }
        }
    }
    function checkPlayerMove(){
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
        if(moved){
            movePlayer(dir);
        }

        for(local i = 0; i < NUM_PLAYER_QUEUED_FLAGS; i++){
            if(mQueuedFlags_[i] != null){
                targetPos = mQueuedFlags_[i][0];
                targetIdx = i;
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

    function movePlayer(amount){
        local targetPos = mPlayerEntry_.mPos_ + Vec3(amount.x, 0, amount.y);
        movePlayerToPos(targetPos);
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

        local changed = mPlayerEntry_.checkVoxelChange();
        if(changed){
            notifyPlayerVoxelChange();
        }
    }

    function notifyPlayerVoxelChange(){
        //Stub
    }

    function notifyEnemyDestroyed(eid){
        mActiveEnemies_[eid].notifyDestroyed();
        mActiveEnemies_.rawdelete(eid);
        if(eid == mCurrentTargetEnemy_){
            setTargetEnemy(null);
        }
    }

    function checkForDistractionAppear(){
        if(::Base.isProfileActive(GameProfile.DISABLE_DISTRACTION_SPAWN)) return;

        mAppearDistractionLogic_.update();

        local target = getPositionForAppearEnemy_(EnemyId.GOBLIN);
        if(target == null) return;
        if(mAppearDistractionLogic_.checkAppearForObject(WorldDistractionType.PERCENTAGE_ENCOUNTER)){
            mEntityFactory_.constructPercentageEncounter(target, mGui_);
        }
        if(mAppearDistractionLogic_.checkAppearForObject(WorldDistractionType.HEALTH_ORB)){
            mEntityFactory_.constructHealthOrbEncounter(target);
        }
        if(mAppearDistractionLogic_.checkAppearForObject(WorldDistractionType.EXP_ORB)){
            mEntityFactory_.constructEXPTrailEncounter(target);
        }
    }
    function checkForEnemyAppear(){
        if(::Base.isProfileActive(GameProfile.DISABLE_ENEMY_SPAWN)) return;

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

    //TODO misleading, I should make it more obvious that I have to call create enemy rather than the factory directly.
    function createEnemy(enemyType, pos){
        local enemyEntry = mEntityFactory_.constructEnemy(enemyType, pos, mGui_);
        mActiveEnemies_.rawset(enemyEntry.mEntity_, enemyEntry);
    }
    function appearEnemy(enemyType){
        local target = getPositionForAppearEnemy_(enemyType);
        if(target == null) return;
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

    function checkPlayerInputs(){
        foreach(c,i in mInputs_.playerMoves){
            local buttonState = _input.getButtonAction(i, _INPUT_PRESSED);
            if(buttonState){
                triggerPlayerMove(c);
            }
        }

        if(_input.getButtonAction(mInputs_.canceltarget, _INPUT_PRESSED)){
            setTargetEnemy(null);
        }
        if(_input.getButtonAction(mInputs_.showInventory, _INPUT_PRESSED)){
            showInventory();
        }
        if(_input.getButtonAction(mInputs_.pauseGame, _INPUT_PRESSED)){
            ::Base.mExplorationLogic.setGamePaused(true);
        }
    }

    function showInventory(){
        notifyModalPopupScreen();
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN,
            {"stats": ::Base.mPlayerStats}),
            null, 1);
        ::Base.mExplorationLogic.pauseExploration();
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

    function pushWorldAction(actionInstance){
        mActiveWorldActions_.append(actionInstance);
    }
    function updateWorldActions(){
        local finishedActions = null;
        foreach(c,i in mActiveWorldActions_){
            local result = i.update();
            if(!result){
                if(finishedActions == null) finishedActions = [];
                finishedActions.append(c);
            }
        }

        if(finishedActions != null){
            foreach(i in finishedActions){
                mActiveWorldActions_.remove(i);
            }
        }
    }

    function actuateSpoils(data, position){
        if(data.mType == SpoilsComponentType.SPOILS_DATA){
            foreach(i in data.mFirst){
                if(i.mType == SPOILS_ENTRIES.EXP_ORBS){
                    spawnEXPOrbs(position, i.mFirst);
                }
                else if(i.mType == SPOILS_ENTRIES.COINS){
                    spawnMoney(position, i.mFirst);
                }
                else if(i.mType == SPOILS_ENTRIES.SPAWN_ENEMIES){
                    spawnEnemies(position, i.mFirst);
                }
                else if(i.mType == SPOILS_ENTRIES.DROPPED_ITEMS){
                    spawnDroppedItem(position, i.mFirst);
                }
            }
        }
        else if(data.mType == SpoilsComponentType.PERCENTAGE){
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
        else if(data.mType == SpoilsComponentType.EXP_TRAIL){
            local action = ::EXPTrailAction(this, position.copy(), _random.randVec2()-0.5, data.mFirst);
            pushWorldAction(action);
        }
        else if(data.mType == SpoilsComponentType.SPAWN_EXP_ORBS){
            spawnEXPOrbs(position, data.mFirst);
        }
        else if(data.mType == SpoilsComponentType.ADD_HEALTH){
            ::_applyHealthIncrease(mEntityManager_, mPlayerEntry_.getEntity(), data.mFirst);
        }
        else if(data.mType == SpoilsComponentType.GIVE_MONEY){

            //local worldPos = ::EffectManager.getWorldPositionForWindowPos(mGui_.mWorldMapDisplay_.getPosition() + mGui_.mWorldMapDisplay_.getSize() / 2);
            //local endPos = mGui_.getMoneyCounter().getPositionWindowPos();
            //::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 5, "start": worldPos, "end": endPos, "money": 100}));

            local worldPos = ::EffectManager.getWorldPositionForWindowPos(::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getPosition() + ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getSize() / 2);
            local endPos = ::Base.mExplorationLogic.mGui_.getEXPCounter().getPositionWindowPos();

            ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_COIN_EFFECT, {"numCoins": 1, "start": worldPos, "end": endPos, "money": 1, "coinScale": 0.2}));
        }
        else if(data.mType == SpoilsComponentType.GIVE_ITEM){
            printf("Giving player item %s", data.mFirst.tostring());
            ::Base.mPlayerStats.addToInventory(data.mFirst);
        }
    }

    function getStatsString(){
        return null;
    }

    function isActive(){
        return mCurrent_ && mReady_;
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

    function setOrientatingCamera(orientate){
        mMouseContext_.requestOrientingCamera();
    }
    function checkOrientatingCamera(){
        if(mMouseContext_.getCurrentState() != WorldMousePressContexts.ORIENTING_CAMERA) return;
        print("orientating");

        if(_input.getMouseButton(0)){
            local mouseX = _input.getMouseX();
            local mouseY = _input.getMouseY();
            if(mPrevMouseX_ != null && mPrevMouseY_ != null){
                local deltaX = mouseX - mPrevMouseX_;
                local deltaY = mouseY - mPrevMouseY_;
                printf("delta x: %f y: %f", deltaX, deltaY);
                processCameraMove(deltaX*-0.2, deltaY*-0.2);
            }
            mPrevMouseX_ = mouseX;
            mPrevMouseY_ = mouseY;
        }else{
            //Wait for the first move to happen.
            if(mPrevMouseX_ != null && mPrevMouseY_ != null){
                mPrevMouseX_ = null;
                mPrevMouseY_ = null;
            }
        }
    }
    function checkCameraChange(){
        local modifier = 1;
        local x = _input.getAxisActionX(mInputs_.camera, _INPUT_ANY);
        local y = _input.getAxisActionY(mInputs_.camera, _INPUT_ANY);
        processCameraMove(x*modifier, y*modifier);
    }

    function notifyModalPopupScreen(){
        mMouseContext_.requestPopupWindow();
    }

};

_doFile("res://src/Logic/World/CollisionWorldWrapper.nut");
_doFile("res://src/Logic/World/EntityFactory.nut");