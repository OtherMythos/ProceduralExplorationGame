
/**
 * Logic interface for exploration.
 *
 * The exploration screen uses this class to determine how the exploration is progressing.
 * This prevents the gui from having to implement any of the actual logic.
 * Manages worlds as part of a single exploration session.
 */
::ExplorationLogic <- class{

    mExplorationPaused_ = false;
    mExplorationActive_ = false;

    mExplorationStats_ = null;

    mCurrentTimer_ = null;
    mRunning_ = false;

    mCurrentWorld_ = null;

    mQueuedWorlds_ = null;
    mIdPool_ = null;

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

        mQueuedWorlds_ = [];
        mIdPool_ = IdPool();

        //resetExploration_();
    }

    function shutdown(){
        if(mCurrentWorld_ == null || !mExplorationActive_) return;
        mCurrentWorld_.shutdown();
        foreach(i in mQueuedWorlds_){
            i.shutdown();
        }

        _event.unsubscribe(Event.PLAYER_DIED, processPlayerDeath, this);

        _state.setPauseState(0);

        mExplorationActive_ = false;
        mCurrentWorld_ = null;
    }

    function setup(){
        if(mCurrentWorld_ != null || mExplorationActive_) return;
        mExplorationActive_ = true;

        _state.setPauseState(0);

        setCurrentWorld_(createWorldInstance(WorldTypes.PROCEDURAL_EXPLORATION_WORLD));
        //setCurrentWorld_(createWorldInstance(WorldTypes.PROCEDURAL_DUNGEON_WORLD));

        _event.subscribe(Event.PLAYER_DIED, processPlayerDeath, this);
    }

    function createWorldInstance(worldType){
        //TODO create the instance, give it an id.
        local id = mIdPool_.getId();
        local created = null;
        switch(worldType){
            case WorldTypes.PROCEDURAL_EXPLORATION_WORLD:
                created = ProceduralExplorationWorld(id, ProceduralExplorationWorldPreparer());
                break;
            case WorldTypes.PROCEDURAL_DUNGEON_WORLD:
                created = ProceduralDungeonWorld(id, ProceduralDungeonWorldPreparer());
                break;
            case WorldTypes.VISITED_LOCATION_WORLD:
                created = VisitedLocationWorld(id, "testVillage");
                break;
            default:
                assert(false);
        }
        return created;
    }

    /**
     * Set the provided world to be active, de-activating and queuing the previous.
    */
    function pushWorld(worldInstance){
        printf("Pushing world instance '%s'", worldInstance.getWorldTypeString());
        mCurrentWorld_.setCurrentWorld(false);
        mQueuedWorlds_.append(mCurrentWorld_);
        setCurrentWorld_(worldInstance);
    }
    function setCurrentWorld(worldInstance){
        setCurrentWorld_(worldInstance);
    }
    function setCurrentWorld_(worldInstance){
        if(mCurrentWorld_ != null) mCurrentWorld_.processWorldActiveChange_(false);
        mCurrentWorld_ = worldInstance;
        mCurrentWorld_.setGuiObject(mGui_);
        mCurrentWorld_.setCurrentWorld(true);

        mGui_.mWorldMapDisplay_.mBillboardManager_.setMaskVisible(0x1 << mCurrentWorld_.getWorldId());

        _event.transmit(Event.CURRENT_WORLD_CHANGE, mCurrentWorld_);

        if(mCurrentWorld_.preparationComplete()){
            //Register the world as active as its preparation is already done.
            notifyActiveChange();
        }
    }
    function notifyActiveChange(){
        mCurrentWorld_.processWorldActiveChange_(true);

        _event.transmit(Event.ACTIVE_WORLD_CHANGE, mCurrentWorld_);
    }

    function processPlayerDeath(id, data){
        print("Received player death");
        pauseExploration();
        if(mGui_) mGui_.notifyPlayerDeath();
    }

    function resetExploration_(){
        mExplorationPaused_ = false;

        mCurrentTimer_ = Timer();
        mCurrentTimer_.start();

        shutdown();
        setup();

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
    }

    function tickUpdate(){
        tickPreparation();

        if(mExplorationPaused_) return;

        //TODO reset the exploration.
        mCurrentWorld_.update();
    }

    function tickPreparation(){
        if(mCurrentWorld_.preparationComplete()) return;
        local result = mCurrentWorld_.processPreparation();
        if(result){
            //Let the world know it's active.
            notifyActiveChange();
        }
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


    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }

    function pauseExploration(){
        print("Pausing exploration");
        mExplorationPaused_ = true;
        _state.setPauseState(0xFFFF);
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
            //local worldPos = ::EffectManager.getWorldPositionForWindowPos(mGui_.mWorldMapDisplay_.getPosition() + mGui_.mWorldMapDisplay_.getSize() / 2);
            //local endPos = mGui_.getMoneyCounter().getPositionWindowPos();
            //::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 5, "start": worldPos, "end": endPos, "money": 100}));

            mExplorationStats_.totalDiscoveredPlaces++;
        }

        if(firstTime){
            _event.transmit(Event.PLACE_DISCOVERED, {
                "id": placeEntry.mEnemy_,
                "pos": placeEntry.getPosition()
            });
        }

        local entity = placeEntry.getEntity();
        checkPlaceBillboardVisible(entity, entered);

        placeEntry.mEncountered_ = true;
    }
    function checkPlaceBillboardVisible(entity, visible){
        local billboardIdx = -1;

        local comp = mCurrentWorld_.mEntityManager_.getComponent(entity, EntityComponents.BILLBOARD);
        if(comp != null){
            mGui_.mWorldMapDisplay_.mBillboardManager_.setVisible(comp.mBillboard, visible);
        }
    }

    function gatewayEndExploration(){
        pauseExploration();
        mCurrentTimer_.stop();
        mExplorationStats_.explorationTimeTaken = mCurrentTimer_.getSeconds();
        if(mGui_) mGui_.notifyGatewayEnd(mExplorationStats_);
    }

    function sceneSafeUpdate(){
        if(!mExplorationActive_) return;
        mCurrentWorld_.sceneSafeUpdate();
    }

    function setOrientatingCamera(orientating){
        mCurrentWorld_.setOrientatingCamera(orientating);
    }
};