::PlayerDeathWorld <- class extends ::World{

    mMapData_ = null;
    mVoxMesh_ = null;

    mLostMoney_ = 0;
    mLostEXP_ = 0;
    mLostItems_ = null;

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);

        mLostMoney_ = 50;
        mLostEXP_ = 50;
        mLostItems_ = [
            ::Item(ItemId.SIMPLE_SWORD)
        ];
    }

    #Override
    function getWorldType(){
        return WorldTypes.PLAYER_DEATH;
    }
    #Override
    function getWorldTypeString(){
        return "Player Death";
    }

    #Override
    function notifyPreparationComplete_(){
        mReady_ = true;
        base.setup();
        resetSession(null);
    }

    #Override
    function getDefaultSkyColour(){
        return Vec3(0.2, 0.2, 0.2);
    }

    #Override
    function processWorldActiveChange_(active){
        if(active){
            resetAtmosphereToDefaults();
        }
    }

    function constructPlayerEntry_(){
        return mEntityFactory_.constructPlayer(mGui_, ::Base.mPlayerStats, true);
    }

    function resetSession(mapData){
        base.resetSession();

        //Remove the health bar from the player.
        {
            local component = mEntityManager_.getComponent(mPlayerEntry_.getEID(), EntityComponents.BILLBOARD);
            //TODO this is duplicated from the entity manager, and also is horrible.
            ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(component.mBillboard);
            mEntityManager_.removeComponent(mPlayerEntry_.getEID(), EntityComponents.BILLBOARD);
        }

        //print(mPlayerEntry_.getPosition());
        //assert(false);

        createScene();
        updateCameraPosition();

        ::CompositorManager.setGameplayEffectsActive(false);

        setBackgroundColour(Vec3(0.2, 0.2, 0.2));
        _state.setPauseState(0x0);

        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLAYER_DEATH_SCREEN, null), null, 3);
    }

    function getPositionForAppearEnemy_(enemyType){
        return Vec3();
    }

    function createScene(){
    }

    function update(){
        updateWorldActions();

        local worldAction = getActionForSpawn_();
        if(worldAction != null){
            pushWorldAction(worldAction);
        }
    }

    function determineObjectType_(){
        local count = mLostMoney_ + mLostEXP_ + mLostItems_.len();
        if(count == 0) return null;
        local idx = _random.randInt(0, count);

        local objectType = 0;
        if(idx < mLostMoney_){
            mLostMoney_--;
            objectType = 0;
        }
        else if(idx >= mLostMoney_ && idx <= mLostMoney_ + mLostEXP_){
            mLostEXP_--;
            objectType = 1;
        }
        else{
            objectType = 2;
        }

        return objectType;
    }

    function getActionForSpawn_(){
        local spread = 4 + _random.rand() * 4;
        local randDir = (_random.rand()*2-1) * PI;
        local targetPos = (Vec3(sin(randDir) * spread, 0, cos(randDir) * spread));

        local worldItem = null;
        local objectType = determineObjectType_();
        if(objectType == null) return null;

        if(objectType == 0){
            worldItem = mEntityFactory_.constructMoneyObject(targetPos);
        }else if(objectType == 1){
            worldItem = mEntityFactory_.constructEXPOrb(targetPos);
        }else if(objectType == 2){
            local item = mLostItems_.top();
            mLostItems_.pop();
            worldItem = mEntityFactory_.constructCollectableItemObject(targetPos, item);
        }else{
            assert(false);
        }

        if(mEntityManager_.hasComponent(worldItem, EntityComponents.LIFETIME)){
            mEntityManager_.removeComponent(worldItem, EntityComponents.LIFETIME);
        }

        local action = ::ObjectDropAction(worldItem, this, ::Vec3_ZERO, targetPos);

        return action;
    }

    function updateCameraPosition(){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)

        local parentNode = camera.getParentNode();
        parentNode.setPosition(0, 20, 30);
        camera.lookAt(0, 0, 0);

        _gameCore.update(mPlayerEntry_.getPosition());
    }

    #Override
    function getZForPos(pos){
        return 1;
    }

    #Override
    function processWorldCurrentChange_(current){
        if(mParentNode_ != null) mParentNode_.setVisible(current);
    }

    function processCameraMove(x, y){

        //updateCameraPosition();
    }

    #Override
    function getMapData(){
        return mMapData_;
    }

    #Override
    function canPauseGame(){
        return false;
    }

};