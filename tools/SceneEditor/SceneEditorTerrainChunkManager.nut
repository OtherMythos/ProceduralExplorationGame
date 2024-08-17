//Version of the TerrainChunkManager which also includes editor tools.

::SceneEditorTerrainChunkManager <- class extends ::TerrainChunkManager{

    mMapHeightDataCopy_ = null;
    mMapVoxTypeDataCopy_ = null;

    function setup(mapData, chunkDivisions){
        base.setup(mapData, chunkDivisions);

        local duplicateArray = function(arr){
            local newArr = array(arr.len());
            for(local i = 0; i < newArr.len(); i++){
                newArr[i] = arr[i];
            }
            return newArr;
        }
        mMapHeightDataCopy_ = duplicateArray(mMapData_.voxHeight.data);
        mMapVoxTypeDataCopy_ = duplicateArray(mMapData_.voxType.data);

        assert(mMapHeightDataCopy_.len() == mMapData_.width * mMapData_.height);
        assert(mMapVoxTypeDataCopy_.len() == mMapData_.width * mMapData_.height);
    }

    function drawVoxTypeValues(x, y, width, height, values){
        assert(mMapVoxTypeDataCopy_ != null);

        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        local depth = mMapData_.voxHeight.greatest;

        assert(mMapVoxTypeDataCopy_.len() == mMapData_.width * mMapData_.height);

        if(width == 1 && height == 1){
            local altered = false;
            mMapVoxTypeDataCopy_[x + y * mMapData_.width] = values[0];

            local chunkX = (x / mChunkWidth_).tointeger();
            local chunkY = (y / mChunkHeight_).tointeger();
            local targetIdx = chunkX << 4 | chunkY;
            local targetX = x - (chunkX * mChunkWidth_);
            local targetY = y - (chunkY * mChunkHeight_);
            local targetChunkArray = mChunkColourData_[targetIdx];
            local startColour = mMapData_.voxType.data[x + y * mMapData_.voxType.width];

            local startIdx = targetX + (targetY * (mChunkWidth_ + PADDING_BOTH));
            local otherIdx = (mChunkWidth_ + PADDING_BOTH) * (mChunkHeight_ + PADDING_BOTH)
            local valToWrite = values[0];
            for(local i = 0; i < depth; i++){
                local idx = startIdx + (i * otherIdx);
                local prev = targetChunkArray[idx];
                if(prev == null) continue;

                targetChunkArray[idx] = valToWrite;
                altered = (prev != valToWrite);
            }
            printf("Chunk format %i %i", chunkX, chunkY);

            //mNodesForChunk_[targetIdx].destroyNodeAndChildren();
            if(altered){
                recreateChunkItem(chunkX, chunkY);
            }
        }

        assert(mMapVoxTypeDataCopy_.len() == mMapData_.width * mMapData_.height);
    }

    function drawHeightValues(x, y, width, height, values){
        assert(mMapHeightDataCopy_ != null);

        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        local depth = mMapData_.voxHeight.greatest;

        if(width == 1 && height == 1){
            local altered = false;
            local heightToWrite = values[0];
            mMapHeightDataCopy_[x + y * mMapData_.width] = heightToWrite;
            //print(mMapHeightDataCopy_[x + y * mMapData_.width]);

            local chunkX = (x / mChunkWidth_).tointeger();
            local chunkY = (y / mChunkHeight_).tointeger();
            local targetIdx = chunkX << 4 | chunkY;
            local targetX = x - (chunkX * mChunkWidth_);
            local targetY = y - (chunkY * mChunkHeight_);
            local targetChunkArray = mChunkColourData_[targetIdx];
            //TODO might want to read this from the copy.
            local startColour = mMapData_.voxType.data[x + y * mMapData_.voxType.width];

            local startIdx = targetX + (targetY * (mChunkWidth_ + PADDING_BOTH));
            local otherIdx = (mChunkWidth_ + PADDING_BOTH) * (mChunkHeight_ + PADDING_BOTH)
            for(local i = 0; i < depth; i++){
                local valToWrite = (i >= heightToWrite) ? null : startColour;
                local idx = startIdx + (i * otherIdx);
                local prev = targetChunkArray[idx];

                targetChunkArray[idx] = valToWrite;
                altered = (prev != valToWrite);
            }
            printf("Chunk format %i %i", chunkX, chunkY);

            //mNodesForChunk_[targetIdx].destroyNodeAndChildren();
            if(altered){
                recreateChunkItem(chunkX, chunkY);
            }
        }
    }


};