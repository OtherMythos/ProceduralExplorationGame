::TerrainChunkManager <- class{

    mWorldId_ = 0;
    mMapData_ = null;
    mParentNode_ = null;
    mChunkDivisions_ = 1;
    mUseThreading_ = false;

    mChunkColourData_ = null;
    mNodesForChunk_ = null;
    mItemsForChunk_ = null;

    mWidth_ = null;
    mHeight_ = null;
    mChunkWidth_ = null;
    mChunkHeight_ = null;

    PADDING = 1;
    PADDING_BOTH = null;

    constructor(worldId){
        mWorldId_ = worldId;
        PADDING_BOTH = PADDING * 2;
    }

    function setup(mapData, chunkDivisions){
        mMapData_ = mapData;
        mChunkDivisions_ = chunkDivisions;
        mChunkColourData_ = {};
        mNodesForChunk_ = {};
        mItemsForChunk_ = {};

        mWidth_ = mMapData_.getWidth();
        mHeight_ = mMapData_.getHeight();

        mChunkWidth_ = mWidth_ / mChunkDivisions_;
        mChunkHeight_ = mHeight_ / mChunkDivisions_;

        //constructDataForChunks();
    }

    function setupParentNode(parentNode){
        mParentNode_ = parentNode;
        generateInitialChunkNodes();
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
                        if(xx < 0 || yy < 0 || xx >= mWidth_ || yy >= height) continue;
                        local altitude = heightData[xx + yy * mWidth_];
                        for(local i = 0; i < altitude; i++){
                            newArray[count + (i*(mChunkWidth_+PADDING_BOTH)*(mChunkHeight_+PADDING_BOTH))] = colourData[xx + yy * mWidth_];
                        }
                    }
                }

                mChunkColourData_.rawset(posId, newArray);
            }
        }
    }

    function generateInitialChunkNodes(){
        for(local y = 0; y < mChunkDivisions_; y++){
            for(local x = 0; x < mChunkDivisions_; x++){
                //Assuming the items have already been generated.
                recreateChunkNode(x, y);
            }
        }
    }

    function generateInitialItems(){
        local total = (mChunkDivisions_ * mChunkDivisions_).tofloat();
        for(local y = 0; y < mChunkDivisions_; y++){
            for(local x = 0; x < mChunkDivisions_; x++){
                recreateChunkItem(x, y);
            }
        }
    }

    function voxeliseChunk_(chunkX, chunkY){
        local targetIdx = chunkX << 4 | chunkY;
        //assert(mChunkColourData_.rawin(targetIdx));
        //local targetChunkArray = mChunkColourData_.rawget(targetIdx);

        //local widthWithPadding = (mMapData_.width / mChunkDivisions_) + PADDING * 2;
        //local heightWithPadding = (mMapData_.height / mChunkDivisions_) + PADDING * 2;

        //print(mMapData_);
        local width = (mWidth_ / mChunkDivisions_);
        local height = (mHeight_ / mChunkDivisions_);
        local x = chunkX * width;
        local y = chunkY * height;

        //local vox = VoxToMesh(Timer(), 1 << 2);
        //local meshObj = vox.createMeshForVoxelData(format("terrainChunkManager-%i-%i", mWorldId_, targetIdx), targetChunkArray, widthWithPadding, heightWithPadding, mMapData_.voxHeight.greatest);
        //local meshObj = _gameCore.voxeliseMeshForVoxelData(format("terrainChunkManager-%i-%i", mWorldId_, targetIdx), targetChunkArray, widthWithPadding, heightWithPadding, mMapData_.voxHeight.greatest);
        local meshObj = mMapData_.voxeliseTerrainMeshForData(format("terrainChunkManager-%i-%i", mWorldId_, targetIdx), x, y, width, height);
        //local meshObj = _gameCore.voxeliseToTerrainMeshes(format("terrainChunkManager-%i-%i", mWorldId_, targetIdx), targetChunkArray, widthWithPadding, heightWithPadding, mMapData_.voxHeight.greatest);
        if(meshObj == null) return null;

        local item = _scene.createItem(meshObj);
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_TERRRAIN);
        item.setCastsShadows(false);
        _gameCore.writeFlagsToItem(item, 1);
        return item;
    }

    /**
     * Recreate the chunk item, destroying the old one.
     * If an older item exists it will be destroyed.
     * If that item was attached to a node recreateChunkNode will be triggered.
    */
    function recreateChunkItem(chunkX, chunkY){
        local targetIdx = chunkX << 4 | chunkY;

        //If a node exists then that must be cleared of the child, otherwise a conflict will occur.
        local nodeExists = mNodesForChunk_.rawin(targetIdx);
        local itemExists = mItemsForChunk_.rawin(targetIdx);
        local oldItemName = null;
        if(itemExists){
            //Get the item name before it's destroyed.
            oldItemName = mItemsForChunk_[targetIdx].getName();
        }
        if(nodeExists){
            local targetNode = mNodesForChunk_.rawget(targetIdx);
            assert(targetNode.getNumAttachedObjects() == 1);
            mNodesForChunk_[targetIdx].destroyNodeAndChildren();
            mNodesForChunk_.rawdelete(targetIdx);
        }
        if(itemExists){
            assert(oldItemName != null);
            _graphics.removeManualMesh(oldItemName);
        }

        local item = voxeliseChunk_(chunkX, chunkY);
        mItemsForChunk_.rawset(targetIdx, item);

        if(nodeExists){
            //Re-create the node with the new item.
            recreateChunkNode(chunkX, chunkY);
        }
    }

    /**
     * Recreate just the chunk node, assuming the item has already been generated.
     */
    function recreateChunkNode(chunkX, chunkY){
        local CHUNK_DEBUG_PADDING = 0;
        local targetIdx = chunkX << 4 | chunkY;

        if(mNodesForChunk_.rawin(targetIdx)){
            mNodesForChunk_[targetIdx].destroyNodeAndChildren();
        }

        local parentNode = mParentNode_.createChildSceneNode();

        local width = (mWidth_ / mChunkDivisions_);
        local height = (mHeight_ / mChunkDivisions_);
        local offset = 0.25;
        parentNode.setPosition((chunkX * -CHUNK_DEBUG_PADDING) + chunkX * width + offset, 0, (chunkY * -CHUNK_DEBUG_PADDING) + -chunkY * height - offset-offset);

        assert(mItemsForChunk_.rawin(targetIdx));
        local item = mItemsForChunk_.rawget(targetIdx);
        if(item != null){
            parentNode.attachObject(item);
        }
        parentNode.setScale(1, 1, VISITED_WORLD_UNIT_MULTIPLIER);
        parentNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        mNodesForChunk_.rawset(targetIdx, parentNode);
    }

    function recreateCompleteChunk(chunkX, chunkY){
        //Recreate item re-generates the item and node if it's missing.
        recreateChunkItem(chunkX, chunkY);
    }

    function _getTouchedChunks(x, y, halfWidth, halfHeight){

    }

    function writeValueToFile_(mapName, altitude){
        local filePath = "res://../../assets/maps/" + mapName + "/" + (altitude ? "terrain.txt" : "terrainBlend.txt");
        if(_system.exists(filePath)){
            _system.remove(filePath);
            _system.createBlankFile(filePath);
        }

        local outFile = File();
        outFile.open(filePath);
        for(local y = 0; y < mMapData_.getHeight(); y++){
            for(local x = 0; x < mMapData_.getWidth(); x++){
                local val = altitude ? mMapData_.getAltitudeForCoord(x, y) : mMapData_.getVoxelForCoord(x, y);
                outFile.write(val.tostring() + ",");
            }
            outFile.write("\n");
        }
    }

    function performSave(mapName){
        writeValueToFile_(mapName, true);
        writeValueToFile_(mapName, false);
    }

};