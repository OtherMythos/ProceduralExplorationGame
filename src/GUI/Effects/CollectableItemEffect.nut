const COLLECTABLE_ITEM_EFFECT_Z = 11;
const COLLECTABLE_ITEM_EFFECT_HOVER_AMOUNT = 3.0;
const COLLECTABLE_ITEM_EFFECT_SCALE_IN_FRAMES = 20;

enum CollectableItemEffectStages{
    NONE,
    HOVER,
    SHRINK,

    MAX
}

local CollectableItemEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(CollectableItemEffectStages.MAX);
};

{
    CollectableItemEffectStateMachine.mStates_[CollectableItemEffectStages.HOVER] = class extends ::Util.State{
        mTotalCount_ = 99999;
        mNextState_ = null;
        mFrameCount_ = 0;

        function start(data){
            mFrameCount_ = 0;
        }

        function update(p, data){
            mFrameCount_++;

            //Scale in during first frames with quadratic easing
            local scaleP = min(1.0, mFrameCount_.tofloat() / COLLECTABLE_ITEM_EFFECT_SCALE_IN_FRAMES.tofloat());
            local currentScale = data.scale * (scaleP * scaleP);

            //Gentle hover bob
            local bob = sin(mFrameCount_ * 0.025) * COLLECTABLE_ITEM_EFFECT_HOVER_AMOUNT;

            local scaleNode = data.item.getChild(0);
            scaleNode.setScale(currentScale, currentScale, currentScale);
            data.item.setPosition(data.centre.x, data.centre.y + bob, COLLECTABLE_ITEM_EFFECT_Z);

            //Sin wave rock matching inventory animation style
            local t = mFrameCount_ * 0.01;
            local rotY = Quat(sin(t * 1.5) * 0.5, ::Vec3_UNIT_Y);
            local rotX = Quat(sin(t * 2.0) * 0.25, ::Vec3_UNIT_X);
            local baseOrient = Quat();
            baseOrient += Quat(0.5, ::Vec3_UNIT_Y);
            baseOrient += Quat(-0.5, ::Vec3_UNIT_Z);
            baseOrient += Quat(1.0, ::Vec3_UNIT_X);
            local animatedOrient = baseOrient;
            animatedOrient += rotY;
            animatedOrient += rotX;
            data.item.setOrientation(animatedOrient);

            return null;
        }
    };

    CollectableItemEffectStateMachine.mStates_[CollectableItemEffectStages.SHRINK] = class extends ::Util.State{
        mTotalCount_ = 15;
        mNextState_ = CollectableItemEffectStages.NONE;

        function start(data){
        }

        function update(p, data){
            local eased = p * p;
            local currentX = data.centre.x + (data.targetPos.x - data.centre.x) * eased;
            local currentY = data.centre.y + (data.targetPos.y - data.centre.y) * eased;
            data.item.setPosition(currentX, currentY, COLLECTABLE_ITEM_EFFECT_Z);

            local currentScale = data.scale * (1.0 - p);
            local scaleNode = data.item.getChild(0);
            scaleNode.setScale(currentScale, currentScale, currentScale);

            return null;
        }
    };
}

::EffectManager.Effects[Effect.COLLECTABLE_ITEM_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mItem_ = null;
    mStateMachine_ = null;
    mStateMachineData_ = null;

    function setup(data){
        local meshName = "collectables.messageInABottle.voxMesh";
        local scale = 10.0;
        local targetPos = ::Vec2_ZERO;

        if("meshName" in data) meshName = data.meshName;
        if("itemScale" in data) scale = data.itemScale;
        if("targetPos" in data) targetPos = data.targetPos;

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
        mItem_ = createItem_(mParentNode_, meshName);

        mStateMachineData_ = {
            "item": mItem_,
            "centre": ::Vec2_ZERO,
            "scale": scale,
            "targetPos": targetPos
        };

        mStateMachine_ = CollectableItemEffectStateMachine(mStateMachineData_);
        mStateMachine_.setState(CollectableItemEffectStages.HOVER);
    }

    function destroy(){
        mParentNode_.destroyNodeAndChildren();
    }

    function setCentre(x, y){
        mStateMachineData_.centre = Vec2(x, y);
    }

    function beginShrink(){
        mStateMachine_.setState(CollectableItemEffectStages.SHRINK);
    }

    function createItem_(parentNode, meshName){
        local itemNode = parentNode.createChildSceneNode();
        local scaleNode = itemNode.createChildSceneNode();
        local voxItem = _gameCore.createVoxMeshItem(meshName);
        voxItem.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);

        //Use AABB to offset the mesh so its visual centre sits at the node origin
        local aabb = voxItem.getLocalAabb();
        local meshCentre = aabb.getCentre();
        local offsetNode = scaleNode.createChildSceneNode();
        offsetNode.setPosition(-meshCentre.x, -meshCentre.y, -meshCentre.z);
        offsetNode.attachObject(voxItem);

        scaleNode.setScale(0, 0, 0); //starts hidden, HOVER state scales it in
        return itemNode;
    }

    function update(){
        return mStateMachine_.update();
    }
};
