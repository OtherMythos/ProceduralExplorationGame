function processStep(mapData){
    print("hello from the script step");

    mapData.test = 10;
    print(mapData.test);

    for(local y = 50; y < 60; y++){
        for(local x = 50; x < 60; x++){
            local val = mapData.voxValueForCoord(x, y);
            local voxValue = val & 0xFF;
            local writeVal = val & (0xFFFFFF00);
            writeVal = writeVal | 110;
            mapData.writeVoxValueForCoord(x, y, writeVal);
        }
    }

}