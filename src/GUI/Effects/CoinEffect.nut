enum CoinEffectStages{
    NONE,
    INITIAL_EXPAND,
    IDLE,
    MERGE_TO_FINISH,
    SHRINK_TO_FINISH,

    MAX
}
::EffectManager.Effects[Effect.COIN_EFFECT] = class extends ::Popup{

    mParentNode_ = null;
    mCoinPos_ = null;
    mCoins_ = null;
    static CELL_WIDTH = 4;
    static CELL_HEIGHT = 4;
    mAnimStage_ = CoinEffectStages.NONE;

    mNumCoins_ = 10;
    mStartPos_ = Vec2(0, 0);
    mEndPos_ = Vec2(0, 0);

    mAnimStages_ = array(CoinEffectStages.MAX);

    function setup(data){
        mNumCoins_ = data.numCoins;
        mStartPos_ = data.start;
        mEndPos_ = data.end;

        mAnimStages_[CoinEffectStages.INITIAL_EXPAND] = {
            mCurrent_ = 0
            mTotal_ = 30
            function start(coins, positions){
                foreach(i in coins){
                    i.setPosition(0, 0, 0);
                }
            }
            function update(coins, positions, start, end){
                local currentPercentage = mCurrent_.tofloat() / mTotal_.tofloat()
                //local animPercentage = sin((currentPercentage * PI) / 2);
                local animPercentage = 1 - pow(1 - currentPercentage, 4);
                for(local i = 0; i < coins.len(); i++){
                    local newPos = start + (positions[i] * animPercentage);
                    coins[i].setPosition(newPos.x, newPos.y, 0);
                }
                mCurrent_++;
                if(mCurrent_ >= mTotal_){
                    return CoinEffectStages.IDLE;
                }
                return CoinEffectStages.INITIAL_EXPAND;
            }
        };
        mAnimStages_[CoinEffectStages.IDLE] = {
            mCurrent_ = 0
            mTotal_ = 20
            function start(coins, positions){ }
            function update(coins, positions, start, end){
                mCurrent_++;
                if(mCurrent_ >= mTotal_) return CoinEffectStages.IDLE;
                return CoinEffectStages.MERGE_TO_FINISH;
            }
        };
        mAnimStages_[CoinEffectStages.MERGE_TO_FINISH] = {
            mCurrent_ = 0
            mTotal_ = 50
            function start(coins, positions){ }
            function update(coins, positions, start, end){
                local p = mCurrent_.tofloat() / mTotal_.tofloat()
                //local animPercentage = sin((currentPercentage * PI) / 2);
                local animPercentage = p * p * p * p * p;
                for(local i = 0; i < coins.len(); i++){
                    local coinStart = start + positions[i];
                    local newPos = (coinStart - (coinStart - end) * animPercentage) ;
                    coins[i].setPosition(newPos.x, newPos.y, 0);
                    //Apply some scale on the way in.
                    local scaleNode = coins[i].getChild(0);
                    local newScale = (1.0 - animPercentage) * 0.3 + 0.2;
                    scaleNode.setScale(newScale, newScale, newScale);
                }

                mCurrent_++;
                if(mCurrent_ >= mTotal_) return CoinEffectStages.SHRINK_TO_FINISH;
                return CoinEffectStages.MERGE_TO_FINISH;
            }
        };
        mAnimStages_[CoinEffectStages.SHRINK_TO_FINISH] = {
            mCurrent_ = 0
            mTotal_ = 8
            function start(coins, positions){ }
            function update(coins, positions, start, end){
                local p = mCurrent_.tofloat() / mTotal_.tofloat()
                for(local i = 0; i < coins.len(); i++){
                    //Apply some scale on the way in.
                    local scaleNode = coins[i].getChild(0);
                    local newScale = (1.0 - p) * 0.2
                    scaleNode.setScale(newScale, newScale, newScale);
                }

                mCurrent_++;
                if(mCurrent_ >= mTotal_) return CoinEffectStages.MAX;
                return CoinEffectStages.SHRINK_TO_FINISH;
            }
        };

        local cellSize = 5;

        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        setupCameras();
        mCoins_ = createInitialCoins(mNumCoins_, mParentNode_, mStartPos_);
        mCoinPos_ = setupCoinPositions(mNumCoins_, Vec2(-cellSize * CELL_WIDTH / 2, -cellSize * CELL_HEIGHT / 2), cellSize);

        setAnimStage(CoinEffectStages.INITIAL_EXPAND)
    }

    function destroy(){
        mCoins_.clear();
        mParentNode_.destroyNodeAndChildren();
    }

    function createInitialCoins(numCoins, parentNode, startPos){
        local retVals = array(numCoins, null);

        local quat = Quat(1, 0, 0, 1);
        local variation = Vec3(20, 20, 1);
        local coinSize = 0.5;
        for(local i = 0; i < numCoins; i++){
            local newNode = parentNode.createChildSceneNode();
            local animNode = newNode.createChildSceneNode();
            local coinItem = _scene.createItem("coin.mesh");
            coinItem.setRenderQueueGroup(65);
            animNode.attachObject(coinItem);
            animNode.setScale(coinSize, coinSize, coinSize);
            animNode.setPosition(startPos.x, startPos.y, 0);
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
        local entry = mAnimStages_[mAnimStage_];
        if(entry != null){
            local finishedState = entry.update(mCoins_, mCoinPos_, mStartPos_, mEndPos_);
            if(finishedState != mAnimStage_){
                if(finishedState == CoinEffectStages.MAX) return false;
                setAnimStage(finishedState);
            }
        }

        return true;
    }

    function setupCameras(){
        foreach(i in [CompositorSceneType.BG_EFFECT, CompositorSceneType.FG_EFFECT]){
            local camera = ::CompositorManager.getCameraForSceneType(i);
            assert(camera);
            local node = camera.getParentNode();
            node.setPosition(0, 0, 10);
            camera.lookAt(0, 0, 0);
            camera.setProjectionType(_PT_ORTHOGRAPHIC);
            camera.setOrthoWindow(20, 20);
        }
    }

    function setAnimStage(stage){
        local entry = mAnimStages_[stage];
        if(entry != null){
            entry.start(mCoins_, mCoinPos_);
        }
        mAnimStage_ = stage;
    }

};