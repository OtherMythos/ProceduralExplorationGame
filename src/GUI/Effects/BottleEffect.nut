const BOTTLE_EFFECT_BOTTLE_Z = 10;
const BOTTLE_EFFECT_VIBRATION_AMOUNT = 0.05;
const BOTTLE_EFFECT_ROTATION_AMOUNT = 0.1;


enum BottleEffectStages{
    NONE,
    MOVE_TO_CENTRE,
    VIBRATE_AND_ROTATE,
    BREAK,

    MAX
}
local BottleEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(BottleEffectStages.MAX);
};

{
    BottleEffectStateMachine.mStates_[BottleEffectStages.MOVE_TO_CENTRE] = class extends ::Util.State{
        mTotalCount_ = 15
        mNextState_ = BottleEffectStages.VIBRATE_AND_ROTATE;
        function start(data){
            //Start at the initial position
        }
        function update(p, data){
            //Interpolate position from start to centre, while scaling in
            local currentPos = data.startPos + (data.centre - data.startPos) * p;
            data.bottle.setPosition(currentPos.x, currentPos.y, BOTTLE_EFFECT_BOTTLE_Z);

            //Scale in during movement
            local scaleNode = data.bottle.getChild(0);
            local newScale = p * data.scale;
            scaleNode.setScale(newScale, newScale, newScale);
        }
    };
    BottleEffectStateMachine.mStates_[BottleEffectStages.VIBRATE_AND_ROTATE] = class extends ::Util.State{
        mTotalCount_ = 50
        mNextState_ = BottleEffectStages.BREAK;
        function start(data){
            data.bottle.setPosition(data.centre.x, data.centre.y, BOTTLE_EFFECT_BOTTLE_Z);
        }
        function update(p, data){
            //Apply vibration based on sine wave
            local vibrationX = sin(p * 3.14159 * 8) * BOTTLE_EFFECT_VIBRATION_AMOUNT;
            local vibrationY = cos(p * 3.14159 * 8) * BOTTLE_EFFECT_VIBRATION_AMOUNT;

            data.bottle.setPosition(data.centre.x + vibrationX, data.centre.y + vibrationY, BOTTLE_EFFECT_BOTTLE_Z);

            //Apply rotation that increases with time
            local rotationAmount = p * BOTTLE_EFFECT_ROTATION_AMOUNT;
            local quat = Quat(rotationAmount, Vec3(0.2, 0.5, 1));
            data.bottle.setOrientation(quat);
        }
    };
    BottleEffectStateMachine.mStates_[BottleEffectStages.BREAK] = class extends ::Util.State{
        mTotalCount_ = 10
        mNextState_ = BottleEffectStages.NONE;
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

::EffectManager.Effects[Effect.BOTTLE_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mBottle_ = null;

    mCentre_ = Vec2(0, 0);
    mStartPos_ = Vec2(0, 0);
    mScale_ = 1.0;

    mStateMachine_ = null;

    function setup(data){
        mCentre_ = ::Vec2_ZERO;
        mStartPos_ = ::Vec2_ZERO;
        if("startPos" in data){
            mStartPos_ = data.startPos;
        }
        if("bottleScale" in data){
            mScale_ = data.bottleScale;
        }

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mBottle_ = createBottle(mParentNode_, mStartPos_, mScale_);

        mStateMachine_ = BottleEffectStateMachine({"bottle": mBottle_, "centre": mCentre_, "startPos": mStartPos_, "scale": mScale_});
        mStateMachine_.setState(BottleEffectStages.MOVE_TO_CENTRE);
    }

    function destroy(){
        mParentNode_.destroyNodeAndChildren();
    }

    function createBottle(parentNode, centre, scale){
        local bottleNode = parentNode.createChildSceneNode();
        local animNode = bottleNode.createChildSceneNode();
        local bottleItem = _gameCore.createVoxMeshItem("smallPotion.voxMesh");
        bottleItem.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
        animNode.attachObject(bottleItem);
        animNode.setScale(scale, scale, scale);

        return bottleNode;
    }

    function update(){
        print("Updating Bottle Effect");
        return mStateMachine_.update();
    }
};
