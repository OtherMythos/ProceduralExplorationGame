::ExplorationSceneLogic <- class{

    mPrevPercentage_ = 0;
    mParentNode_ = null;
    mLandPieces_ = null;

    mLandGenCounter_ = 0;

    LandEntry = class{
        static scale = 0.5;
        static objSize = 32 * 0.5;

        mDatablock_ = null;
        mId_ = 0;
        mNode_ = null;

        constructor(id, x, y, parentNode){
            print("Creating exploration land at " + x + "  " + y);
            mId_ = id;
            local scale = Vec3(0.5, 0.5, 0.5);
            local objSize = Vec3(32, 0, 32) * scale;

            mNode_ = parentNode.createChildSceneNode();

            local item = _scene.createItem("grasslands1.mesh");
            item.setRenderQueueGroup(30);
            mNode_.attachObject(item);
            mNode_.setScale(scale);
            mNode_.setPosition(objSize.x * x, 0, objSize.z * y);

            //Create custom datablock for animation.
            local originalDatablock = _hlms.getDatablock("baseVoxelMaterial");
            mDatablock_ = originalDatablock.cloneBlock("materialExplorationLand" + id);
            mDatablock_.setTransparency(0.0);
            item.setDatablock(mDatablock_)

            //Apply some rotation to give variation.
            local randVal = _random.randInt(0, 3);
            local orientation = Quat((PI*2) / 4 * randVal, Vec3(0, 1, 0));
            mNode_.setOrientation(orientation);

            placeTrees(mNode_, 4);
        }

        function shutdown(){
            print("shutting down with id " + mId_)
            _hlms.destroyDatablock(mDatablock_);
            mDatablock_ = null;
        }

        function placeTrees(parentNode, num){
            for(local i = 0; i < num; i++){
                local node = parentNode.createChildSceneNode();
                local posVal = _random.randVec3();
                local actualPos = posVal * objSize - objSize / 2;
                actualPos.y = 3;
                node.setPosition(actualPos);
                node.setScale(2, 2, 2);
                local item = _scene.createItem("tree.mesh");
                item.setRenderQueueGroup(30);
                node.attachObject(item);
                item.setDatablock(mDatablock_);
            }
        }

        function update(progress){
            print(progress);
            mDatablock_.setTransparency(progress);
        }
    };

    constructor(){
        mLandPieces_ = [];
    }

    function setup(){
        print("Creating exploration scene");
        createScene();
    }

    function shutdown(){
        if(mParentNode_) mParentNode_.destroyNodeAndChildren();

        foreach(i in mLandPieces_){
            i.shutdown();
        }
        mLandPieces_.clear();

        mLandGenCounter_ = 0;
        mParentNode_ = null;
    }

    function resetExploration(){
        print("Resetting exploration scene");
        shutdown();
        setup();
    }

    function updatePercentage(percentage){
        if(percentage == 100) return;

        local currentUpdateCount = 0;
        if(mPrevPercentage_ != percentage){
            mPrevPercentage_ = percentage;

            local counter = percentage - (percentage / 10) * 10
            currentUpdateCount = counter.tofloat() / 10.0;
            if(percentage % 10 == 0 || percentage == 0){
                createLandPiece(mParentNode_);
            }

            mLandPieces_.top().update(currentUpdateCount);
        }
    }

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        {
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
            assert(camera != null);
            local parentNode = camera.getParentNode();
            parentNode.setPosition(0, 20, 30);
            camera.lookAt(0, 0, 0);
        }

        createLandPiece(mParentNode_);
    }

    function createLandPiece(parentNode){
        local landPiece = getFreeLandPiece();

        local piece = LandEntry(mLandGenCounter_, landPiece[0], landPiece[1], parentNode);
        mLandPieces_.append(piece);
    }

    function getFreeLandPiece(){
        //TODO in future make this smarter.

        local valsX = [
            0, 1, 0, -1, -1, 1, 0, 1, -1, 0, 1
        ];
        local valsY = [
            0, -1, -1, -1, 0, 0, 1, 1, 1, -2, -2
        ];

        //TODO this should not be needed later on.
        if(mLandGenCounter_ >= valsX.len()){
            return [0, 0];
        }

        local vals = [valsX[mLandGenCounter_], valsY[mLandGenCounter_]];
        mLandGenCounter_++;
        return vals;
    }
};