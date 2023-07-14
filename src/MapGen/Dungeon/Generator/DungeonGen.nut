::DungeonGen <- class{

    constructor(){
    }

    function generate(data){
        local outVals = array(data.width * data.height, false);

        //Generate the individual rooms into the array structure.
        _setupRooms(outVals, data.width, data.height);
        //Use a flood fill algorithm to collect combined rooms together.
        _determineTotalRooms(outVals, data.width, data.height);

        local outData = {
            "width": data.width,
            "height": data.height,
            "vals": outVals
        };
        return outData;
    }

    function _setupRooms(d, w, h){
        local maxEntry = w * h;
        local roomsToDraw = 50;

        local roomMaxWidth = 10;
        local roomMaxHeight = 10;
        local roomMinWidth = 3;
        local roomMinHeight = 3;

        //x, y, width, height
        local successRooms = [];

        for(local i = 0; i < roomsToDraw; i++){

            for(local attempt = 5; attempt >= 0; attempt--){
                local targetWidth = _random.randInt(roomMaxWidth - roomMinWidth);
                local targetHeight = _random.randInt(roomMaxHeight - roomMinHeight);
                targetWidth += roomMinWidth;
                targetHeight += roomMinHeight;

                local roomX = _random.randInt(w);
                local roomY = _random.randInt(h);

                local roomPadding = 1;
                //Add a 1x1 padding to the rooms. This way none of them can hug the x and y corners.
                roomX += roomPadding;
                roomY += roomPadding;


                local invalidRoom = false;
                foreach(r in successRooms){
                    if(roomX < r[0] + r[2] && roomX + targetWidth > r[0] &&
                        roomY < r[1] + r[3] && roomY + targetHeight > r[2]
                    ){
                        //Leaving this off for now as the rooms look much more interesting with the flood fill with this turned off.
                        //invalidRoom = true;
                        break;
                    }
                }
                if(roomX + targetWidth > w - roomPadding || roomY + targetHeight > h - roomPadding) invalidRoom = true;


                if(invalidRoom){
                    if(attempt == 0) print("Giving up on room.");
                    continue;
                }

                successRooms.append([roomX, roomY, targetWidth, targetHeight]);
                break;
            }

        }

        foreach(i in successRooms){
            local roomX = i[0];
            local roomY = i[1];
            local targetWidth = i[2];
            local targetHeight = i[3];

            for(local y = 0; y < targetHeight; y++){
                for(local x = 0; x < targetWidth; x++){
                    local yT = y + roomY;
                    local xT = x + roomX;
                    if(yT >= h) continue;
                    if(xT >= w) continue;

                    d[xT + yT * w] = true;
                }
            }
        }

    }

    function _floodFillData(d, x, y, w, i){
        d[x + y * w] = i;

        local ret = 1;
        //Note: It has to be true not just boolean check.
        if(d[x + (y - 1) * w] == true) ret += _floodFillData(d, x, y - 1, w, i);
        if(d[(x - 1) + y * w] == true) ret += _floodFillData(d, x - 1, y, w, i);
        if(d[(x + 1) + y * w] == true) ret += _floodFillData(d, x + 1, y, w, i);
        if(d[x + (y + 1) * w] == true) ret += _floodFillData(d, x, y + 1, w, i);

        return ret;
    }

    function _determineTotalRooms(d, w, h){
        local roomIndex = 0;
        for(local y = 0; y < h; y++){
            for(local x = 0; x < w; x++){
                if(d[x + y * w] == true){
                    //A tile has been found, so start the flood fill.
                    local roomTileCount = _floodFillData(d, x, y, w, roomIndex);

                    roomIndex++;
                }
            }
        }
    }
};