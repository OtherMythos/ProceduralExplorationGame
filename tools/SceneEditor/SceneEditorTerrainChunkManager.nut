//Version of the TerrainChunkManager which also includes editor tools.

enum EditorTerrainType{
    HEIGHT,
    VOXEL,
    REGION
}

::SceneEditorTerrainChunkManager <- class extends ::TerrainChunkManager{

    mCurrentAction_ = null

    constructor(worldId, alterValues){
        base.constructor(worldId);

        mAlterValues_ = alterValues;
    }

    function drawValue_(x, y, width, height, values, editType){
        //Must be 0 so there's a centre voxel.
        assert(width % 2 == 1 && height % 2 == 1);

        local halfWidth = (width - 1) / 2;
        local halfHeight = (height - 1) / 2;

        local drawVal = {};

        for(local yy = 0; yy < height; yy++){
            for(local xx = 0; xx < width; xx++){
                local coordX = x + xx - halfWidth;
                local coordY = y + yy - halfHeight;

                local chunkX = (coordX / mChunkWidth_).tointeger();
                local chunkY = (coordY / mChunkHeight_).tointeger();
                local targetIdx = chunkX << 4 | chunkY;
                local targetX = coordX - (chunkX * mChunkWidth_);
                local targetY = coordY - (chunkY * mChunkHeight_);

                assert(mCurrentAction_ != null);

                local altitudeVal = null;
                if(editType == EditorTerrainType.HEIGHT){
                    altitudeVal = mMapData_.getAltitudeForCoord(coordX, coordY);
                }else if(editType == EditorTerrainType.VOXEL){
                    altitudeVal = mMapData_.getVoxelForCoord(coordX, coordY);
                }else if(editType == EditorTerrainType.REGION){
                    altitudeVal = mMapData_.getMetaForCoord(coordX, coordY);
                }
                if(altitudeVal == null) return;
                local writeValue = values[xx + yy * width];
                mCurrentAction_.populateForCoord(coordX, coordY, chunkX, chunkY, altitudeVal, writeValue);

                if(editType == EditorTerrainType.HEIGHT){
                    mMapData_.setAltitudeForCoord(coordX, coordY, writeValue);
                }else if(editType == EditorTerrainType.VOXEL){
                    mMapData_.setVoxelForCoord(coordX, coordY, writeValue);
                }else if(editType == EditorTerrainType.REGION){
                    mMapData_.setMetaForCoord(coordX, coordY, writeValue);
                }

                drawVal.rawset(targetIdx, true);
            }
        }

        foreach(c,i in drawVal){
            local chunkX = (c >> 4) & 0xF;
            local chunkY = c & 0xF;
            recreateChunkItem(chunkX, chunkY);
        }

    }

    function drawVoxTypeValues(x, y, width, height, values){
        drawValue_(x, y, width, height, values, EditorTerrainType.VOXEL);
    }

    function drawHeightValues(x, y, width, height, values){
        drawValue_(x, y, width, height, values, EditorTerrainType.HEIGHT);
    }

    function drawRegionValues(x, y, width, height, values){
        drawValue_(x, y, width, height, values, EditorTerrainType.REGION);
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

    function writeValueToFile_(filePath, editType){
        //TODO finish plugging these values in.
        //printf("Writing %s to file %s", altitude ? "terrain altitude" : "terrain blend", filePath);
        if(_system.exists(filePath)){
            _system.remove(filePath);
        }

        _system.createBlankFile(filePath);

        local outFile = File();
        outFile.open(filePath);
        local width = mMapData_.getWidth();
        local height = mMapData_.getHeight();
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local val = 0;
                if(editType == EditorTerrainType.HEIGHT){
                    val = mMapData_.getAltitudeForCoord(x, y);
                }else if(editType == EditorTerrainType.VOXEL){
                    val = mMapData_.getVoxelForCoord(x, y);
                }else if(editType == EditorTerrainType.REGION){
                    val = mMapData_.getMetaForCoord(x, y);
                }
                if(
                    x == 0 ||
                    y == 0 ||
                    x == width - 1 ||
                    y == height - 1
                ){
                    val = 0;
                }
                outFile.write(val.tostring() + ",");
            }
            outFile.write("\n");
        }
    }

    function performAltitudeSave(filePath){
        writeValueToFile_(filePath, EditorTerrainType.HEIGHT);
    }

    function performBlendSave(filePath){
        writeValueToFile_(filePath, EditorTerrainType.VOXEL);
    }

    function performMetaSave(filePath){
        writeValueToFile_(filePath, EditorTerrainType.REGION);
    }

};