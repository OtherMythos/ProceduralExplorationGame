//Version of the TerrainChunkManager which also includes editor tools.

::SceneEditorTerrainChunkManager <- class extends ::TerrainChunkManager{

    mCurrentAction_ = null

    constructor(worldId, alterValues){
        base.constructor(worldId);

        mAlterValues_ = alterValues;
    }

    function drawValue_(x, y, width, height, values, altitude){
        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        local halfWidth = (width - 1) / 2;
        local halfHeight = (height - 1) / 2;

        local drawVal = {};

        for(local yy = 0; yy < height; yy++){
            for(local xx = 0; xx < width; xx++){
                local coordX = x + xx - halfWidth;
                local coordY = y + yy - halfHeight;

                local chunkX = (coordX / mChunkWidth_).tointeger();
                local chunkY = (coordY / mChunkHeight_).tointeger();
                local targetIdx = chunkX << 4 | chunkY;
                local targetX = coordX - (chunkX * mChunkWidth_);
                local targetY = coordY - (chunkY * mChunkHeight_);

                assert(mCurrentAction_ != null);

                local altitudeVal = null;
                if(altitude){
                    altitudeVal = mMapData_.getAltitudeForCoord(coordX, coordY);
                }else{
                    altitudeVal = mMapData_.getVoxelForCoord(coordX, coordY);
                }
                if(altitudeVal == null) return;
                local writeValue = values[xx + yy * width];
                mCurrentAction_.populateForCoord(coordX, coordY, chunkX, chunkY, altitudeVal, writeValue);
                if(altitude){
                    mMapData_.setAltitudeForCoord(coordX, coordY, writeValue);
                }else{
                    mMapData_.setVoxelForCoord(coordX, coordY, writeValue);
                }

                drawVal.rawset(targetIdx, true);
            }
        }

        foreach(c,i in drawVal){
            local chunkX = (c >> 4) & 0xF;
            local chunkY = c & 0xF;
            recreateChunkItem(chunkX, chunkY);
        }

    }

    function drawVoxTypeValues(x, y, width, height, values){
        drawValue_(x, y, width, height, values, false);
    }

    function drawHeightValues(x, y, width, height, values){
        drawValue_(x, y, width, height, values, true);
    }

    function notifyActionStart(altitude){
        assert(mCurrentAction_ == null);
        mCurrentAction_ = ::SceneEditorFramework.Actions[SceneEditorFramework_Action.USER_0](mMapData_, altitude, this);
    }

    function notifyActionEnd(){
        assert(mCurrentAction_ != null);
        ::Base.mEditorBase.mActionStack_.pushAction_(mCurrentAction_);
        mCurrentAction_ = null;
    }

};