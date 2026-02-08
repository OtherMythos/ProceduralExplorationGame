enum SpreadCoinEffectStages{
    NONE,
    INITIAL_EXPAND,
    IDLE,
    MERGE_TO_FINISH,
    SHRINK_TO_FINISH,

    MAX
}
const COIN_EFFECT_COIN_Z = 10;

local SpreadCoinEffectStateMachine = class extends ::Util.StateMachine{
    mStates_ = array(SpreadCoinEffectStages.MAX);
};

{
    SpreadCoinEffectStateMachine.mStates_[SpreadCoinEffectStages.INITIAL_EXPAND] = class extends ::Util.State{
        mTotalCount_ = 30
        mNextState_ = SpreadCoinEffectStages.IDLE;
        function start(data){
            foreach(i in data.coins){
                i.setPosition(0, 0, COIN_EFFECT_COIN_Z);
            }
        }
        function update(p, data){
            local animPercentage = 1 - pow(1 - p, 4);
            for(local i = 0; i < data.coins.len(); i++){
                local newPos = data.start + (data.pos[i] * animPercentage);
                data.coins[i].setPosition(newPos.x, newPos.y, COIN_EFFECT_COIN_Z);
            }
        }
    };
    SpreadCoinEffectStateMachine.mStates_[SpreadCoinEffectStages.IDLE] = class extends ::Util.State{
        mTotalCount_ = 0
        mNextState_ = SpreadCoinEffectStages.MERGE_TO_FINISH;
        function start(data){ }
        function update(p, data){ }
    };
    SpreadCoinEffectStateMachine.mStates_[SpreadCoinEffectStages.MERGE_TO_FINISH] = class extends ::Util.State{
        mTotalCount_ = 30
        mNextState_ = SpreadCoinEffectStages.SHRINK_TO_FINISH;
        function start(data){ }
        function update(p, data){
            local animPercentage = p * p * p * p * p;
            for(local i = 0; i < data.coins.len(); i++){
                local coinStart = data.start + data.pos[i];
                local newPos = (coinStart - (coinStart - data.end) * animPercentage);
                data.coins[i].setPosition(newPos.x, newPos.y, COIN_EFFECT_COIN_Z);
                //Apply some scale on the way in.
                local scaleNode = data.coins[i].getChild(0);
                local newScale = (1.0 - animPercentage) * data.halfScale + data.halfScale;
                scaleNode.setScale(newScale, newScale, newScale);
            }
        }
    };
    SpreadCoinEffectStateMachine.mStates_[SpreadCoinEffectStages.SHRINK_TO_FINISH] = class extends ::Util.State{
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

::EffectManager.Effects[Effect.SPREAD_COIN_EFFECT] = class extends ::Effect{

    mParentNode_ = null;
    mCoinPos_ = null;
    mCoins_ = null;
    static CELL_WIDTH = 4;
    static CELL_HEIGHT = 4;

    mMoneyAdding_ = 0;
    mNumCoins_ = 10;
    mStartPos_ = Vec2(0, 0);
    mEndPos_ = Vec2(0, 0);
    mAnimStages_ = null;
    mScale_ = 10;
    mCellSize_ = 100;

    mStateMachine_ = null;

    function setup(data){
        mNumCoins_ = data.numCoins;
        mStartPos_ = data.start;
        mEndPos_ = data.end;
        mMoneyAdding_ = data.money;
        if("coinScale" in data){
            mScale_ = data.coinScale;
        }
        if("cellSize" in data){
            mCellSize_ = data.cellSize;
        }

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        mCoins_ = createInitialCoins(mNumCoins_, mParentNode_, mStartPos_, mScale_);
        mCoinPos_ = setupCoinPositions(mNumCoins_, Vec2(-mCellSize_ * CELL_WIDTH / 2, -mCellSize_ * CELL_HEIGHT / 2), mCellSize_);

        mStateMachine_ = SpreadCoinEffectStateMachine({"coins": mCoins_, "pos": mCoinPos_, "start": mStartPos_, "end": mEndPos_, "scale": mScale_, "halfScale": mScale_ / 2});
        mStateMachine_.setState(SpreadCoinEffectStages.INITIAL_EXPAND);

    }

    function destroy(){
        mCoins_.clear();
        mParentNode_.destroyNodeAndChildren();

        _event.transmit(Event.MONEY_ADDED, mMoneyAdding_);
    }

    function createInitialCoins(numCoins, parentNode, startPos, scale){
        local retVals = array(numCoins, null);

        local quat = Quat(1, 0, 0, 1);
        local variation = Vec3(20, 20, 1);
        local coinSize = 0.1;
        for(local i = 0; i < numCoins; i++){
            local newNode = parentNode.createChildSceneNode();
            local animNode = newNode.createChildSceneNode();
            local coinItem = _gameCore.createVoxMeshItem("coin.voxMesh");
            coinItem.setRenderQueueGroup(RENDER_QUEUE_EFFECT_FG);
            animNode.attachObject(coinItem);
            animNode.setScale(scale, scale, scale);
            //TODO will want to animate the coin rotation as well.
            local newQuat = Quat(_random.rand()*1.0, Vec3(0.1, 1, 0))
            animNode.setOrientation(quat * newQuat);

            retVals[i] = newNode;
        }

        return retVals;
    }

    /**
     * Generate the positions for all the coins based on a cell system.
     * @param numCoins The number of coins to place.
     */
    function setupCoinPositions(numCoins, gridStart, cellSize){
        local outPos = [];
        local totalCells = CELL_WIDTH * CELL_HEIGHT;
        local coinCells = array(totalCells, false);
        local usedCells = 0;

        for(local i = 0; i < numCoins; i++){
            local found = false;
            while(!found){
                local idx = _random.randIndex(coinCells);
                if(coinCells[idx] == false){
                    found = true;
                    //Use this cell
                    usedCells++;
                    coinCells[idx] = true;

                    local x = idx % CELL_WIDTH;
                    local y = (idx / CELL_WIDTH).tointeger();

                    local chosenPos = Vec2(x * cellSize, y * cellSize);
                    chosenPos += gridStart;
                    chosenPos += _random.randVec2() * cellSize;
                    outPos.append(chosenPos);
                    if(usedCells == totalCells){
                        //Each cell is saturated, so reset the array
                        coinCells = array(totalCells, false);
                        usedCells = 0;
                    }
                }
            }
        }

        return outPos;
    }

    function update(){
        return mStateMachine_.update();
    }
};