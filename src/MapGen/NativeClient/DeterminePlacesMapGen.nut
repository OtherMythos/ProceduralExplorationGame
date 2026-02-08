
::ScriptedMapGen <- class{

    mMapData_ = null;
    mReturnPlaces_ = null;
    mPlacesCollisionWorld_ = null;
    mData_ = null;

    constructor(mapData){
        mMapData_ = mapData;
    }

    function _determineRegionBySize(){
        local targetRegions = [];
        local min = mData_.minVox;
        local max = mData_.maxVox;
        for(local i = 0; i < mMapData_.getNumRegions(); i++){
            local total = mMapData_.getRegionTotal(i);
            if(total >= min && total <= max){
                local regionType = mMapData_.getRegionType(i);
                if(regionType == 0){
                    targetRegions.append(i);
                }
            }
        }
        return targetRegions;
    }

    function _determineRegionByType(){
        local targetRegions = [];
        local r = mData_.region;
        for(local i = 0; i < mMapData_.getNumRegions(); i++){
            local regionType = mMapData_.getRegionType(i);
            if(regionType == r){
                targetRegions.append(i);
            }
        }
        return targetRegions;
    }

    function _checkPlacementVoxelsAreLand(x, y){
        local halfX = mData_.halfX;
        local halfY = mData_.halfY;

        local foundRegion = null;
        for(local yy = y - halfY; yy < y + halfY; yy++){
            for(local xx = x - halfX; xx < x + halfX; xx++){
                //Optimistaion, remove the vec3 wrapper.
                //local pos = Vec3(xx, 0, -yy);
                if(mMapData_.getIsWaterForCoord(xx, yy)) return false;
            }
        }

        return true;
    }

    function roundAwayFromZero(v){
        return (v > 0 ? ceil(v) : floor(v)).tointeger();
    }

    function seedFindRandomPointInRegion(regionId){
        local total = mMapData_.getRegionTotalCoords(regionId);
        if(total == 0) return INVALID_WORLD_POINT;
        local randomIdx = mMapData_.randomIntMinMax(0, total - 1);
        return mMapData_.getRegionCoordForIdx(regionId, randomIdx);
    }

    function altitudeToZPos(altitude){
        local voxFloat = altitude.tofloat();
        local seaLevel = 100;
        local ABOVE_GROUND = 0xFF - seaLevel;
        local WORLD_DEPTH = 20;
        local PROCEDURAL_WORLD_UNIT_MULTIPLIER = 0.4;

        local altitude = (((voxFloat - seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
        local clampedAltitude = altitude < 0 ? 0 : altitude;

        return 0.5 + clampedAltitude * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
    }

    function _markRemovePlacedItems(originX, originY, halfX, halfY){
        for(local y = originY - halfY; y < originY + halfY; y++){
            for(local x = originX - halfX; x < originX + halfX; x++){
                local val = mMapData_.secondaryValueForCoord(x, y);

                val = val | (DO_NOT_PLACE_ITEMS_VOXEL_FLAG | DO_NOT_PLACE_RIVERS_VOXEL_FLAG);
                mMapData_.writeSecondaryValueForCoord(x, y, val);
            }
        }
    }

    function _averageOutGround(originX, originY, halfX, halfY, region){
        mMapData_.averageOutAltitudeRectangle(originX, originY, halfX, halfY, 5, region, 100);
    }

    function placeLocation(placeId, determineRegionFunction, checkPlacement){
        local placeData = ::Places[placeId];
        local targetRegions = determineRegionFunction();
        if(targetRegions.len() == 0) return;

        //Read the meta data for the place.
        local metaJsonPath = format("%s/%s/meta.json", ::basePlacesPath, placeData.mPlaceFileName);
        local placeMetaData = null;
        if(_mapGen.exists(metaJsonPath)){
            placeMetaData = _mapGen.readJSONAsTable(metaJsonPath);
        }

        if(placeData.mHalf != null){
            local halfX = placeData.mHalf[0];
            local halfY = placeData.mHalf[2];
            if(halfX != null && halfY != null){
                mData_.halfX = roundAwayFromZero(halfX);
                mData_.halfY = roundAwayFromZero(halfY);
            }
        }else{
            mData_.halfX = roundAwayFromZero(5);
            mData_.halfY = roundAwayFromZero(5);
        }
        local radius = placeData.mRadius == null ? 20 : placeData.mRadius;

        for(local i = 0; i < 100; i++){
            local targetIdx = mMapData_.randomIntMinMax(0, targetRegions.len()-1);
            local region = targetRegions[targetIdx];

            local point = seedFindRandomPointInRegion(region);
            if(point == INVALID_WORLD_POINT) continue;

            local originX = (point >> 16) & 0xFFFF;
            local originY = point & 0xFFFF;
            if(mPlacesCollisionWorld_.checkCollisionPoint(originX, originY, radius)){
                continue;
            }

            if(checkPlacement != null){
                if(!checkPlacement(originX, originY)){
                    continue;
                }
            }

            _markRemovePlacedItems(originX, originY, mData_.halfX, mData_.halfY);

            local shouldApplyVoxelHighlight = placeMetaData != null && placeMetaData.rawin("spawnEnemyCollisionBlocker") && placeMetaData.spawnEnemyCollisionBlocker;

            if(placeMetaData != null && placeMetaData.rawin("averageGroundRadius")){
                local radiusVal = placeMetaData.averageGroundRadius[0];
                local strengthVal = placeMetaData.averageGroundRadius[1];
                mMapData_.averageOutAltitudeRadius(originX, originY, radiusVal, strengthVal, region, 101);
                if(shouldApplyVoxelHighlight){
                    mMapData_.setVoxelHighlightGroupRadius(originX, originY, radiusVal, placeId);
                }
            }else{
                _averageOutGround(originX, originY, mData_.halfX, mData_.halfY, region);
                if(shouldApplyVoxelHighlight){
                    mMapData_.setVoxelHighlightGroupRectangle(originX, originY, mData_.halfX, mData_.halfY, placeId);
                }
            }

            mPlacesCollisionWorld_.addCollisionPoint(originX, originY, radius);

            local outputPlaceData = {
                "originX": originX,
                "originY": originY,
                "originWrapped": point,
                "placeId": placeId,
                "region": mMapData_.getRegionId(region)
            };

            if(placeMetaData != null && placeMetaData.rawin("terrainHoleRadius")){
                local radius = placeMetaData.terrainHoleRadius;
                for(local y = originY - radius; y < originY + radius; y++){
                    for(local x = originX - radius; x < originX + radius; x++){
                        local dx = x - originX;
                        local dy = y - originY;
                        if(dx * dx + dy * dy > radius * radius) continue;

                        local val = mMapData_.secondaryValueForCoord(x, y);
                        val = val | SKIP_DRAW_TERRAIN_VOXEL_FLAG;
                        mMapData_.writeSecondaryValueForCoord(x, y, val);
                    }
                }

                local holeIdx = mMapData_.holeCount;
                local holesPos = (originX << 16) | originY;
                mMapData_._set("holePos_" + holeIdx, holesPos);
                mMapData_._set("holeRadius_" + holeIdx, radius);
                mMapData_.holeCount = holeIdx + 1;
            }

            local tileOffsetX = 0;
            local tileOffsetY = 0;
            if(placeMetaData != null && placeMetaData.rawin("tileOffsetX")){
                tileOffsetX = placeMetaData.tileOffsetX;
            }
            if(placeMetaData != null && placeMetaData.rawin("tileOffsetY")){
                tileOffsetY = placeMetaData.tileOffsetY;
            }

            mMapData_.applyTerrainVoxelsForPlace(placeData.mPlaceFileName, ::basePlacesPath, originX - mData_.halfX + tileOffsetX, originY - mData_.halfY + tileOffsetY);

            mReturnPlaces_.append(outputPlaceData);
            return;
        }
    }

    function determinePlaces(){
        mReturnPlaces_ = [];
        mPlacesCollisionWorld_ = CollisionWorld(_COLLISION_WORLD_BRUTE_FORCE);

        mData_ = {
            "region": RegionType.DESERT,
            "minVox": 100,
            "maxVox": 1500,
            "radius": 8,

            "centreX": 0,
            "centreY": 0,
            "halfX": 5,
            "halfY": 5,
        };

        mMapData_.holeCount = 0;

        placeLocation(PlaceId.GATEWAY, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.PLAYER_SPAWN, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GARRITON, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.MORRINGTON, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.TEMPLE, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.GRAVEYARD, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.DEEP_HOLE, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.DUSTMITE_NEST, _determineRegionByType, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.MUSHROOM_FAIRY_RING, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.PILGRIM, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        mData_.region = RegionType.CHERRY_BLOSSOM_FOREST;
        placeLocation(PlaceId.CHERRY_BLOSSOM_ORB, _determineRegionByType, _checkPlacementVoxelsAreLand);
        mData_.region = RegionType.GEOTHERMAL_PLANES;
        mData_.radius = 40;
        for(local i = 0; i < 6; i++){
            placeLocation(PlaceId.GEOTHERMAL_GEYSER, _determineRegionByType, _checkPlacementVoxelsAreLand);
        }

        return mReturnPlaces_;
    }
}

function processStep(inputData, mapData, data){
    local gen = ::ScriptedMapGen(mapData);

    local placeData = gen.determinePlaces();
    data.placeData <- placeData;

    local gatewayPosition = 0;
    local playerStartPosition = 0;
    if(placeData.len() >= 1 && placeData[0].placeId == PlaceId.GATEWAY){
        gatewayPosition = placeData[0].originWrapped;
    }
    if(placeData.len() >= 2 && placeData[1].placeId == PlaceId.PLAYER_SPAWN){
        playerStartPosition = placeData[1].originWrapped;
    }
    mapData.gatewayPosition = gatewayPosition;
    mapData.playerStart = playerStartPosition;
}