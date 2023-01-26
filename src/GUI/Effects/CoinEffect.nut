enum CoinEffectStages{
    NONE,
    INITIAL_EXPAND,
    IDLE,
    MERGE_TO_FINISH,

    MAX
}
::EffectManager.Effects[Effect.COIN_EFFECT] = class extends ::Popup{

    mCoinPos_ = null;
    mCoins_ = null;
    static CELL_WIDTH = 4;
    static CELL_HEIGHT = 4;
    mAnimStage_ = CoinEffectStages.NONE;

    mAnimStages_ = array(CoinEffectStages.MAX);

    function setup(data){
        mAnimStages_[CoinEffectStages.INITIAL_EXPAND] = {
            mCurrent_ = 0
            mTotal_ = 50
            function start(coins, positions){
                foreach(i in coins){
                    i.setPosition(0, 0, 0);
                }
            }
            function update(coins, positions){
                local currentPercentage = mCurrent_.tofloat() / mTotal_.tofloat()
                for(local i = 0; i < coins.len(); i++){
                    local newPos = positions[i] * currentPercentage;
                    coins[i].setPosition(newPos.x, newPos.y, 0);
                }
                mCurrent_++;
                if(mCurrent_ >= mTotal_){
                    return CoinEffectStages.IDLE;
                }
                return CoinEffectStages.INITIAL_EXPAND;
            }
        };

        local cellSize = 5;
        local numCoins = 20;

        local parentNode = _scene.getRootSceneNode().createChildSceneNode();

        setupCameras();
        mCoins_ = createInitialCoins(numCoins, parentNode);
        mCoinPos_ = setupCoinPositions(numCoins, Vec2(-cellSize * CELL_WIDTH / 2, -cellSize * CELL_HEIGHT / 2), cellSize);

        setAnimStage(CoinEffectStages.INITIAL_EXPAND)
    }

    function createInitialCoins(numCoins, parentNode){
        local retVals = array(numCoins, null);

        local quat = Quat(1, 0, 0, 1);
        local variation = Vec3(20, 20, 1);
        local coinSize = 0.5;
        for(local i = 0; i < numCoins; i++){
            local newNode = parentNode.createChildSceneNode();
            local coinItem = _scene.createItem("coin.mesh");
            coinItem.setRenderQueueGroup(65);
            newNode.attachObject(coinItem);
            newNode.setScale(coinSize, coinSize, coinSize);
            //TODO will want to animate the coin rotation as well.
            local newQuat = Quat(_random.rand()*1.0, Vec3(0.1, 1, 0))
            newNode.setOrientation(quat * newQuat);

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
                    print("Placing coin " + i + " in " + idx);
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
            local finishedState = entry.update(mCoins_, mCoinPos_);
            if(finishedState != mAnimStage_){
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