::w <- {
}
::w.e <- {
}

/**
 * Logic interface for exploration.
 *
 * The exploration screen uses this class to determine how the exploration is progressing.
 * This prevents the gui from having to implement any of the actual logic.
 */
::ExplorationLogic <- class{

    ActiveEnemyEntry = class{
        mEnemy_ = Enemy.NONE;
        mPos_ = null;
        mId_ = null;
        mEncountered_ = false;
        mModel_ = null;
        mMoving_ = 0;
        mGizmo_ = null;
        mCombatData_ = null;

        mEntity_ = null;

        mPerformingEquippable_ = null;

        constructor(enemyType, enemyPos, entity){
            mEnemy_ = enemyType;
            mPos_ = enemyPos;
            mEntity_ = entity;
        }
        function setPosition(pos){
            mPos_ = pos;
            if(mEntity_) mEntity_.setPosition(SlotPosition(pos));
            if(mGizmo_) mGizmo_.setPosition(pos);
        }
        function getSceneNode(){
            return _component.sceneNode.getNode(mEntity_);
        }
        function getPosition(){
            return mPos_;
        }
        function getEntity(){
            return mEntity_;
        }
        function setModel(model){
            mModel_ = model;
        }
        function setCombatData(combatData){
            mCombatData_ = combatData;
        }
        function move(amount){
            setPosition(mPos_ + amount);
            if(mModel_){
                local orientation = Quat(atan2(amount.x, amount.z), Vec3(0, 1, 0));
                mModel_.setOrientation(orientation);
            }else{
                if(mEntity_){
                    local orientation = Quat(atan2(amount.x, amount.z), Vec3(0, 1, 0));
                    getSceneNode().setOrientation(orientation);
                }
            }

            if(mMoving_ == 0){
                if(mModel_){
                    mModel_.startAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
                    mModel_.startAnimation(CharacterModelAnimId.BASE_ARMS_WALK);
                }
            }
            mMoving_ = 10;
        }
        function moveQueryZ(amount, sceneLogic){
            local zQuery = sceneLogic.getZForPos(mPos_ + amount);
            mPos_.y = zQuery;
            move(amount);
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
                    if(mModel_){
                        mModel_.stopAnimation(CharacterModelAnimId.BASE_LEGS_WALK);
                        mModel_.stopAnimation(CharacterModelAnimId.BASE_ARMS_WALK);
                    }
                }
            }
            if(mPerformingEquippable_){
                local result = mPerformingEquippable_.update(mPos_);
                if(!result) mPerformingEquippable_ = null;
            }
        }
        function performAttack(){
            if(mPerformingEquippable_) return;
            if(mCombatData_ == null) return;
            local equippedSword = mCombatData_.mEquippedItems.mItems[EquippedSlotTypes.SWORD];
            //TODO in future have some base attack.
            if(equippedSword == null) return;

            local equippable = ::Equippables[equippedSword.getEquippableData()];
            local performance = ::EquippablePerformance(equippable, mModel_);
            mPerformingEquippable_ = performance;
        }
    }

    mPlayerMoves = [
        MoveId.AREA,
        MoveId.FIREBALL,
        MoveId.AREA,
        MoveId.AREA
    ];

    mSceneLogic_ = null;

    mExplorationCount_ = 0;
    mExplorationPercentage_ = 0;

    EXPLORATION_MAX_LENGTH = 1000;
    EXPLORATION_MAX_FOUND_ITEMS = 4;
    EXPLORATION_MAX_QUEUED_ENCOUNTERS = 4;

    EXPLORATION_ITEM_LIFE = 400.0;
    EXPLORATION_ENEMY_LIFE = 800.0;

    NUM_PLAYER_QUEUED_FLAGS = 1;
    mQueuedFlags_ = null;
    mDeterminedFlag_ = null;

    mFoundObjects_ = null;
    mFoundObjectsLife_ = null;
    mNumFoundObjects_ = 0;

    mEnemyEncountered_ = false;
    mExplorationFinished_ = false;
    mExplorationPaused_ = false;

    mPrevTargetEnemy_ = null;
    mCurrentTargetEnemy_ = null;

    mCurrentMapData_ = null;
    mPlayerEntry_ = null;
    mActiveEnemies_ = null;
    mQueuedEnemyEncounters_ = null;
    mQueuedEnemyEncountersLife_ = null;
    mNumQueuedEnemies_ = 0;
    mPlacingMarker_ = false;
    mRecentTargetEnemy_ = false;

    mCurrentHighlightEnemy_ = null;
    mPreviousHighlightEnemy_ = null;

    mOrientatingCamera_ = false;
    mPrevMouseX_ = null;
    mPrevMouseY_ = null;

    mProjectileManager_ = null;
    mExplorationStats_ = null;
    mGatewayPercentage_ = 0.0;
    mActiveEXPOrbs_ = null;

    mInputs_ = null;

    mDebugForceItem_ = ItemId.NONE;

    mCurrentTimer_ = null;

    mGui_ = null;

    constructor(){
        mSceneLogic_ = ExplorationSceneLogic();
        mProjectileManager_ = ExplorationProjectileManager();

        mActiveEnemies_ = {};
        mQueuedFlags_ = array(NUM_PLAYER_QUEUED_FLAGS, null);
        mQueuedEnemyEncounters_ = [];
        mQueuedEnemyEncountersLife_ = [];
        mActiveEXPOrbs_ = {};

        resetExploration_();
        processDebug_();

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

    //Check for debug flags
    function processDebug_(){
        local forceItem = _settings.getUserSetting("forceFoundItem");
        if(forceItem){
            local result = ::ItemHelper.nameToItemId(forceItem);
            if(result == ItemId.NONE){
                assert(false); //If an item is requested and not found better to just error out.
            }
            mDebugForceItem_ = result;
        }
    }

    function shutdown(){
        foreach(i in mActiveEnemies_){
            i.notifyDestroyed();
        }
        mPlayerEntry_.notifyDestroyed();

        mActiveEnemies_.clear();
        mSceneLogic_.shutdown();

        _event.unsubscribe(Event.PLAYER_DIED, processPlayerDeath, this);

        _state.setPauseState(0);
    }

    function setup(){
        _state.setPauseState(0);

        //resetGenMap_();
        //mSceneLogic_.setup();
        resetExploration();

        _event.subscribe(Event.PLAYER_DIED, processPlayerDeath, this);
    }

    function processPlayerDeath(id, data){
        print("Received player death");
        pauseExploration();
        if(mGui_) mGui_.notifyPlayerDeath();
    }

    function resetExploration_(){
        mExplorationCount_ = 0;
        mExplorationPercentage_ = 0;

        mNumFoundObjects_ = 0;
        mFoundObjects_ = array(EXPLORATION_MAX_FOUND_ITEMS, null);
        mFoundObjectsLife_ = array(EXPLORATION_MAX_FOUND_ITEMS, 0);
        mQueuedEnemyEncountersLife_ = array(EXPLORATION_MAX_QUEUED_ENCOUNTERS, 0);
        mEnemyEncountered_ = false;
        mExplorationFinished_ = false;
        mExplorationPaused_ = false;

        mExplorationStats_ = {
            "explorationTimeTaken": 0,
            "totalDiscoveredPlaces": 0,
            "totalDefeated": 0,
            "foundEXPOrbs": 0,
        };

        renotifyItems();
        processExplorationBegan();
    }
    function resetGenMap_(){
        resetExplorationGenMap_();
        mSceneLogic_.resetExploration(mCurrentMapData_);
        mPlayerEntry_ = ::ExplorationEntityFactory.constructPlayer(mGui_);
        mPlayerEntry_.setPosition(Vec3(mCurrentMapData_.width / 2, 0, -mCurrentMapData_.height / 2));
        if(mGui_) mGui_.notifyNewMapData(mCurrentMapData_);
        //mSceneLogic_.updatePlayerPos(mPlayerEntry_.mPos_);
    }
    function resetExploration(){
        //TODO find a better way than the direct lookup.
        if(mGui_) mGui_.mWorldMapDisplay_.mBillboardManager_.untrackAllNodes();
        _state.setPauseState(0);

        resetExploration_();
        resetGenMap_();

        mCurrentTimer_ = Timer();
        mCurrentTimer_.start();
    }
    function resetExplorationGenMap_(){
        local gen = ::MapGen();
        local data = {
            "seed": _random.randInt(0, 1000),
            "variation": _random.randInt(0, 1000),
            "width": 200,
            "height": 200,
            "numRivers": 12,
            "seaLevel": 100,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        local outData = gen.generate(data);
        mCurrentMapData_ = outData;
    }

    function tickUpdate(){
        if(mExplorationCount_ >= EXPLORATION_MAX_LENGTH){
            processExplorationEnd();
            return;
        }
        if(mExplorationCount_ == EXPLORATION_MAX_LENGTH) return;
        if(mExplorationPaused_) return;
        if(mEnemyEncountered_) return;
        //updatePercentage();
        checkTargetEnemy();
        checkExploration();
        checkCameraChange();
        checkPlayerMove();
        checkOrientatingCamera();
        checkPlayerCombatMoves();
        checkHighlightEnemy();
        ageItems();

        mSceneLogic_.updatePercentage(mExplorationPercentage_);
        mProjectileManager_.update();

        mPlayerEntry_.update();
        foreach(i in mActiveEnemies_){
            i.update();
        }
    }

    function checkExploration(){
        checkForFoundObject();

        checkForEnemyAppear();
        local disableEncounters = _settings.getUserSetting("disableEncounters");
        if(!disableEncounters){
            //checkForEncounter();
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

    function checkHighlightEnemy(){
        if(mCurrentHighlightEnemy_ == mPreviousHighlightEnemy_) return;

        assert(mCurrentHighlightEnemy_ != mPreviousHighlightEnemy_);
        print("Highlight enemy change");

        local enemy = null;
        if(mCurrentHighlightEnemy_ != null){
            if(mActiveEnemies_.rawin(mCurrentHighlightEnemy_)){
                enemy = mActiveEnemies_[mCurrentHighlightEnemy_].mEnemy_;
            }
        }
        if(mGui_) mGui_.notifyHighlightEnemy(enemy);
    }

    //Unfortunately as the scene is safe when the target enemy is registered I have to check this later.
    function checkTargetEnemy(){
        if(!mRecentTargetEnemy_) return;
        if(!mCurrentTargetEnemy_) return;

        if(mActiveEnemies_.rawin(mPrevTargetEnemy_)){
            mActiveEnemies_[mPrevTargetEnemy_].setGizmo(null);
        }

        local e = mActiveEnemies_[mCurrentTargetEnemy_];
        local gizmo = mSceneLogic_.createGizmo(e.getPosition(), ExplorationGizmos.TARGET_ENEMY);
        e.setGizmo(gizmo);
    }
    function notifyEnemyDestroyed(eid){
        mActiveEnemies_[eid].notifyDestroyed();
        mActiveEnemies_.rawdelete(eid);
        if(eid == mCurrentTargetEnemy_) mCurrentTargetEnemy_ = null;

        mExplorationStats_.totalDefeated++;
    }

    function setOrientatingCamera(orientate){
        mOrientatingCamera_ = orientate;
    }
    function checkOrientatingCamera(){

        if(_input.getMouseButton(1)){
            //::Base.mExplorationLogic.spawnEXPOrbs(mPlayerEntry_.getPosition(), 4);

            gatewayEndExploration();
        }
        if(!mOrientatingCamera_) return;
        print("orientating");

        if(_input.getMouseButton(0)){
            local mouseX = _input.getMouseX();
            local mouseY = _input.getMouseY();
            if(mPrevMouseX_ != null && mPrevMouseY_ != null){
                local deltaX = mouseX - mPrevMouseX_;
                local deltaY = mouseY - mPrevMouseY_;
                printf("delta x: %f y: %f", deltaX, deltaY);
                mSceneLogic_.processCameraMove(deltaX*-0.2, deltaY*-0.2);
            }
            mPrevMouseX_ = mouseX;
            mPrevMouseY_ = mouseY;
        }else{
            //Wait for the first move to happen.
            if(mPrevMouseX_ != null && mPrevMouseY_ != null){
                mPrevMouseX_ = null;
                mPrevMouseY_ = null;
                mOrientatingCamera_ = false;
            }
        }
    }

    function checkCameraChange(){
        local modifier = 1;
        local x = _input.getAxisActionX(mInputs_.camera, _INPUT_ANY);
        local y = _input.getAxisActionY(mInputs_.camera, _INPUT_ANY);
        mSceneLogic_.processCameraMove(x*modifier, y*modifier);
    }

    function checkPlayerMove(){
        if(mEnemyEncountered_) return;
        if(mExplorationPaused_) return;

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
            local enemyPos = mActiveEnemies_[mCurrentTargetEnemy_].getPosition();
            local dir = (mPlayerEntry_.getPosition() - enemyPos);
            dir.normalise();
            targetPos = enemyPos + (Vec3(4, 0, 4) * dir);
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
                }
            }
        }else{
            mPlacingMarker_ = false;
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

                if(mCurrentTargetEnemy_) performPlayerAttack();
            }
        }

        //Check if the current enemy is in the list.
        if(mCurrentTargetEnemy_ != null){
            if(!::w.e.rawin(mCurrentTargetEnemy_)){
                //Assuming the enemy has been destroyed now.
                mCurrentTargetEnemy_ = null;
            }
        }
    }

    function getNearestPlaceData_(playerPos){
        local idx = 0;
        local smallestDist = 1000000.0;
        local activePlaces = mSceneLogic_.mActivePlaces_
        foreach(c,i in activePlaces){
            if(i.mEncountered_) continue;
            local distance = playerPos.distance(i.mPos_);
            if(distance < smallestDist){
                idx = c;
                smallestDist = distance;
            }
        }
        return activePlaces[idx];
    }
    function getSystemDeterminedFlag(){
        if(mDeterminedFlag_ == null){
            //Generate a new location.
            local place = getNearestPlaceData_(mPlayerEntry_.mPos_);
            mDeterminedFlag_ = place.mPos_;
        }
        return mDeterminedFlag_;
    }

    function movePlayerToPos(targetPos){
        local original = (targetPos - mPlayerEntry_.getPosition());
        local dir = original.normalisedCopy() * 0.2;
        local target = Vec2(dir.x, dir.z);

        movePlayer(target);

        local newPos = mPlayerEntry_.mPos_.copy();
        local newTarget = targetPos.copy();
        newPos.y = 0;
        newTarget.y = 0;
        local distance = newTarget.distance(newPos);
        return distance < 0.4;
    }

    function movePlayer(dir){
        mPlayerEntry_.moveQueryZ(Vec3(dir.x, 0, dir.y), mSceneLogic_);
        local playerPos = Vec3(mPlayerEntry_.mPos_.x, 0, mPlayerEntry_.mPos_.z);
        mSceneLogic_.updatePlayerPos(playerPos);
        _world.setPlayerPosition(SlotPosition(playerPos));
        //TODO remove direct access.
        mGui_.mWorldMapDisplay_.mMapViewer_.setPlayerPosition(playerPos.x, playerPos.z);
    }

    function ageItems(){
        for(local i = 0; i < mFoundObjects_.len(); i++){
            if(mFoundObjects_[i] == null || mFoundObjects_[i] == ItemId.NONE) continue;
            mFoundObjectsLife_[i]--;
            if(mGui_) mGui_.notifyFoundItemLifetime(i, mFoundObjectsLife_[i].tofloat() / EXPLORATION_ITEM_LIFE);
            if(mFoundObjectsLife_[i] <= 0){
                //Scrap the item.
                printf("Item at slot %i got too old", i);
                removeFoundItem(i);
            }
        }

        //Age the enemies.
        for(local i = 0; i < mQueuedEnemyEncounters_.len(); i++){
            if(mQueuedEnemyEncounters_[i] == null || mQueuedEnemyEncounters_[i] == Enemy.NONE) continue;
            mQueuedEnemyEncountersLife_[i]--;
            if(mGui_) mGui_.notifyQueuedEnemyLifetime(i, mQueuedEnemyEncountersLife_[i].tofloat() / EXPLORATION_ENEMY_LIFE);
            if(mQueuedEnemyEncountersLife_[i] <= 0){
                //Remove the enemy.
                printf("Item at slot %i got too old", i);
                removeQueuedEnemy(i);
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

    function updatePercentage(){
        //TODO in future this could be done with system milliseconds.
        if(mExplorationCount_ < EXPLORATION_MAX_LENGTH) mExplorationCount_++;

        local newPercentage = ((mExplorationCount_.tofloat() / EXPLORATION_MAX_LENGTH) * 100).tointeger();

        if(mExplorationPercentage_ != newPercentage){
            if(mGui_) mGui_.notifyExplorationPercentage(newPercentage);
        }
        mExplorationPercentage_ = newPercentage;
    }

    function wrapDataForFoundItem(item){
        local data = null;
        switch(item){
            case ItemId.LARGE_BAG_OF_COINS:{
                data = {"money": _random.randInt(50, 100)};
                break;
            }
            default:{
                break;
            }
        }
        return ::Item(item, data);
    }

    function checkForFoundObject(){
        if(mNumFoundObjects_ >= EXPLORATION_MAX_FOUND_ITEMS) return;

        local foundSomething = _random.randInt(50) == 0;
        if(foundSomething){
            //decide what was found.
            local item = ItemId.NONE;
            if(mDebugForceItem_){
                item = mDebugForceItem_;
            }else{
                item = _random.randInt(ItemId.NONE+1, ItemId.MAX-1);
            }
            local wrapped = wrapDataForFoundItem(item)
            processFoundItem(wrapped);
            return;
        }

        /*
        foundSomething = _random.randInt(500) == 0;
        if(foundSomething){
            local foundPlace = _random.randInt(PlaceId.NONE+1, PlaceId.MAX-1);
            processFoundPlace(foundPlace);
            return;
        }
        */
    }

    function checkForEnemyAppear(){
        local foundSomething = _random.randInt(100) == 0;
        if(!foundSomething) return;
        if(mActiveEnemies_.len() >= 20){
            print("can't add any more enemies");
            return;
        }
        appearEnemy(Enemy.GOBLIN);
    }

    function appearEnemy(enemyType){
        assert(mSceneLogic_ != null);
        local randVec = _random.randVec2();
        local targetPos = mPlayerEntry_.mPos_ + Vec3(5, 0, 5) + (Vec3(randVec.x, 0, randVec.y) * 20);
        local enemyEntry = ::ExplorationEntityFactory.constructEnemy(enemyType, targetPos, mGui_);
        mActiveEnemies_.rawset(enemyEntry.mEntity_.getId(), enemyEntry);
    }

    function checkForEncounter(){
        local foundSomething = _random.randInt(2000) == 0;
        if(foundSomething){
            //decide what was found.
            local enemy = _random.randInt(Enemy.NONE+1, Enemy.MAX-1);
            //processEncounter(enemy);
        }
    }

    function processFoundItem(item){
        //TODO could reduce duplication here.
        //Find the index of insertion.
        local idx = mFoundObjects_.find(null);
        //Should have found something and there should be space if this function is being called.
        assert(idx != null);

        local foundObj = ::FoundObject(item, FoundObjectType.ITEM);
        mFoundObjects_[idx] = foundObj;
        mFoundObjectsLife_[idx] = EXPLORATION_ITEM_LIFE;
        mNumFoundObjects_++;

        //local foundPosition = mSceneLogic_.getFoundPositionForItem(item);
        local foundPosition = mPlayerEntry_.mPos_;

        print(format("Found item %s at index %i", item.getName(), idx));

        if(mGui_) mGui_.notifyObjectFound(foundObj, idx, foundPosition);

        notifyGatewayStatsChange();
    }

    function processFoundPlace(place){
        //Find the index of insertion.
        local idx = mFoundObjects_.find(null);
        //Should have found something and there should be space if this function is being called.
        assert(idx != null);

        local foundObj = ::FoundObject(place, FoundObjectType.PLACE);
        mFoundObjects_[idx] = foundObj;
        mNumFoundObjects_++;

        print(format("Found place %s at index %i", ::Places[place].getName(), idx));

        if(mGui_) mGui_.notifyObjectFound(foundObj, idx);
    }

    function notifyGatewayStatsChange(){
        //TODO for now calculate this stat on the fly for now.
        local gatewayStat = mExplorationStats_.totalDiscoveredPlaces.tofloat() / 20;
        mGatewayPercentage_ = gatewayStat > 1.0 ? 1.0 : gatewayStat;
        if(mGui_) mGui_.notifyGatewayStatsChange(mGatewayPercentage_);
    }

    function removeFoundItem(idx){
        print(format("Removing item: %i", idx));
        mFoundObjects_[idx] = null;
        mNumFoundObjects_--;
        assert(mNumFoundObjects_ >= 0);
        if(mGui_) mGui_.notifyFoundItemRemoved(idx);
    }

    function scrapAllFoundObjects(){
        //TODO Make sure it actually gives you the money!
        for(local i = 0; i < ::ExplorationLogic.EXPLORATION_MAX_FOUND_ITEMS; i++){
            if(mFoundObjects_[i] == null) continue;
            removeFoundItem(i);
        }
    }

    function _setupDataForCombat(){
        local enemyData = [];
        foreach(i in mQueuedEnemyEncounters_){
            enemyData.append(i);
        }
        local currentCombatData = ::Combat.CombatData(::Base.mPlayerStats.mPlayerCombatStats, enemyData);
        ::Base.notifyEncounter(currentCombatData)
        return currentCombatData;
    }
    function triggerCombatEarly(){
        assert(mNumQueuedEnemies_ > 0);
        processEncounter();
    }

    function processEncounter(){
        //local foundPosition = mSceneLogic_.getFoundPositionForEncounter(enemy);
        local foundPosition = mPlayerEntry_.mPos_;

        local combatData = _setupDataForCombat();
        if(mGui_) mGui_.notifyEnemyCombatBegan(combatData, foundPosition);
        mEnemyEncountered_ = true;
    }

    function processExplorationBegan(){
        if(mGui_) mGui_.notifyExplorationBegan();
    }

    function processExplorationEnd(){
        if(mExplorationFinished_) return;
        mExplorationFinished_ = true;
        mExplorationPaused_ = false;

        if(mGui_) mGui_.notifyExplorationEnd();
    }

    function continueExploration(){
        mEnemyEncountered_ = false;
        mExplorationPaused_ = false;
        renotifyItems();
        _state.setPauseState(0);
    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }

    function renotifyItems(){
        if(!mGui_) return;
        foreach(i,c in mFoundObjects_){
            local target = c;
            if(!target){
                target = ::FoundObject();
            }
            mGui_.notifyObjectFound(target, i);
        }
    }

    function pauseExploration(){
        print("Pausing exploration");
        mExplorationPaused_ = true;
        _state.setPauseState(0xFFFF);
    }

    /*
    * Either continue or reset the exploration, depending on whether it's finished or not.
    */
    function continueOrResetExploration(){
        if(mExplorationPaused_){
            print("Unpausing exploration");
            continueExploration();
            return;
        }
        if(mExplorationFinished_){
            resetExploration();
            return;
        }
        continueExploration();
    }

    function notifyLeaveExplorationScreen(){
        if(mExplorationFinished_) return;
        mExplorationPaused_ = true;
        mGui_ = null;
    }

    function moveEnemyToPlayer(enemyId){
        if(mEnemyEncountered_) return;
        local enemyEntry = mActiveEnemies_[enemyId];
        if(enemyEntry == null) return;
        local dir = mPlayerEntry_.mPos_ - enemyEntry.mPos_;
        dir.normalise();
        dir *= 0.05;
        enemyEntry.move(dir);
    }

    function removeQueuedEnemy(idx){
        print(format("Removing queued enemy: %i", idx));
        mQueuedEnemyEncounters_[idx] = null;
        mNumQueuedEnemies_--;
        assert(mNumQueuedEnemies_ >= 0);
        if(mGui_) mGui_.notifyQueuedEnemyRemoved(idx);
    }
    function addEncounter_(encounter){
        local holeIdx = mQueuedEnemyEncounters_.find(null);
        if(holeIdx == null){
            holeIdx = mQueuedEnemyEncounters_.len();
            mQueuedEnemyEncounters_.append(encounter);
        }else{
            mQueuedEnemyEncounters_[holeIdx] = encounter;
        }
        return holeIdx;
    }
    function notifyEncounter(enemyIdx, enemyData){
        local listIdx = addEncounter_(enemyData);
        mNumQueuedEnemies_++;

        mActiveEnemies_[enemyIdx].destroy();
        mQueuedEnemyEncountersLife_[listIdx] = EXPLORATION_ENEMY_LIFE;

        local foundPosition = mPlayerEntry_.mPos_;
        if(mGui_) mGui_.notifyEnemyEncounter(listIdx, enemyData, foundPosition);

        if(mNumQueuedEnemies_ >= EXPLORATION_MAX_QUEUED_ENCOUNTERS){
            processEncounter();
        }
    }

    function isGatewayReady(){
        return mGatewayPercentage_ >= 1.0;
    }

    function notifyPlaceEnterState(id, entered){
        local placeEntry = mSceneLogic_.mActivePlaces_[id];
        local firstTime = !placeEntry.mEncountered_;
        if(firstTime && placeEntry.mEnemy_ != PlaceId.GATEWAY){
            //Add the flag to the place.
            local childNode = placeEntry.getSceneNode().createChildSceneNode();
            childNode.setPosition(0.5, 0, 0);
            childNode.setScale(1.5, 1.5, 1.5);
            local item = _scene.createItem("locationFlag.mesh");
            item.setRenderQueueGroup(30);
            childNode.attachObject(item);

            //Do a coin effect.
            local worldPos = ::EffectManager.getWorldPositionForWindowPos(mGui_.mWorldMapDisplay_.getPosition() + mGui_.mWorldMapDisplay_.getSize() / 2);
            local endPos = mGui_.getMoneyCounter().getPositionWindowPos();
            ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 5, "start": worldPos, "end": endPos, "money": 100}));

            mExplorationStats_.totalDiscoveredPlaces++;
            notifyGatewayStatsChange();
        }

        local entity = placeEntry.getEntity();
        checkPlaceBillboardVisible(entity, entered);

        placeEntry.mEncountered_ = true;

        //TODO will want to rename this from enemy at some point.
        if(mGui_) mGui_.notifyPlaceEnterState(placeEntry.mEnemy_, entered, firstTime, placeEntry.mPos_);
    }
    function checkPlaceBillboardVisible(entity, visible){
        local billboardIdx = -1;
        try{
            billboardIdx = _component.user[Component.MISC].get(entity, 0);
        }catch(e){ }
        if(billboardIdx == -1) return;

        mGui_.mWorldMapDisplay_.mBillboardManager_.setVisible(billboardIdx, visible);
    }

    function gatewayEndExploration(){
        pauseExploration();
        mCurrentTimer_.stop();
        mExplorationStats_.explorationTimeTaken = mCurrentTimer_.getSeconds();
        if(mGui_) mGui_.notifyGatewayEnd(mExplorationStats_);
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
        entityObject.performAttack();
    }

    function performPlayerMove(moveId){
        local playerPos = mPlayerEntry_.mPos_.copy();
        performMove(moveId, playerPos, null, _COLLISION_ENEMY);
    }

    function performMove(moveId, pos, dir, collisionType){
        local moveDef = ::Moves[moveId];
        local targetProjectile = moveDef.getProjectile();
        if(targetProjectile != null){
            mProjectileManager_.spawnProjectile(targetProjectile, pos, dir, collisionType);
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
    //-------

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
                            setCurrentTargetEnemy(enemy);
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

    function setCurrentTargetEnemy(currentEnemy){
        mPrevTargetEnemy_ = mCurrentTargetEnemy_;
        mCurrentTargetEnemy_ = currentEnemy;
        mRecentTargetEnemy_ = true;
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

        if(mCurrentTargetEnemy_ && mActiveEnemies_.rawin(entity.getId())){
            if(entity.getId() == mActiveEnemies_[mCurrentTargetEnemy_].getEntity().getId()){
                print("is the target entity");
            }
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

    function notifyFoundEXPOrb(){
        mExplorationStats_.foundEXPOrbs++;

        local worldPos = ::EffectManager.getWorldPositionForWindowPos(::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getPosition() + ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getSize() / 2);
        local endPos = ::Base.mExplorationLogic.mGui_.getEXPCounter().getPositionWindowPos();

        ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_EXP_ORB_EFFECT, {"numOrbs": 1, "start": worldPos, "end": endPos, "orbScale": 0.2}));
    }
};