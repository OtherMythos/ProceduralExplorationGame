::DungeonGen <- class{

    constructor(){
    }

    function generate(data){
        _random.seed(data.seed);

        local outVals = array(data.width * data.height, false);

        //Generate the individual rooms into the array structure.
        if(data.dungeonType == ProceduralDungeonTypes.DUST_MITE_NEST){
            _setupCoridoors(outVals, data.width, data.height);
        }else{
            _setupRooms(outVals, data.width, data.height);
        }
        //Use a flood fill algorithm to collect combined rooms together.
        local floodRooms = _determineTotalRooms(outVals, data.width, data.height);
        local roomWeighted = _weightAndSortRooms(floodRooms);

        //_debugPrintData(outVals, data.width, data.height);
        local playerStart = _determinePlayerStart(floodRooms, outVals, data.width, data.height);

        _determineEdges(outVals, data.width, data.height);

        local resolvedTiles = _resolveTiles(outVals, data.width, data.height);

        local objectPositions = _generateObjectPositions(floodRooms);

        _random.seed(_system.time());

        local outData = {
            "width": data.width,
            "height": data.height,
            "rooms": floodRooms,
            "playerStart": playerStart,
            "vals": outVals,
            "dungeonType": data.dungeonType,
            "resolvedTiles": resolvedTiles,
            "weighted": roomWeighted,
            "seed": data.seed,
            "objectPositions": objectPositions
        };
        return outData;
    }

    function _debugPrintData(outVals, width, height){
        for(local y = 0; y < height; y++){
            local vals = "";
            for(local x = 0; x < width; x++){
                vals += (outVals[x + y * width]).tostring();
            }
            print(vals);
        }
    }

    function _determinePlayerStart(floodRooms, valData, width, height){
        local biggestRoom = -1;
        local biggestRoomIdx = -1;
        foreach(c,i in floodRooms){
            if(i.tileCount > biggestRoom){
                biggestRoomIdx = c;
                biggestRoom = i.tileCount;
            }
        }
        if(biggestRoomIdx == -1) return;

        //Check a few times to ensure the player has a big enough radius of tiles around them.
        local targetPos = null;
        for(local i = 0; i < 200; i++){
            local d = floodRooms[biggestRoomIdx].foundPoints;
            local testPos = d[_random.randIndex(d)];
            local result = _determineSizeAroundPosition(testPos, valData, width, height);
            if(result){
                targetPos = testPos;
                break;
            }
        }

        //TODO proper check incase this fails.
        assert(targetPos != null);

        return targetPos;
    }

    function _determineSizeAroundPosition(pos, valData, width, height){
        local x = pos & 0xFFFF
        local y = ((pos >> 16) & 0xFFFF);

        local radius = 1;
        for(local yy = y - radius; yy <= y + radius; yy++){
            for(local xx = x - radius; xx <= x + radius; xx++){
                if(xx < 0 || yy < 0 || xx >= width || yy >= height) return false;
                if(valData[xx + yy * width] == false) return false;
            }
        }

        return true;
    }

    function _setupCoridoors(d, w, h){
        local points = [];

        local padding = 6;
        for(local i = 0; i < 10; i++){
            local xx = _random.randInt(w - 6) + (6/2);
            local yy = _random.randInt(h - 6) + (6/2);
            points.append(Vec2(xx, yy));
        }

        for(local i = 1; i < points.len()-1; i++){
            local start = points[i - 1];
            local end = points[i];
            local linePoints = calculateLineBetweenPoints(start.x, start.y, end.x, end.y);
            foreach(p in linePoints){
                points.append(p);
            }
        }

        foreach(i in points){
            for(local y = -1; y <= 1; y++){
                for(local x = -1; x <= 1; x++){
                    local xx = x + i.x;
                    local yy = y + i.y;
                    if(xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                    d[xx + yy * w] = true;
                }
            }
        }
    }

    function calculateLineBetweenPoints(startX, startY, endX, endY){
        local outPoints = [];

        local deltaX = abs(endX.tointeger() - startX.tointeger());
        local deltaY = abs(endY.tointeger() - startY.tointeger());

        local pointX = startX.tointeger();
        local pointY = startY.tointeger();

        local horizontalStep = (startX < endX) ? 1 : -1;
        local verticalStep = (startY < endY) ? 1 : -1;

        local difference = deltaX - deltaY;
        while(true){
            local doubleDifference = 2 * difference;
            if(doubleDifference > -deltaY){
                difference -= deltaY;
                pointX += horizontalStep;
            }
            if(doubleDifference < deltaX){
                difference += deltaX;
                pointY += verticalStep;
            }

            if(pointX == endX && pointY == endY) break;

            outPoints.append(Vec2(pointX, pointY));
        }

        return outPoints;
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

                //TODO base this generation around a seed value.
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

    function _floodFillData(d, x, y, w, h, i, entry){
        entry.foundPoints.append((x & 0xFFFF) | ((y & 0xFFFF) << 16));
        d[x + y * w] = i;
        entry.tileCount++;

        //Note: It has to be true not just boolean check.
        //TODO do a mask of which tiles were true.
        local mask = 0;
        if(y > 0 && d[x + (y - 1) * w] == true) { _floodFillData(d, x, y - 1, w, h, i, entry); mask = mask | 0x1; }
        if(x > 0 && d[(x - 1) + y * w] == true) { _floodFillData(d, x - 1, y, w, h, i, entry); mask = mask | 0x2; }
        if(y < w-1 && d[(x + 1) + y * w] == true) { _floodFillData(d, x + 1, y, w, h, i, entry); mask = mask | 0x4; }
        if(y < h-1 && d[x + (y + 1) * w] == true) { _floodFillData(d, x, y + 1, w, h, i, entry); mask = mask | 0x8; }

        //d[x + y * w] = (i | (mask << 24));

        return true;
    }

    function _determineTotalRooms(d, w, h){
        local outData = [];

        local roomIndex = 0;
        for(local y = 0; y < h; y++){
            for(local x = 0; x < w; x++){
                if(d[x + y * w] == true){
                    local entry = {
                        "tileCount": 0,
                        "foundPoints": []
                    };
                    //A tile has been found, so start the flood fill.
                    _floodFillData(d, x, y, w, h, roomIndex, entry);

                    roomIndex++;
                    outData.append(entry);
                }
            }
        }

        return outData;
    }

    function _checkEdges(d, x, y, w, h){
        local idx = (x + y * w);
        if(idx < 0 || idx >= w*h) return false;
        return d[idx] == false;
    }
    function _determineEdges(d, w, h){
        for(local y = 0; y < h; y++){
            for(local x = 0; x < w; x++){
                local val = d[x + y * w];
                if(val == false) continue;
                local mask = 0;
                if(_checkEdges(d, x, (y - 1), w, h)) mask = mask | 0x1;
                if(_checkEdges(d, (x - 1), y, w, h)) mask = mask | 0x2;
                if(_checkEdges(d, (x + 1), y, w, h)) mask = mask | 0x4;
                if(_checkEdges(d, x, (y + 1), w, h)) mask = mask | 0x8;

                d[x + y * w] = (val & 0xF) | (mask << 4);
            }
        }
    }

    function _weightAndSortRooms(floodRooms){
        local totalTiles = 0;
        foreach(i in floodRooms){
            totalTiles += i.tileCount;
        }

        floodRooms.sort(function(a,b){
            if(a.tileCount<b.tileCount) return 1;
            else if(a.tileCount>b.tileCount) return -1;
            return 0;
        });

        local weighted = array(100, 0);
        local count = 0;
        local startIdx = floodRooms.len() > 100 ? 100 : floodRooms.len()-1;
        for(local i = startIdx; i >= 0; i--){
            local weightFloat = (floodRooms[i].tileCount.tofloat() / totalTiles) * 100;
            local weight = weightFloat >= 1.0 ? weightFloat.tointeger() : 1;
            for(local y = 0; y < weight; y++){
                weighted[count] = i;
                count++;
                //Drop out if the array is populated.
                if(count >= 100){
                    //Assuming we stop on the largest room.
                    assert(i == 0);
                    return weighted;
                }
            }
        }

        return weighted;
    }

    function _resolveTiles(data, width, height){
        local outVals = array(width * height, TileGridMasks.HOLE);

        foreach(c,i in data){
            if(i == false) continue;

            local mask = (i >> 4) & 0xF;

            local writeValue = 0x0;
            local orientation = 0x0;

            if(mask != 0){
                if(mask == 0x2) orientation = TileGridMasks.ROTATE_90;
                else if(mask == 0x4) orientation = TileGridMasks.ROTATE_180;
                else if(mask == 0x8) orientation = TileGridMasks.ROTATE_270;
                writeValue = 0x1;

                if((mask & (mask - 1)) != 0){
                    //Two bits are true meaning this is a corner.
                    if(mask == 0x3) orientation = TileGridMasks.ROTATE_90;
                    if(mask == 0xA) orientation = TileGridMasks.ROTATE_270;
                    if(mask == 0xC) orientation = TileGridMasks.ROTATE_180;
                    writeValue = 0x2;
                }
            }

            outVals[c] = (writeValue & 0xF) | (orientation);
        }

        return outVals;
    }

    function _generateObjectPositions(floodRooms){
        local objectPositions = {
            "enemies": [],
            "decorations": [],
            "chest": null,
            "ladderUp": null,
            "ladderDown": null
        };

        //Generate enemy positions (3 to 5 enemies)
        local enemyCount = 3 + _random.randInt(3);
        for(local i = 0; i < enemyCount; i++){
            objectPositions.enemies.append(_getRandomRoomPosition(floodRooms));
        }

        //Generate decoration positions (10 to 19 decorations)
        local decorationCount = 10 + _random.randInt(10);
        for(local i = 0; i < decorationCount; i++){
            local pos = _getRandomRoomPosition(floodRooms);
            local orientation = {
                "rotX": -PI/(_random.rand()*1.5+1),
                "rotY": _random.rand()*PI - PI/2,
                "isSkeletonBody": _random.randInt(3) == 0
            };
            objectPositions.decorations.append({
                "pos": pos,
                "orientation": orientation
            });
        }

        //Generate chest position
        objectPositions.chest = _getRandomRoomPosition(floodRooms);

        //Generate ladder up position
        objectPositions.ladderUp = _getRandomRoomPosition(floodRooms);

        //Generate ladder down position
        objectPositions.ladderDown = _getRandomRoomPosition(floodRooms);

        return objectPositions;
    }

    function _getRandomRoomPosition(floodRooms){
        local roomId = floodRooms.len() > 0 ? _random.randIndex(floodRooms) : 0;
        if(roomId >= floodRooms.len()) roomId = floodRooms.len() - 1;

        local targetRoom = floodRooms[roomId].foundPoints;
        if(targetRoom.len() == 0) return Vec3(0, 0, 0);

        local point = targetRoom[_random.randIndex(targetRoom)];
        return Vec3( (point & 0xFFFF), 0, (point >> 16) & 0xFFFF );
    }
};