::TileGridPlacer <- class{

    mTileMeshes_ = null;
    mTileCollisionData_ = null;
    mWorldScaleSize_ = 1;
    mResolutionScale_ = 1;

    constructor(meshes, worldScale=1, collisionData=null, resolutionScale=1){
        mTileMeshes_ = meshes;
        mWorldScaleSize_ = worldScale;
        mTileCollisionData_ = collisionData;
        mResolutionScale_ = resolutionScale;
    }

    function insertGridToScene(parentNode, voxVals, width, height){
        local sceneNode = parentNode.createChildSceneNode();

        //local voxData = array(width * height, null);
        local v = voxVals;
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local val = v[x + y * width];
                if(val & TileGridMasks.HOLE) continue;

                local mask = (val >> 4) & 0xF;

                local newNode = sceneNode.createChildSceneNode();
                newNode.setPosition(x * mWorldScaleSize_, 0, y * mWorldScaleSize_);

                populateNodeForTile(newNode, val & 0xF, val & 0x60);
            }
        }

        return sceneNode;
    }

    function populateNodeForTile(node, tile, tileRotation){
        if(tile < 0 || tile >= mTileMeshes_.len()) return null;
        local itemName = mTileMeshes_[tile];
        local orientation = Quat();

        {
            if(tileRotation == TileGridMasks.ROTATE_90)
            orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));

            else if(tileRotation == TileGridMasks.ROTATE_180)
            orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));

            else if(tileRotation == TileGridMasks.ROTATE_270)
            orientation = Quat(0, 1, 0, 0);
        }

        local item = _gameCore.createVoxMeshItem(itemName);
        node.attachObject(item);
        node.setOrientation(orientation);

        return item;
    }

    //Builds a high-resolution collision grid by sampling per-tile collision data and expanding it.
    //voxVals: the tile array from the map data (contains tile ID and rotation info)
    //width, height: dimensions of the tile grid
    //Returns a table with {grid, width, height, scale}
    function buildCollisionGrid(voxVals, width, height){
        if(mTileCollisionData_ == null || mResolutionScale_ <= 1){
            //No collision data or no scaling - return default grid
            local defaultGrid = array(width * height, false);
            return {grid = defaultGrid, width = width, height = height, scale = 1};
        }

        local expandedWidth = width * mResolutionScale_;
        local expandedHeight = height * mResolutionScale_;
        local expandedGrid = array(expandedWidth * expandedHeight, false);

        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local tileVal = voxVals[x + y * width];
                local tileId = tileVal & 0xF;
                local tileRotation = tileVal & 0x60;

                if(tileVal & TileGridMasks.HOLE){
                    //Skip holes
                    continue;
                }

                //Get collision data for this tile ID
                if(tileId >= 0 && tileId < mTileCollisionData_.len()){
                    local collisionArray = mTileCollisionData_[tileId];
                    if(collisionArray != null){
                        placeCollisionDataInGrid_(expandedGrid, expandedWidth, x, y, collisionArray, mResolutionScale_, tileRotation);
                    }
                }
            }
        }

        return {grid = expandedGrid, width = expandedWidth, height = expandedHeight, scale = mResolutionScale_};
    }

    //Places collision data for a single tile into the expanded grid, handling rotation.
    function placeCollisionDataInGrid_(expandedGrid, expandedWidth, tileX, tileY, collisionArray, resolutionScale, tileRotation){
        for(local dy = 0; dy < resolutionScale; dy++){
            for(local dx = 0; dx < resolutionScale; dx++){
                local sourceIdx = dx + dy * resolutionScale;
                local mirroredIdx = sourceIdx;

                //Apply rotation by mirroring the array
                if(tileRotation == TileGridMasks.ROTATE_90){
                    //90 degree: (x,y) -> (y, scale-1-x)
                    //mirroredIdx = dy + (resolutionScale - 1 - dx) * resolutionScale;
                    mirroredIdx = (resolutionScale - 1 - dy) + dx * resolutionScale;
                }else if(tileRotation == TileGridMasks.ROTATE_180){
                    //180 degree: (x,y) -> (scale-1-x, scale-1-y)
                    mirroredIdx = dy + (resolutionScale - 1 - dx) * resolutionScale;
                    //mirroredIdx = (resolutionScale - 1 - dx) + (resolutionScale - 1 - dy) * resolutionScale;
                    //return;
                }else if(tileRotation == TileGridMasks.ROTATE_270){
                    //270 degree: (x,y) -> (scale-1-y, x)
                    mirroredIdx = (resolutionScale - 1 - dx) + (resolutionScale - 1 - dy) * resolutionScale;
                }

                if(mirroredIdx < collisionArray.len()){
                    local expandedX = tileX * resolutionScale + dx;
                    local expandedY = tileY * resolutionScale + dy;
                    expandedGrid[expandedX + expandedY * expandedWidth] = collisionArray[mirroredIdx];
                }
            }
        }
    }

}