//TODO lots of duplication here obviously, better fix that at some point.

const EXP_ORB_EFFECT_Z = 11;


enum LinearEXPOrbEffectStages{
    NONE,
    MOVEMENT,
    SHRINK_TO_FINISH,

    MAX
}
local LinearEXPOrbEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(LinearEXPOrbEffectStages.MAX);
};

{
    LinearEXPOrbEffectStateMachine.mStates_[LinearEXPOrbEffectStages.MOVEMENT] = class extends ::Util.State{
        mTotalCount_ = 30
        mNextState_ = LinearEXPOrbEffectStages.SHRINK_TO_FINISH;
        function start(data){
            foreach(i in data.orbs){
                i.setPosition(data.start.x, data.start.y, EXP_ORB_EFFECT_Z);
            }
        }
        function update(p, data){
            local diff = data.end - data.start;
            local dir = diff.normalisedCopy();
            local perpDir = dir.perpendicular();

            local c1 = 1.70158;
            local c3 = c1 + 1;
            local animPercentage = 1 + c3 * pow(p - 1, 3) + c1 * pow(p - 1, 2);

            local anim = diff * animPercentage;
            local animBase = diff * p;
            local animDiff = anim - animBase;

            for(local i = 0; i < data.orbs.len(); i++){
                local test = perpDir * animDiff * data.offsets[i];
                data.orbs[i].setPosition(data.start.x + diff.x * p + test.x, data.start.y + diff.y * p + test.y, EXP_ORB_EFFECT_Z);
            }
        }
    };
    LinearEXPOrbEffectStateMachine.mStates_[LinearEXPOrbEffectStages.SHRINK_TO_FINISH] = class extends ::Util.State{
        mTotalCount_ = 8
        mNextState_ = SpreadCoinEffectStages.NONE;
        function start(data){ }
        function update(p, data){
            for(local i = 0; i < data.orbs.len(); i++){
                //Apply some scale on the way in.
                local scaleNode = data.orbs[i].getChild(0);
                local newScale = (1.0 - p) * data.halfScale;
                scaleNode.setScale(newScale, newScale, newScale);
            }
        }
    };
}

::EffectManager.Effects[Effect.LINEAR_EXP_ORB_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mOrbs_ = null;
    mOffsets_ = null;

    mNumOrbs_ = 1;
    mStartPos_ = Vec2(0, 0);
    mEndPos_ = Vec2(0, 0);
    mScale_ = 0.1;
    mCellSize_ = 100;

    mStateMachine_ = null;

    function setup(data){
        mNumOrbs_ = data.numOrbs;
        mStartPos_ = data.start;
        mEndPos_ = data.end;
        if("orbScale" in data){
            mScale_ = data.orbScale;
        }

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mOrbs_ = createInitialCoins(mNumOrbs_, mParentNode_, mStartPos_, mScale_);
        mOffsets_ = createCoinOffsets(mNumOrbs_);

        mStateMachine_ = LinearEXPOrbEffectStateMachine({"orbs": mOrbs_, "start": mStartPos_, "end": mEndPos_, "scale": mScale_, "halfScale": mScale_ / 2, "offsets": mOffsets_});
        mStateMachine_.setState(LinearEXPOrbEffectStages.MOVEMENT);
    }

    function destroy(){
        mOrbs_.clear();
        mParentNode_.destroyNodeAndChildren();

        _event.transmit(Event.EXP_ORBS_ADDED, 1);
    }

    function createCoinOffsets(numCoins){
        local offsets = array(numCoins);
        for(local i = 0; i < numCoins; i++){
            offsets[i] = (_random.rand()-0.5)*5;
        }
        return offsets;
    }

    function createInitialCoins(numCoins, parentNode, startPos, scale){
        local retVals = array(numCoins, null);

        local quat = Quat(1, 0, 0, 1);
        local variation = Vec3(20, 20, 1);
        local coinSize = 0.1;
        for(local i = 0; i < numCoins; i++){
            local newNode = parentNode.createChildSceneNode();
            local animNode = newNode.createChildSceneNode();
            local coinItem = _scene.createItem(::expOrbMesh);
            _gameCore.writeFlagsToItem(coinItem, 0x1);
            coinItem.setDatablock("baseVoxelMaterial");
            coinItem.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
            animNode.attachObject(coinItem);
            animNode.setScale(scale, scale, scale);
            local newQuat = Quat(_random.rand()*1.0, Vec3(0.1, 1, 0))
            animNode.setOrientation(quat * newQuat);

            retVals[i] = newNode;
        }

        return retVals;
    }

    function update(){
        return mStateMachine_.update();
    }
};