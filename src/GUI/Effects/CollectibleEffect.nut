const COLLECTIBLE_EFFECT_ITEM_Z = 10;
const COLLECTIBLE_EFFECT_VIBRATION_AMOUNT = 0.05;
const COLLECTIBLE_EFFECT_ROTATION_AMOUNT = 0.1;


enum CollectibleEffectStages{
    NONE,
    MOVE_TO_CENTRE,
    VIBRATE_AND_ROTATE,
    BREAK,

    MAX
}
local CollectibleEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(CollectibleEffectStages.MAX);
};

{
    CollectibleEffectStateMachine.mStates_[CollectibleEffectStages.MOVE_TO_CENTRE] = class extends ::Util.State{
        mTotalCount_ = 15
        mNextState_ = CollectibleEffectStages.VIBRATE_AND_ROTATE;
        function start(data){
            //Start at the initial position
        }
        function update(p, data){
            //Interpolate position from start to centre, while scaling in
            local currentPos = data.startPos + (data.centre - data.startPos) * p;
            data.bottle.setPosition(currentPos.x, currentPos.y, COLLECTIBLE_EFFECT_ITEM_Z);

            //Scale in during movement
            local scaleNode = data.bottle.getChild(0);
            local newScale = p * data.scale;
            scaleNode.setScale(newScale, newScale, newScale);
        }
    };
    CollectibleEffectStateMachine.mStates_[CollectibleEffectStages.VIBRATE_AND_ROTATE] = class extends ::Util.State{
        mTotalCount_ = 50
        mNextState_ = CollectibleEffectStages.BREAK;
        function start(data){
            data.bottle.setPosition(data.centre.x, data.centre.y, COLLECTIBLE_EFFECT_ITEM_Z);
        }
        function update(p, data){
            //Apply vibration based on sine wave
            local vibrationX = sin(p * 3.14159 * 8) * COLLECTIBLE_EFFECT_VIBRATION_AMOUNT;
            local vibrationY = cos(p * 3.14159 * 8) * COLLECTIBLE_EFFECT_VIBRATION_AMOUNT;

            data.bottle.setPosition(data.centre.x + vibrationX, data.centre.y + vibrationY, COLLECTIBLE_EFFECT_ITEM_Z);

            //Apply rotation that increases with time
            local rotationAmount = p * COLLECTIBLE_EFFECT_ROTATION_AMOUNT;
            local quat = Quat(rotationAmount, Vec3(0.2, 0.5, 1));
            data.bottle.setOrientation(quat);
        }
    };
    CollectibleEffectStateMachine.mStates_[CollectibleEffectStages.BREAK] = class extends ::Util.State{
        mTotalCount_ = 10
        mNextState_ = CollectibleEffectStages.NONE;
        function start(data){
            //Remove the original bottle and prepare for break animation
            //In future, this will create two broken pieces and animate them
        }
        function update(p, data){
            //Scale down the bottle as it breaks
            local scaleNode = data.bottle.getChild(0);
            local newScale = (1.0 - p) * data.scale;
            scaleNode.setScale(newScale, newScale, newScale);
        }
    };
}

::EffectManager.Effects[Effect.COLLECTABLE_OPEN_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mItem_ = null;

    mCentre_ = Vec2(0, 0);
    mStartPos_ = Vec2(0, 0);
    mScale_ = 1.0;
    mMeshName_ = "collectables.messageInABottle.voxMesh";

    mStateMachine_ = null;

    function setup(data){
        mCentre_ = ::Vec2_ZERO;
        mStartPos_ = ::Vec2_ZERO;
        if("startPos" in data){
            mStartPos_ = data.startPos;
        }
        if("itemScale" in data){
            mScale_ = data.itemScale;
        }
        if("meshName" in data){
            mMeshName_ = data.meshName;
        }

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mItem_ = createVoxelItem(mParentNode_, mStartPos_, mScale_, mMeshName_);

        mStateMachine_ = CollectibleEffectStateMachine({"bottle": mItem_, "centre": mCentre_, "startPos": mStartPos_, "scale": mScale_});
        mStateMachine_.setState(CollectibleEffectStages.MOVE_TO_CENTRE);
    }

    function destroy(){
        mParentNode_.destroyNodeAndChildren();
    }

    function createVoxelItem(parentNode, centre, scale, meshName){
        local itemNode = parentNode.createChildSceneNode();
        local animNode = itemNode.createChildSceneNode();
        local voxItem = _gameCore.createVoxMeshItem(meshName);
        voxItem.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
        animNode.attachObject(voxItem);
        animNode.setScale(scale, scale, scale);

        return itemNode;
    }

    function update(){
        print("Updating Collectible Effect");
        return mStateMachine_.update();
    }
};
