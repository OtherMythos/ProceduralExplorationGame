
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
    mPauseCount_ = 0;

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

    function setExplorationActive_(active){
        mExplorationActive_ = active;
        ::CompositorManager.setGameplayActive(active);
    }

    function shutdown(){
        if(mCurrentWorld_ == null || !mExplorationActive_) return;
        mCurrentWorld_.shutdown();
        foreach(i in mQueuedWorlds_){
            i.shutdown();
        }

        _event.unsubscribe(Event.PLAYER_DIED, processPlayerDeath, this);
        _event.unsubscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
        _event.unsubscribe(Event.PLAYER_EQUIP_CHANGED, playerEquipChanged, this);
        _event.unsubscribe(Event.PLAYER_WIELD_ACTIVE_CHANGED, playerWieldActiveChanged, this);

        _state.setPauseState(0);

        setExplorationActive_(false);
        mCurrentWorld_ = null;
    }

    function setup(){
        if(mCurrentWorld_ != null || mExplorationActive_) return;
        setExplorationActive_(true);

        _state.setPauseState(0);

        local targetWorld = ::Base.determineForcedWorld();
        if(targetWorld == null){
            targetWorld = ::BaseHelperFunctions.getDefaultWorld();
        }
        local data = {};
        local targetMap = ::Base.determineForcedMap();
        if(targetMap != null){
            data.rawset("mapName", targetMap);
        }
        setCurrentWorld_(createWorldInstance(targetWorld, data));

        _event.subscribe(Event.PLAYER_DIED, processPlayerDeath, this);
        _event.subscribe(Event.PLAYER_HEALTH_CHANGED, playerHealthChanged, this);
        _event.subscribe(Event.PLAYER_EQUIP_CHANGED, playerEquipChanged, this);
        _event.subscribe(Event.PLAYER_WIELD_ACTIVE_CHANGED, playerWieldActiveChanged, this);
    }

    function playerHealthChanged(id, data){
        mCurrentWorld_.playerHealthChanged(data);
        foreach(i in mQueuedWorlds_){
            i.playerHealthChanged(data);
        }
    }
    function playerWieldActiveChanged(id, data){
        mCurrentWorld_.playerWieldChanged(data);
        foreach(i in mQueuedWorlds_){
            i.playerWieldChanged(data);
        }
    }
    function playerEquipChanged(id, data){
        mCurrentWorld_.playerEquipChanged(data);
        foreach(i in mQueuedWorlds_){
            i.playerEquipChanged(data);
        }
    }

    function createWorldInstance(worldType, data){
        local id = mIdPool_.getId();
        local created = null;
        switch(worldType){
            case WorldTypes.PROCEDURAL_EXPLORATION_WORLD:
                created = ProceduralExplorationWorld(id, ProceduralExplorationWorldPreparer());
                break;
            case WorldTypes.PROCEDURAL_DUNGEON_WORLD:
                created = ProceduralDungeonWorld(id, ProceduralDungeonWorldPreparer(data));
                break;
            case WorldTypes.VISITED_LOCATION_WORLD:{
                local defaultMap = ::BaseHelperFunctions.getDefaultMapName();
                if(data.rawin("mapName")){
                    defaultMap = data.mapName;
                }
                created = VisitedLocationWorld(id, VisitedLocationWorldPreparer(defaultMap));
                break;
            }
            case WorldTypes.TESTING_WORLD:
                created = TestingWorld(id, WorldPreparer());
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
    function popWorld(){
        //There must be at least one world.
        if(mQueuedWorlds_.len() <= 0) return false;
        destroyWorld_(mCurrentWorld_);
        local current = mQueuedWorlds_.top();
        mQueuedWorlds_.pop();
        setCurrentWorld_(current);
        return true;
    }
    function replaceWorld(worldInstance){
        destroyWorld_(mCurrentWorld_);
        setCurrentWorld_(worldInstance);
    }
    function setCurrentWorld(worldInstance){
        setCurrentWorld_(worldInstance);
    }
    function destroyWorld_(worldInstance){
        worldInstance.setCurrentWorld(false);
        worldInstance.shutdown();
        mIdPool_.recycleId(worldInstance.getWorldId());
        _event.transmit(Event.WORLD_DESTROYED, worldInstance);
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
        ::Base.mPlayerStats.processPlayerDeath();
        if(mGui_) mGui_.notifyPlayerDeath();
    }

    function resetExploration_(){
        mExplorationPaused_ = false;

        mCurrentTimer_ = Timer();
        mCurrentTimer_.start();

        shutdown();
        setup();

        //TODO this duplicates some logic stored in the player stats class.
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
        mPauseCount_++;
        if(mExplorationPaused_) return;

        print("Pausing exploration");
        mExplorationPaused_ = true;
        _state.setPauseState(0xFFFF);
    }

    function unPauseExploration(){
        mPauseCount_--;
        if(mPauseCount_ > 0){
            return;
        }

        //Make sure it doesn't become negative.
        mPauseCount_ = 0;
        if(!mExplorationPaused_) return;

        print("UnPausing exploration");
        mExplorationPaused_ = false;
        _state.setPauseState(0x0);
    }

    function beginDialog(path, targetBlock=0){
        ::Base.mDialogManager.beginExecuting(path, targetBlock);
        pauseExploration();
    }
    function notifyDialogEnded(){
        unPauseExploration();
    }

    function notifyPlaceEnterState(id, entered){
        local placeEntry = mCurrentWorld_.mActivePlaces_[id];
        local firstTime = !placeEntry.mEncountered_;
        if(firstTime && placeEntry.mEnemy_ != PlaceId.GATEWAY){
            //Add the flag to the place.
            local childNode = placeEntry.getSceneNode().createChildSceneNode();
            childNode.setPosition(0.5, 0, 0);
            childNode.setScale(1.5, 1.5, 1.5);
            local item = _gameCore.createVoxMeshItem("locationFlag.voxMesh");
            item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
            childNode.attachObject(item);

            //Do a coin effect.
            //local worldPos = ::EffectManager.getWorldPositionForWindowPos(mGui_.mWorldMapDisplay_.getPosition() + mGui_.mWorldMapDisplay_.getSize() / 2);
            //local endPos = mGui_.getMoneyCounter().getPositionWindowPos();
            //::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 5, "start": worldPos, "end": endPos, "money": 100}));

            mCurrentWorld_.spawnMoney(placeEntry.getPosition(), 5);

            mExplorationStats_.totalDiscoveredPlaces++;
        }

        if(firstTime){
            _event.transmit(Event.PLACE_DISCOVERED, {
                "id": placeEntry.mEnemy_,
                "pos": placeEntry.getPosition()
            });
        }

        local entity = placeEntry.getEntity();
        //checkPlaceBillboardVisible(entity, entered);

        if(entered){
            ::Base.mActionManager.registerAction(placeEntry.mEnemy_ != PlaceId.GATEWAY ? ActionSlotType.VISIT : ActionSlotType.END_EXPLORATION, 0, null, id);
        }else{
            ::Base.mActionManager.unsetAction(0, id);
        }

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

        local result = null;
        {
            //result = clone ::Base.mPlayerStats.mCurrentExplorationStats_.discoveredBiomes;
            //Annoyingly you can't just clone it because it makes a shallow clone.
            //TODO wrap this with a proper deep clone function.
            result = {};
            foreach(c,i in ::Base.mPlayerStats.mCurrentExplorationStats_.discoveredBiomes){
                local vv = {};
                foreach(cc,ii in i){
                    vv.rawset(cc, ii);
                }
                result.rawset(c, vv);
            }

            local totalBiomes = ::Base.mPlayerStats.mCurrentData_.discoveredBiomes;
            //Determine the numbers to pass
            foreach(c,i in result){
                if(!totalBiomes.rawin(c)) continue;
                i.foundAmount += totalBiomes.rawget(c).foundAmount;
            }
        }
        ::Base.mPlayerStats.commitForExplorationSuccess();

        mExplorationStats_.explorationTimeTaken = mCurrentTimer_.getSeconds();
        mExplorationStats_.rawset("discoveredBiomes", result);
        ::Base.mPlayerStats.processExplorationSuccess();
        if(mGui_) mGui_.notifyGatewayEnd(mExplorationStats_);
    }

    function sceneSafeUpdate(){
        if(!mExplorationActive_) return;
        mCurrentWorld_.sceneSafeUpdate();
    }

    function readLoreContentForItem(item){
        local targetPath = "res://build/assets/readables/" + item.getDefData();
        readLoreContentPath(targetPath);
    }

    function readReadable(readable){
        local targetPath = format("res://build/assets/readables/%s.nut", readable);
        readLoreContentPath(targetPath);
    }

    function readLoreContentPath(readablePath){
        if(!_system.exists(readablePath)) throw "Could not find lore content for path " + readablePath;
        _doFile(readablePath);

        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.READABLE_CONTENT_SCREEN, {"content": readable}), null, 3);
        getroottable().rawdelete("readable");

        pauseExploration();
    }

    function toggleWieldActive(){
        ::Base.mExplorationLogic.toggleWieldActive();
    }

    function setGamePaused(pause){
        if(pause){
            pauseExploration();
            ::ScreenManager.transitionToScreen(Screen.PAUSE_SCREEN, null, 2);
            mCurrentWorld_.notifyModalPopupScreen();
        }else{
            unPauseExploration();
            ::ScreenManager.transitionToScreen(Screen.PAUSE_SCREEN, null, 2);
        }
    }
};