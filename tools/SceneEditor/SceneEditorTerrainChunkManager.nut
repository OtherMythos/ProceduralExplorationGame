//Version of the TerrainChunkManager which also includes editor tools.

::SceneEditorTerrainChunkManager <- class extends ::TerrainChunkManager{

    mCurrentAction_ = null

    function drawVoxTypeValues(x, y, width, height, values){
        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        if(width == 1 && height == 1){
            local chunkX = (x / mChunkWidth_).tointeger();
            local chunkY = (y / mChunkHeight_).tointeger();
            local targetIdx = chunkX << 4 | chunkY;
            local targetX = x - (chunkX * mChunkWidth_);
            local targetY = y - (chunkY * mChunkHeight_);

            assert(mCurrentAction_ != null);
            local voxVal = mMapData_.getVoxelForCoord(x, y);
            if(voxVal == null) return;
            mCurrentAction_.populateForCoord(x, y, chunkX, chunkY, voxVal, values[0]);
            mMapData_.setVoxelForCoord(x, y, values[0]);
            recreateChunkItem(chunkX, chunkY);
        }
    }

    function drawHeightValues(x, y, width, height, values){
        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        if(width == 1 && height == 1){
            local chunkX = (x / mChunkWidth_).tointeger();
            local chunkY = (y / mChunkHeight_).tointeger();
            local targetIdx = chunkX << 4 | chunkY;
            local targetX = x - (chunkX * mChunkWidth_);
            local targetY = y - (chunkY * mChunkHeight_);

            assert(mCurrentAction_ != null);
            local altitudeVal = mMapData_.getAltitudeForCoord(x, y);
            if(altitudeVal == null) return;
            mCurrentAction_.populateForCoord(x, y, chunkX, chunkY, altitudeVal, values[0]);
            mMapData_.setAltitudeForCoord(x, y, values[0]);
            recreateChunkItem(chunkX, chunkY);
        }
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