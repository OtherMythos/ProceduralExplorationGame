//A class to manage writing tile data to a file.
::TileDataWriter <- class{

    constructor(){

    }

    function performSave(mapName, data, width){
        local filePath = "res://../../assets/maps/" + mapName + "/tileData.txt";
        if(_system.exists(filePath)){
            _system.remove(filePath);
        }
        _system.createBlankFile(filePath);
        writeToFile(filePath, data, width);
    }

    function writeToFile(path, data, width){
        printf("Writing tile data file to path '%s'", path);

        local outFile = File();
        outFile.open(path);

        local widthCount = width;
        foreach(i in data){
            outFile.write(i.tostring() + ",");
            widthCount--;
            if(widthCount == 0){
                outFile.write("\n");
                widthCount = width;
            }
        }
    }

};