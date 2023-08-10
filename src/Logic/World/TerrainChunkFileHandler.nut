/**
 * A class to manage file read and writes for terrain chunks.
 */
::TerrainChunkFileHandler <- class{

    mMapsDir_ = null;

    ParsedTerrainData = class{
        constructor() {}
        voxHeight = null;
        voxType = null;

        width = null;
        height = null;
    };

    constructor(mapsDir="res://assets/maps/"){
        mMapsDir_ = mapsDir;
    }

    function parseFileToData_(file){
        local outArray = [];
        local height = 0;
        local width = null;
        local greatest = 0;
        while(!file.eof()){
            local line = file.getLine();
            local vals = split(line, ",");
            local len = vals.len();
            if(len == 0) break;

            if(width == null){
                width = len;
            }else{
                if(len != width) throw "Inconsistent line lengths in file";
            }

            foreach(i in vals){
                local intVal = i.tointeger();
                outArray.append(intVal);
                if(intVal > greatest){
                    greatest = intVal;
                }
            }
            height++;
        }


        return {
            "width": width,
            "height": height,
            "greatest": greatest,
            "data": outArray,
        }
    }

    function readMapData(mapName){
        local parsedData = [];
        foreach(i in [getTerrainHeightFile(mapName), getTerrainBlendFile(mapName)]){
            local file = File();
            file.open(i);
            local voxData = parseFileToData_(file);
            parsedData.append(voxData);
            file.close();
        }

        local outData = ParsedTerrainData();
        outData.voxHeight = parsedData[0];
        outData.voxType = parsedData[1];
        outData.width = parsedData[0].width;
        outData.height = parsedData[0].height;

        return outData;
    }

    function writeMapDataToPath_(mapPath, mapData){
        assert(mapData.data.len() == mapData.width * mapData.height);
        local file = File();
        printf("Saving terrain data to file %s", mapPath);
        file.open(mapPath);
        local width = mapData.width;
        for(local y = 0; y < mapData.height; y++){
            local outString = "";
            for(local x = 0; x < width; x++){
                outString += mapData.data[x + y * width].tostring();
                outString += ",";
            }
            outString += "\n";
            file.writeLine(outString);
        }

        file.close();
    }
    function writeMapData(mapName, terrainData){
        local paths = [getTerrainHeightFile(mapName), getTerrainBlendFile(mapName)];
        local data = [terrainData.voxHeight, terrainData.voxType];
        foreach(c,i in paths){
            if(_system.exists(i)){
                _system.remove(i);
            }
            _system.createBlankFile(i);
            writeMapDataToPath_(i, data[c]);
        }
    }

    function getTerrainHeightFile(mapName){
        return mMapsDir_ + mapName + "/terrain.txt";
    }
    function getTerrainBlendFile(mapName){
        return mMapsDir_ + mapName + "/terrainBlend.txt";
    }

};