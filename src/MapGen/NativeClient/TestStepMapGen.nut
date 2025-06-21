function processStep(inputData, mapData, data){
    local width = inputData.boxWidth;
    local height = inputData.boxHeight;

    data.placeData <- [
        {
            "originX": 100,
            "originY": 100,
            "originWrapped": (100 << 16) | 100,
            "placeId": 2,
            "region": 0
        }
    ];

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