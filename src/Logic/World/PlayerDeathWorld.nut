::PlayerDeathWorld <- class extends ::World{

    mMapData_ = null;
    mVoxMesh_ = null;

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);
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

    function resetSession(mapData){
        base.resetSession();

        //print(mPlayerEntry_.getPosition());
        //assert(false);

        createScene();
        updateCameraPosition();

        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLAYER_DEATH_SCREEN, null), null, 3);
    }

    function getPositionForAppearEnemy_(enemyType){
        return Vec3();
    }

    function createScene(){

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

};