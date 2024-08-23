//Version of the TerrainChunkManager which also includes editor tools.

::SceneEditorTerrainChunkManager <- class extends ::TerrainChunkManager{

    mMapHeightDataCopy_ = null;
    mMapVoxTypeDataCopy_ = null;

    function setup(mapData, chunkDivisions){
        base.setup(mapData, chunkDivisions);

        local duplicateArray = function(data, width, height, copyType){
            //local newArr = array(arr.len());
            local newArr = array(width * height);

            for(local y = 0; y < height; y++){
                for(local x = 0; x < width; x++){
                    if(copyType){
                        newArr[x + y * width] = data.getAltitudeForCoord(x, y);
                    }else{
                        newArr[x + y * width] = data.getVoxelForCoord(x, y);
                    }
                }
            }
            return newArr;
        }
        //mMapHeightDataCopy_ = duplicateArray(mapData, mWidth_, mHeight_, true);
        //mMapVoxTypeDataCopy_ = duplicateArray(mapData, mWidth_, mHeight_, false);

        //assert(mMapHeightDataCopy_.len() == mWidth_ * mHeight_);
        //assert(mMapVoxTypeDataCopy_.len() == mWidth_ * mHeight_);
    }

    function drawVoxTypeValues(x, y, width, height, values){
        //assert(mMapVoxTypeDataCopy_ != null);

        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        //assert(mMapVoxTypeDataCopy_.len() == mWidth_ * mHeight_);

        if(width == 1 && height == 1){
            //mMapVoxTypeDataCopy_[x + y * mWidth_] = values[0];

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
        //assert(mMapHeightDataCopy_ != null);

        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        if(width == 1 && height == 1){
            //mMapHeightDataCopy_[x + y * mWidth_] = heightToWrite;

            local chunkX = (x / mChunkWidth_).tointeger();
            local chunkY = (y / mChunkHeight_).tointeger();
            local targetIdx = chunkX << 4 | chunkY;
            local targetX = x - (chunkX * mChunkWidth_);
            local targetY = y - (chunkY * mChunkHeight_);

            mMapData_.setAltitudeForCoord(x, y, 1);
            recreateChunkItem(chunkX, chunkY);
        }
    }


};