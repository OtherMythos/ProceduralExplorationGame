function processStep(inputData, mapData, data){
    print("hello from the script step");
    print(data.test);

    mapData.test = 10;
    print(mapData.test);

    data.stepVal <- "Written from a step";
    data.valData <- [10, 20];
    //data.other <- thing();

    local width = inputData.boxWidth;
    local height = inputData.boxHeight;

    for(local y = 50; y < 50 + width; y++){
        for(local x = 50; x < 50 + height; x++){
            local val = mapData.voxValueForCoord(x, y);
            local voxValue = val & 0xFF;
            local writeVal = val & (0xFFFFFF00);
            writeVal = writeVal | 150;
            mapData.writeVoxValueForCoord(x, y, writeVal);
        }
    }

}