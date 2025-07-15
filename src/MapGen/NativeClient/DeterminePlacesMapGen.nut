
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

                val = val | DO_NOT_PLACE_ITEMS_VOXEL_FLAG;
                mMapData_.writeSecondaryValueForCoord(x, y, val);
            }
        }
    }

    function _averageOutGround(originX, originY, halfX, halfY, region){
        mMapData_.averageOutAltitudeRectangle(originX, originY, halfX, halfY, 5, region);
    }

    function placeLocation(placeId, determineRegionFunction, checkPlacement){
        local placeData = ::Places[placeId];
        local targetRegions = determineRegionFunction();
        if(targetRegions.len() == 0) return;

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

            if(placeId == PlaceId.DUSTMITE_NEST){
                mMapData_.averageOutAltitudeRadius(originX, originY, 10, 5, region);
            }else{
                _averageOutGround(originX, originY, mData_.halfX, mData_.halfY, region);
            }

            mPlacesCollisionWorld_.addCollisionPoint(originX, originY, radius);

            local placeData = {
                "originX": originX,
                "originY": originY,
                "originWrapped": point,
                "placeId": placeId,
                "region": mMapData_.getRegionId(region)
            };

            if(placeId == PlaceId.DUSTMITE_NEST){
                local radius = 5;
                for(local y = originY - radius; y < originY + radius; y++){
                    for(local x = originX - radius; x < originX + radius; x++){
                        local dx = x - originX;
                        local dy = y - originY;
                        if(dx * dx + dy * dy > radius * radius) continue;

                        /*
                        local val = mMapData_.voxValueForCoord(x, y);
                        local voxValue = val & 0xFF;

                        if(x == originX && y == originY){
                            placeData.forceZ <- altitudeToZPos(voxValue);
                        }
                        */

                        local val = mMapData_.secondaryValueForCoord(x, y);
                        val = val | SKIP_DRAW_TERRAIN_VOXEL_FLAG;
                        mMapData_.writeSecondaryValueForCoord(x, y, val);
                    }
                }

                mMapData_.holeX = originX;
                mMapData_.holeY = originY;
                mMapData_.holeRadius = radius;
            }
            if(placeId == PlaceId.GRAVEYARD){
                mMapData_.applyTerrainVoxelsForPlace("graveyard", ::basePlacesPath, originX - mData_.halfX, originY - mData_.halfY);
            }

            mReturnPlaces_.append(placeData);
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

        //TODO Ensure the gateway is placed at a position using a map gen step rather than just randomly.
        placeLocation(PlaceId.GATEWAY, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand)
        placeLocation(PlaceId.GARRITON, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.TEMPLE, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.GRAVEYARD, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.DUSTMITE_NEST, _determineRegionByType, _checkPlacementVoxelsAreLand);

        return mReturnPlaces_;
    }
}

function processStep(inputData, mapData, data){
    local gen = ::ScriptedMapGen(mapData);

    data.placeData <- gen.determinePlaces();
}