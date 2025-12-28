::TileGridPlacer <- class{

    mTileMeshes_ = null;
    mWorldScaleSize_ = 1;

    constructor(meshes, worldScale=1){
        mTileMeshes_ = meshes;
        mWorldScaleSize_ = worldScale;
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

}