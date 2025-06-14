function processStep(mapData){
    print("hello from the script step");

    local width = mapData.width;
    local height = mapData.height;
    print(width);
    print(height);

    mapData.test = 10;

}