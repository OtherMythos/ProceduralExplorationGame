::TerrainChunkManager <- class{

    mMapData_ = null;
    mParentNode_ = null;
    mChunkDivisions_ = 1;
    mVoxTerrainMesh_ = null;

    mChunkData_ = null;

    PADDING = 1;

    constructor(){

    }

    function setup(parentNode, mapData, chunkDivisions){
        mMapData_ = mapData;
        mParentNode_ = parentNode;
        mChunkDivisions_ = chunkDivisions;
        mChunkData_ = {};

        constructDataForChunks();
        generateInitialChunks();
    }

    function constructDataForChunks(){
        //Padding so the ambient occlusion can work.
        local chunkWidth = (mMapData_.width / mChunkDivisions_);
        local chunkHeight = (mMapData_.height / mChunkDivisions_);
        local depth = mMapData_.voxHeight.greatest;

        local heightData = mMapData_.voxHeight.data;
        local colourData = mMapData_.voxType.data;

        local width = mMapData_.width;
        local height = mMapData_.height;

        local arraySize = (chunkWidth + PADDING * 2) * (chunkHeight + PADDING * 2) * depth;

        for(local y = 0; y < mChunkDivisions_; y++){
            for(local x = 0; x < mChunkDivisions_; x++){
                local posId = x << 4 | y;
                local newArray = array(arraySize, null);

                //Populate the array with the data.
                local startX = x * chunkWidth;
                local startY = y * chunkHeight;

                //Keep track with a simple count rather than calculating the value each iteration.
                local count = -1;
                for(local yy = startY - PADDING; yy < startY + chunkHeight + PADDING; yy++){
                    for(local xx = startX - PADDING; xx < startX + chunkWidth + PADDING; xx++){
                        count++;
                        if(xx < 0 || yy < 0 || xx >= width || yy >= height) continue;
                        local someData = heightData[xx + yy * width];
                        for(local i = 0; i < someData; i++){
                            local colourValue = colourData[xx + yy * width];
                            newArray[count + (i*(chunkWidth+2)*(chunkHeight+2))] = colourValue;
                        }
                    }
                }

                mChunkData_.rawset(posId, newArray);
            }
        }
    }

    function generateInitialChunks(){
        local CHUNK_DEBUG_PADDING = 2;
        for(local y = 0; y < mChunkDivisions_; y++){
            for(local x = 0; x < mChunkDivisions_; x++){
                local parentNode = mParentNode_.createChildSceneNode();
                local item = voxeliseChunk_(x, y);

                local width = (mMapData_.width / mChunkDivisions_);
                local height = (mMapData_.height / mChunkDivisions_);
                parentNode.setPosition((x * -CHUNK_DEBUG_PADDING) + x * width, 0, (y * -CHUNK_DEBUG_PADDING) + -y * height);

                parentNode.attachObject(item);
                parentNode.setScale(1, 1, 0.4);
                parentNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));
            }
        }
    }

    function voxeliseChunk_(chunkX, chunkY){
        local targetIdx = chunkX << 4 | chunkY;
        assert(mChunkData_.rawin(targetIdx));
        local targetChunkArray = mChunkData_.rawget(targetIdx);

        local widthWithPadding = (mMapData_.width / mChunkDivisions_) + PADDING * 2;
        local heightWithPadding = (mMapData_.height / mChunkDivisions_) + PADDING * 2;

        local vox = VoxToMesh(Timer(), 1 << 2, 0.4);
        //TODO get rid of this with the proper function to destory meshes.
        ::ExplorationCount++;
        local meshObj = vox.createMeshForVoxelData(format("terrainChunkManager%s%s", ::ExplorationCount.tostring(), targetIdx.tostring()), targetChunkArray, widthWithPadding, heightWithPadding, mMapData_.voxHeight.greatest);
        mVoxTerrainMesh_ = meshObj;

        local item = _scene.createItem(meshObj);
        item.setRenderQueueGroup(30);
        return item;
    }

};