//Version of the TerrainChunkManager which also includes editor tools.

::SceneEditorTerrainChunkManager <- class extends ::TerrainChunkManager{

    function drawVoxTypeValues(x, y, width, height, values){
        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        if(width == 1 && height == 1){
            local chunkX = (x / mChunkWidth_).tointeger();
            local chunkY = (y / mChunkHeight_).tointeger();
            local targetIdx = chunkX << 4 | chunkY;
            local targetX = x - (chunkX * mChunkWidth_);
            local targetY = y - (chunkY * mChunkHeight_);

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

            mMapData_.setAltitudeForCoord(x, y, values[0]);
            recreateChunkItem(chunkX, chunkY);
        }
    }


};