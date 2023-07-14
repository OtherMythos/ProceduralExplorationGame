//TODO get rid of this.
::ExplorationCount <- 0;

::ProceduralDungeonWorld <- class extends ::World{

    mMapData_ = null;

    constructor(){
        base.constructor();
    }

    function getWorldType(){
        return WorldTypes.PROCEDURAL_DUNGEON_WORLD;
    }

    function setup(){
        base.setup();

        resetSessionGenMap();
    }

    function resetSessionGenMap(){
        local gen = ::DungeonGen();
        local data = {
            "width": 50,
            "height": 50,
        };
        local outData = gen.generate(data);

        resetSession(outData);
    }

    function resetSession(mapData){
        base.resetSession();

        mMapData_ = mapData;
    }

    function getPositionForAppearEnemy_(enemyType){
        return Vec3();
    }

    function updatePlayerPos(playerPos){
        base.updatePlayerPos(playerPos);

        updateCameraPosition();
    }

    function updateCameraPosition(){
        local zPos = getZForPos(mPosition_);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local xPos = cos(mRotation_.x)*mCurrentZoomLevel_;
        local yPos = sin(mRotation_.x)*mCurrentZoomLevel_;
        local rot = Vec3(xPos, 0, yPos);
        yPos = sin(mRotation_.y)*mCurrentZoomLevel_;
        rot += Vec3(0, yPos, 0);

        parentNode.setPosition(Vec3(mPosition_.x, zPos, mPosition_.z) + rot );
        camera.lookAt(mPosition_.x, zPos, mPosition_.z);
    }

    function processCameraMove(x, y){
        mRotation_ += Vec2(x, y) * -0.05;
        local first = PI * 0.5;
        local second = PI * 0.1;
        if(mRotation_.y > first) mRotation_.y = first;
        if(mRotation_.y < second) mRotation_.y = second;

        local mouseScroll = _input.getMouseWheelValue();
        if(mouseScroll != 0){
            mCurrentZoomLevel_ += mouseScroll;
            if(mCurrentZoomLevel_ < MIN_ZOOM) mCurrentZoomLevel_ = MIN_ZOOM;
        }

        updateCameraPosition();
    }

    function getZForPos(pos){
        return 0;
    }

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

    }

    function getMapData(){
        return mMapData_;
    }

};