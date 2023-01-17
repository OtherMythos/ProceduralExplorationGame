::w <- {
    //Store entity machines to perform logic.
    e = {}
}

::World <- class{

    mParentNode_ = null;
    mPlayerEntity_ = null;
    mEnemyObjects_ = null;
    mTargetCamera_ = null;

    mMapName_ = null;

    constructor(mapName){
        mMapName_ = mapName;
        mEnemyObjects_ = [];

        //TODO might want to move this somewhere else.
        _doFile("res://src/World/Entities/StateMachine.nut");
    }

    function setup(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mTargetCamera_ = ::CompositorManager.getCameraForSceneType(CompositorSceneType.WORLD_SCENE);
        assert(mTargetCamera_ != null);
        setCameraPosition(SlotPosition());

        local item = _scene.createItem("testTown.mesh");
        item.setRenderQueueGroup(50);
        mParentNode_.attachObject(item);
        mParentNode_.setScale(2, 1, 2);

        _slotManager.setCurrentMap(mMapName_);
        _world.createWorld();
        _developer.setRenderQueueForMeshGroup(50);
        mPlayerEntity_ = ::EntityFactory.createPlayer(SlotPosition());

        populateEnemies();
    }

    function shutdown(){
        _entity.destroy(mPlayerEntity_);
        foreach(i in mEnemyObjects_){
            _entity.destroy(i);
        }

        _world.destroyWorld();
        mParentNode_.destroyNodeAndChildren();
    }

    function update(){
        if(_input.getMouseButton(0)){
            local width = _window.getWidth();
            local height = _window.getHeight();

            local posX = _input.getMouseX().tofloat() / width;
            local posY = _input.getMouseY().tofloat() / height;

            local dir = (Vec2(posX, posY) - Vec2(0.5, 0.5));
            dir.normalise();

            movePlayer(dir);
        }
    }

    function populateEnemies(){
        for(local i = 0; i < 3; i++){
            local targetPos = SlotPosition() + (Vec3(100, 0, 100) * _random.randVec3());
            local entity = ::EntityFactory.createGoblinEnemy(targetPos);

            mEnemyObjects_.append(entity);
        }
    }

    function movePlayer(dir){
        local playerPos = _world.getPlayerPosition();
        playerPos.move(dir.x, 0, dir.y);
        mPlayerEntity_.setPosition(playerPos);
        _world.setPlayerPosition(playerPos);

        setCameraPosition(mPlayerEntity_.getPosition());
    }

    function setCameraPosition(pos){
        local parentNode = mTargetCamera_.getParentNode();
        local target = pos + Vec3(0, 80, 120);
        parentNode.setPosition(target);
        mTargetCamera_.lookAt(pos);
    }

};