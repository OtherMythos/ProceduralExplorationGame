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
        local tileMeshes = mTileMeshes_;
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local val = v[x + y * width];
                if(val == false) continue;

                local mask = (val >> 4) & 0xF;

                local newNode = sceneNode.createChildSceneNode();
                newNode.setPosition(x * mWorldScaleSize_, 0, y * mWorldScaleSize_);

                local itemName = tileMeshes[0];
                local orientation = Quat();
                if(mask == 0){
                }else{
                    if(mask == 0x2) orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));
                    else if(mask == 0x4) orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));
                    else if(mask == 0x8) orientation = Quat(0, 1, 0, 0);
                    itemName = tileMeshes[1];

                    if((mask & (mask - 1)) != 0){
                        //Two bits are true meaning this is a corner.
                        itemName = tileMeshes[2];
                        if(mask == 0x3) orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));
                        if(mask == 0xA) orientation = Quat(0, 1, 0, 0);
                        if(mask == 0xC) orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));
                    }
                }

                local item = _gameCore.createVoxMeshItem(itemName);
                item.setRenderQueueGroup(30);
                newNode.attachObject(item);
                newNode.setOrientation(orientation);
            }
        }

        return sceneNode;
    }

}