::ExplorationSceneLogic <- class{

    mPrevPercentage_ = 0;
    mParentNode_ = null;
    mLandPieces_ = null;

    mLandGenCounter_ = 0;

    LandEntry = class{
        constructor(x, y, parentNode){
            print("Creating exploration land at " + x + "  " + y);
            local scale = Vec3(0.5, 0.5, 0.5);
            local objSize = Vec3(32, 0, 32) * scale;

            local item = _scene.createItem("grasslands1.mesh");
            item.setRenderQueueGroup(30);
            parentNode.attachObject(item);
            parentNode.setScale(scale);
            parentNode.setPosition(objSize.x * x, 0, objSize.z * y);
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
        mParentNode_.destroyNodeAndChildren();
        mParentNode_ = null;
    }

    function updatePercentage(percentage){
        if(mPrevPercentage_ != percentage){
            mPrevPercentage_ = percentage;

            if(percentage % 10 == 0 || percentage == 0){
                createLandPiece(mParentNode_);
            }
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

        local landNode = _scene.getRootSceneNode().createChildSceneNode();

        local piece = LandEntry(landPiece[0], landPiece[1], landNode);
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