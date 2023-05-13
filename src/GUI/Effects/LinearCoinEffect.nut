const COIN_EFFECT_COIN_Z = 10;


enum LinearCoinEffectStages{
    NONE,
    MOVEMENT,
    SHRINK_TO_FINISH,

    MAX
}
local LinearCoinEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(LinearCoinEffectStages.MAX);
};

{
    LinearCoinEffectStateMachine.mStates_[LinearCoinEffectStages.MOVEMENT] = class extends ::Util.State{
        mTotalCount_ = 30
        mNextState_ = LinearCoinEffectStages.SHRINK_TO_FINISH;
        function start(data){
            foreach(i in data.coins){
                i.setPosition(data.start.x, data.start.y, COIN_EFFECT_COIN_Z);
            }
        }
        function update(p, data){
            local diff = data.end - data.start;

            local c1 = 1.70158;
            local c3 = c1 + 1;
            local animPercentage = 1 + c3 * pow(p - 1, 3) + c1 * pow(p - 1, 2);

            //local animPercentage = 1 - pow(1 - p, 4);
            for(local i = 0; i < data.coins.len(); i++){
                local xAnim = diff.x * animPercentage;
                local xAnimBase = diff.x * p;
                local xAnimDiff = xAnim - xAnimBase;

                data.coins[i].setPosition(data.start.x + diff.x * p + xAnimDiff * data.offsets[i], data.start.y + diff.y * p, COIN_EFFECT_COIN_Z);
            }
        }
    };
    LinearCoinEffectStateMachine.mStates_[LinearCoinEffectStages.SHRINK_TO_FINISH] = class extends ::Util.State{
        mTotalCount_ = 8
        mNextState_ = SpreadCoinEffectStages.NONE;
        function start(data){ }
        function update(p, data){
            for(local i = 0; i < data.coins.len(); i++){
                //Apply some scale on the way in.
                local scaleNode = data.coins[i].getChild(0);
                local newScale = (1.0 - p) * data.halfScale;
                scaleNode.setScale(newScale, newScale, newScale);
            }
        }
    };
}

::EffectManager.Effects[Effect.LINEAR_COIN_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mCoins_ = null;
    mOffsets_ = null;

    mMoneyAdding_ = 0;
    mNumCoins_ = 10;
    mStartPos_ = Vec2(0, 0);
    mEndPos_ = Vec2(0, 0);
    mScale_ = 0.5;
    mCellSize_ = 5;

    mStateMachine_ = null;

    function setup(data){
        mNumCoins_ = data.numCoins;
        mStartPos_ = data.start;
        mEndPos_ = data.end;
        mMoneyAdding_ = data.money;
        if("coinScale" in data){
            mScale_ = data.coinScale;
        }

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mCoins_ = createInitialCoins(mNumCoins_, mParentNode_, mStartPos_, mScale_);
        mOffsets_ = createCoinOffsets(mNumCoins_);

        mStateMachine_ = LinearCoinEffectStateMachine({"coins": mCoins_, "start": mStartPos_, "end": mEndPos_, "scale": mScale_, "halfScale": mScale_ / 2, "offsets": mOffsets_});
        mStateMachine_.setState(LinearCoinEffectStages.MOVEMENT);
    }

    function destroy(){
        mCoins_.clear();
        mParentNode_.destroyNodeAndChildren();

        _event.transmit(Event.MONEY_ADDED, mMoneyAdding_);
    }

    function createCoinOffsets(numCoins){
        local offsets = array(numCoins);
        for(local i = 0; i < numCoins; i++){
            offsets[i] = (_random.rand()-0.5)*2;
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
            local coinItem = _scene.createItem("coin.mesh");
            coinItem.setRenderQueueGroup(65);
            animNode.attachObject(coinItem);
            animNode.setScale(scale, scale, scale);
            //TODO will want to animate the coin rotation as well.
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