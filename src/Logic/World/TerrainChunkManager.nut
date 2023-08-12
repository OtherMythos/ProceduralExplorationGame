::TerrainChunkManager <- class{

    mMapData_ = null;
    mParentNode_ = null;
    mChunkDivisions_ = 1;
    mVoxTerrainMesh_ = null;

    mChunkColourData_ = null;
    mMapHeightDataCopy_ = null;
    mMapVoxTypeDataCopy_ = null;
    mNodesForChunk_ = null;

    mChunkWidth_ = null;
    mChunkHeight_ = null;

    PADDING = 1;
    PADDING_BOTH = null;

    constructor(){
        PADDING_BOTH = PADDING * 2;
    }

    /**
     * @param copyData Duplicate height values per chunk. Only use if allowing for a level editor.
     */
    function setup(parentNode, mapData, chunkDivisions, copyData=false){
        mMapData_ = mapData;
        mParentNode_ = parentNode;
        mChunkDivisions_ = chunkDivisions;
        mChunkColourData_ = {};
        mNodesForChunk_ = {};

        mChunkWidth_ = mMapData_.width / mChunkDivisions_;
        mChunkHeight_ = mMapData_.height / mChunkDivisions_;

        if(copyData){
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

        constructDataForChunks();
        generateInitialChunks();
    }

    function constructDataForChunks(){
        //Padding so the ambient occlusion can work.
        local depth = mMapData_.voxHeight.greatest;

        local heightData = mMapData_.voxHeight.data;
        local colourData = mMapData_.voxType.data;

        local width = mMapData_.width;
        local height = mMapData_.height;

        local arraySize = (mChunkWidth_ + PADDING_BOTH) * (mChunkHeight_ + PADDING_BOTH) * depth;

        for(local y = 0; y < mChunkDivisions_; y++){
            for(local x = 0; x < mChunkDivisions_; x++){
                local posId = x << 4 | y;
                local newArray = array(arraySize, null);

                //Populate the array with the data.
                local startX = x * mChunkWidth_;
                local startY = y * mChunkHeight_;

                //Keep track with a simple count rather than calculating the value each iteration.
                local count = -1;
                for(local yy = startY - PADDING; yy < startY + mChunkHeight_ + PADDING; yy++){
                    for(local xx = startX - PADDING; xx < startX + mChunkWidth_ + PADDING; xx++){
                        count++;
                        if(xx < 0 || yy < 0 || xx >= width || yy >= height) continue;
                        local altitude = heightData[xx + yy * width];
                        for(local i = 0; i < altitude; i++){
                            newArray[count + (i*(mChunkWidth_+PADDING_BOTH)*(mChunkHeight_+PADDING_BOTH))] = colourData[xx + yy * width];
                        }
                    }
                }

                mChunkColourData_.rawset(posId, newArray);
            }
        }
    }

    function generateInitialChunks(){
        for(local y = 0; y < mChunkDivisions_; y++){
            for(local x = 0; x < mChunkDivisions_; x++){
                recreateChunk(x, y);
            }
        }
    }

    function voxeliseChunk_(chunkX, chunkY){
        local targetIdx = chunkX << 4 | chunkY;
        assert(mChunkColourData_.rawin(targetIdx));
        local targetChunkArray = mChunkColourData_.rawget(targetIdx);

        local widthWithPadding = (mMapData_.width / mChunkDivisions_) + PADDING * 2;
        local heightWithPadding = (mMapData_.height / mChunkDivisions_) + PADDING * 2;

        local vox = VoxToMesh(Timer(), 1 << 2, 0.4);
        //TODO get rid of this with the proper function to destory meshes.
        ::ExplorationCount++;
        local meshObj = vox.createMeshForVoxelData(format("terrainChunkManager%s%s", ::ExplorationCount.tostring(), targetIdx.tostring()), targetChunkArray, widthWithPadding, heightWithPadding, mMapData_.voxHeight.greatest);
        mVoxTerrainMesh_ = meshObj;

        local item = _scene.createItem(meshObj);
        item.setRenderQueueGroup(30);
        item.setCastsShadows(false);
        return item;
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
                recreateChunk(chunkX, chunkY);
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
                recreateChunk(chunkX, chunkY);
            }
        }
    }

    function recreateChunk(chunkX, chunkY){
        local CHUNK_DEBUG_PADDING = 2;
        local parentNode = mParentNode_.createChildSceneNode();
        local targetIdx = chunkX << 4 | chunkY;
        local item = voxeliseChunk_(chunkX, chunkY);

        local width = (mMapData_.width / mChunkDivisions_);
        local height = (mMapData_.height / mChunkDivisions_);
        parentNode.setPosition((chunkX * -CHUNK_DEBUG_PADDING) + chunkX * width, 0, (chunkY * -CHUNK_DEBUG_PADDING) + -chunkY * height);

        parentNode.attachObject(item);
        parentNode.setScale(1, 1, 0.4);
        parentNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        if(mNodesForChunk_.rawin(targetIdx)){
            mNodesForChunk_[targetIdx].destroyNodeAndChildren();
        }
        mNodesForChunk_.rawset(targetIdx, parentNode);

    }

    function _getTouchedChunks(x, y, halfWidth, halfHeight){

    }

    function performSave(mapName){
        local fileHandler = TerrainChunkFileHandler("res://../../assets/maps/");
        //local fileHandler = TerrainChunkFileHandler("/tmp/");

        assert(mMapHeightDataCopy_ != null && mMapVoxTypeDataCopy_ != null);

        local saveMapData = ::TerrainChunkFileHandler.ParsedTerrainData();
        saveMapData.width = mMapData_.width;
        saveMapData.height = mMapData_.height;
        saveMapData.voxHeight = {"data": mMapHeightDataCopy_, "width": mMapData_.voxHeight.width, "height": mMapData_.voxHeight.height};
        saveMapData.voxType = {"data": mMapVoxTypeDataCopy_, "width": mMapData_.voxType.width, "height": mMapData_.voxType.height};

        fileHandler.writeMapData(mapName, saveMapData);
    }

};