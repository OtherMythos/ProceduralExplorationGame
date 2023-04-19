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
        mPhysicsInner_ = null;
        mPhysicsOuter_ = null;
        mNode_ = null;
        mId_ = null;
        mEncountered_ = false;
        constructor(enemyType, enemyPos){
            mEnemy_ = enemyType;
            mPos_ = enemyPos;
        }
        function setCollisionShapes(inner, outer){
            mPhysicsInner_ = inner;
            mPhysicsOuter_ = outer;
        }
        function setEnemyNode(node){
            mNode_ = node;
        }
        function setPosition(pos){
            mPos_ = pos;
            if(mNode_) mNode_.setPosition(pos);
            if(mPhysicsInner_) mPhysicsInner_.setPosition(pos);
            if(mPhysicsOuter_) mPhysicsOuter_.setPosition(pos);
        }
        function getPosition(){
            return mPos_;
        }
        function move(amount){
            setPosition(mPos_ + amount);
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
        function destroy(){
            //TODO work around, for some reason destroying the collision object as part of the callback crashes the engine.
            //if(mNode_) mNode_.destroyNodeAndChildren();
            if(mNode_){
                mNode_.destroyNodeAndChildren();
                mNode_ = null;
            }
            setPosition(Vec3(-100, 0, -100));
            //The physics objects should just destroy themselves.
            //if(mPhysicsInner_) _physics.collision[TRIGGER].removeObject(mPhysicsInner_);
            //if(mPhysicsOuter_) _physics.collision[TRIGGER].removeObject(mPhysicsOuter_);
        }
    }

    mSceneLogic_ = null;

    mExplorationCount_ = 0;
    mExplorationPercentage_ = 0;

    EXPLORATION_MAX_LENGTH = 1000;
    EXPLORATION_MAX_FOUND_ITEMS = 4;
    EXPLORATION_MAX_QUEUED_ENCOUNTERS = 4;

    EXPLORATION_ITEM_LIFE = 400.0;
    EXPLORATION_ENEMY_LIFE = 800.0;

    NUM_PLAYER_QUEUED_FLAGS = 4;
    mQueuedFlags_ = null;
    mDeterminedFlag_ = null;

    mFoundObjects_ = null;
    mFoundObjectsLife_ = null;
    mNumFoundObjects_ = 0;

    mEnemyEncountered_ = false;
    mExplorationFinished_ = false;
    mExplorationPaused_ = false;

    mCurrentMapData_ = null;
    mPlayerEntry_ = null;
    mActiveEnemies_ = null;
    mQueuedEnemyEncounters_ = null;
    mQueuedEnemyEncountersLife_ = null;
    mNumQueuedEnemies_ = 0;

    mExplorationStats_ = null;
    mGatewayPercentage_ = 0.0;

    mMoveInputHandle_ = null;

    mDebugForceItem_ = ItemId.NONE;

    mGui_ = null;

    constructor(){
        mSceneLogic_ = ExplorationSceneLogic();

        mActiveEnemies_ = [];
        mQueuedFlags_ = array(NUM_PLAYER_QUEUED_FLAGS, null);
        mQueuedEnemyEncounters_ = [];
        mQueuedEnemyEncountersLife_ = [];

        mExplorationStats_ = {
            "totalFoundItems": 0,
            "totalDiscoveredPlaces": 0,
        };

        resetExploration_();
        processDebug_();

        mMoveInputHandle_ = _input.getAxisActionHandle("LeftMove");
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
        mSceneLogic_.shutdown();
    }

    function setup(){
        resetGenMap_();
        //mSceneLogic_.setup();
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

        renotifyItems();
        processExplorationBegan();
    }
    function resetGenMap_(){
        resetExplorationGenMap_();
        mSceneLogic_.resetExploration(mCurrentMapData_);
        mPlayerEntry_ = mSceneLogic_.constructPlayer();
        mPlayerEntry_.setPosition(Vec3(mCurrentMapData_.width / 2, 0, -mCurrentMapData_.height / 2));
        if(mGui_) mGui_.notifyNewMapData(mCurrentMapData_);
        //mSceneLogic_.updatePlayerPos(mPlayerEntry_.mPos_);
    }
    function resetExploration(){
        resetExploration_();
        resetGenMap_();
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
        checkExploration();
        checkPlayerMove();
        ageItems();

        mSceneLogic_.updatePercentage(mExplorationPercentage_);
    }

    function checkExploration(){
        checkForFoundObject();

        checkForEnemyAppear();
        local disableEncounters = _settings.getUserSetting("disableEncounters");
        if(!disableEncounters){
            //checkForEncounter();
        }
    }

    function checkPlayerMove(){
        if(mEnemyEncountered_) return;

        //TODO ewww clean this up.
        local moved = false;
        local xVal = _input.getAxisActionX(mMoveInputHandle_, _INPUT_ANY);
        local yVal = _input.getAxisActionY(mMoveInputHandle_, _INPUT_ANY);

        local dir = Vec2(xVal, yVal);
        moved = (xVal != 0 || yVal != 0);
        if(moved){
            dir /= 4;
        }

        if(_input.getMouseButton(0)){
            /*
            moved = true;
            local width = _window.getWidth();
            local height = _window.getHeight();

            local posX = _input.getMouseX().tofloat() / width;
            local posY = _input.getMouseY().tofloat() / height;

            dir = (Vec2(posX, posY) - Vec2(0.5, 0.5));
            dir.normalise();
            dir /= 4;
            */
            if(mGui_){
                local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
                if(inWindow != null){
                    queuePlayerFlagForWindowTouch(inWindow);
                }
            }
        }
        if(moved){
            movePlayer(dir);
            return;
        }

        /*
        foreach(c,i in mQueuedFlags_){
            print("Flag " + c + " : " + i);
        }
        */

        //Try and walk to the queued position.
        local targetIdx = -1;
        local targetPos = null;
        for(local i = 0; i < NUM_PLAYER_QUEUED_FLAGS; i++){
            if(mQueuedFlags_[i] != null){
                targetPos = mQueuedFlags_[i][0];
                targetIdx = i;
            }
        }
        if(targetPos == null){
            //If no queued flags were found use the system intended location.
            targetPos = getSystemDeterminedFlag();
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
            }
        }
    }

    function getSystemDeterminedFlag(){
        if(mDeterminedFlag_ == null){
            //Generate a new location.
            local placeData = mCurrentMapData_.placeData;
            local place = placeData[_random.randIndex(placeData)];
            mDeterminedFlag_ = Vec3(place.originX, 0, -place.originY);
        }
        return mDeterminedFlag_;
    }

    function movePlayerToPos(targetPos){
        local original = (targetPos - mPlayerEntry_.getPosition());
        //local dir = original.normalisedCopy();
        //dir /= 4;
        local dir = Vec2();
        if(original.x > 0) dir.x = 0.1;
        if(original.x < 0) dir.x = -0.1;
        if(original.z > 0) dir.y = 0.1;
        if(original.z < 0) dir.y = -0.1;

        print(original);
        movePlayer(dir);

        local checkMargin = 0.2;
        if(original.x < checkMargin && original.z < checkMargin
            &&
            original.x >= -checkMargin && original.z >= -checkMargin
            ){
            return true;
        }
        return false;
    }

    function movePlayer(dir){
        mPlayerEntry_.moveQueryZ(Vec3(dir.x, 0, dir.y), mSceneLogic_);
        local playerPos = Vec3(mPlayerEntry_.mPos_.x, 0, mPlayerEntry_.mPos_.z);
        mSceneLogic_.updatePlayerPos(playerPos);
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

    function queuePlayerFlagForWindowTouch(touchCoords){
        local inWindow = mGui_.checkPlayerInputPosition(_input.getMouseX(), _input.getMouseY());
        if(inWindow != null){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
            assert(camera != null);
            local mTestPlane_ = Plane(Vec3(0, 1, 0), Vec3(0, 0, 0));
            local ray = camera.getCameraToViewportRay(touchCoords.x, touchCoords.y);
            local point = ray.intersects(mTestPlane_);
            assert(point != false);
            local worldPoint = ray.getPoint(point);
            print("World point " + worldPoint);

            queuePlayerFlag(worldPoint);
        }
    }
    function queuePlayerFlag(worldPos){
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
        local randVec = _random.randVec2();
        local targetPos = mPlayerEntry_.mPos_ + Vec3(5, 0, 5) + (Vec3(randVec.x, 0, randVec.y) * 20);
        local entry = ActiveEnemyEntry(enemyType, Vec3(targetPos.x, 0, targetPos.z));
        registerEnemyEntry(entry);
        if(mSceneLogic_) mSceneLogic_.appearEnemy(entry);
    }

    function registerEnemyEntry(entry){
        local idx = mActiveEnemies_.find(null);
        if(idx == null){
            entry.setId(mActiveEnemies_.len());
            mActiveEnemies_.append(entry);
            return;
        }
        entry.setId(idx);
        mActiveEnemies_[idx] = entry;
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

        mExplorationStats_.totalFoundItems++;
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
        if(!placeEntry.mEncountered_ && placeEntry.mEnemy_ != PlaceId.GATEWAY){
            //Add the flag to the place.
            local childNode = placeEntry.mNode_.createChildSceneNode();
            childNode.setPosition(0.5, 0, 0);
            childNode.setScale(1.5, 1.5, 1.5);
            local item = _scene.createItem("locationFlag.mesh");
            item.setRenderQueueGroup(30);
            childNode.attachObject(item);

            //Do a coin effect.
            local worldPos = ::EffectManager.getWorldPositionForWindowPos(mGui_.mWorldMapDisplay_.getPosition() + mGui_.mWorldMapDisplay_.getSize() / 2);
            local endPos = mGui_.mMoneyCounter_.getPosition();
            ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 5, "start": worldPos, "end": endPos, "money": 100}));

            mExplorationStats_.totalDiscoveredPlaces++;
            notifyGatewayStatsChange();
        }
        placeEntry.mEncountered_ = true;

        //TODO will want to rename this from enemy at some point.
        if(mGui_) mGui_.notifyPlaceEnterState(placeEntry.mEnemy_, entered);
    }
};