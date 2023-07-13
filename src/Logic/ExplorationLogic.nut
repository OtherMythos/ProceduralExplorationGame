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

    mPlayerMoves = [
        MoveId.AREA,
        MoveId.FIREBALL,
        MoveId.AREA,
        MoveId.AREA
    ];

    mEnemyEncountered_ = false;
    mExplorationFinished_ = false;
    mExplorationPaused_ = false;

    mTargetManager_ = null;

    mPlayerEntry_ = null;
    mPlacingMarker_ = false;

    mOrientatingCamera_ = false;
    mPrevMouseX_ = null;
    mPrevMouseY_ = null;

    mProjectileManager_ = null;
    mExplorationStats_ = null;
    mGatewayPercentage_ = 0.0;

    mCurrentTimer_ = null;

    mCurrentWorld_ = null;

    mGui_ = null;
    mInputs_ = null;

    constructor(){

        //TODO remove duplication.
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

        mProjectileManager_ = ExplorationProjectileManager();

        //mCurrentWorld_ = ProceduralExplorationWorld();
        mCurrentWorld_ = ProceduralDungeonWorld();

        mTargetManager_ = EntityTargetManager();

        resetExploration_();
    }

    function shutdown(){
        mCurrentWorld_.shutdown();

        _event.unsubscribe(Event.PLAYER_DIED, processPlayerDeath, this);

        _state.setPauseState(0);
    }

    function setup(){
        _state.setPauseState(0);

        mCurrentWorld_.setup();

        resetExploration();

        _event.subscribe(Event.PLAYER_DIED, processPlayerDeath, this);
        _event.transmit(Event.ACTIVE_WORLD_CHANGE, mCurrentWorld_);
    }

    function processPlayerDeath(id, data){
        print("Received player death");
        pauseExploration();
        if(mGui_) mGui_.notifyPlayerDeath();
    }

    function resetExploration_(){
        mEnemyEncountered_ = false;
        mExplorationFinished_ = false;
        mExplorationPaused_ = false;

        mExplorationStats_ = {
            "explorationTimeTaken": 0,
            "totalDiscoveredPlaces": 0,
            "totalDefeated": 0,
            "foundEXPOrbs": 0,
        };
    }
    function resetExploration(){
        //TODO find a better way than the direct lookup.
        if(mGui_) mGui_.mWorldMapDisplay_.mBillboardManager_.untrackAllNodes();
        _state.setPauseState(0);

        resetExploration_();

        mCurrentTimer_ = Timer();
        mCurrentTimer_.start();
    }

    function tickUpdate(){
        if(mExplorationPaused_) return;
        if(mEnemyEncountered_) return;

        mCurrentWorld_.update();

        checkCameraChange();
        checkOrientatingCamera();

        mProjectileManager_.update();
    }

    function notifyEnemyDestroyed(eid){
        mCurrentWorld_.notifyEnemyDestroyed(eid);

        mExplorationStats_.totalDefeated++;
    }

    function notifyFoundEXPOrb(){
        mExplorationStats_.foundEXPOrbs++;

        local worldPos = ::EffectManager.getWorldPositionForWindowPos(::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getPosition() + ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.getSize() / 2);
        local endPos = ::Base.mExplorationLogic.mGui_.getEXPCounter().getPositionWindowPos();

        ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.LINEAR_EXP_ORB_EFFECT, {"numOrbs": 1, "start": worldPos, "end": endPos, "orbScale": 0.2}));
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
                mCurrentWorld_.processCameraMove(deltaX*-0.2, deltaY*-0.2);
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
        mCurrentWorld_.processCameraMove(x*modifier, y*modifier);
    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
        mCurrentWorld_.setGuiObject(guiObj);
    }

    function pauseExploration(){
        print("Pausing exploration");
        mExplorationPaused_ = true;
        _state.setPauseState(0xFFFF);
    }

    function isGatewayReady(){
        return mGatewayPercentage_ >= 1.0;
    }

    function notifyPlaceEnterState(id, entered){
        local placeEntry = mCurrentWorld_.mActivePlaces_[id];
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
            //notifyGatewayStatsChange();
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
};