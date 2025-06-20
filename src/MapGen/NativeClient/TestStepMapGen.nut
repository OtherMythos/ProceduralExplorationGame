
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

    function _checkPlacementVoxelsAreLand(x, y){
        local halfX = mData_.halfX;
        local halfY = mData_.halfY;

        local foundRegion = null;
        for(local yy = y - halfX; yy < y + halfY; yy++){
            for(local xx = x - halfX; xx < x + halfX; xx++){
                //Optimistaion, remove the vec3 wrapper.
                local pos = Vec3(xx, 0, -yy);
                if(mNativeMapData_.getIsWaterForPos(pos)) return false;
            }
        }

        return true;
    }

    function roundAwayFromZero(v){
        return (v > 0 ? ceil(v) : floor(v)).tointeger();
    }

    function placeLocation(placeId, determineRegionFunction, checkPlacement){
        //local placeData = ::Places[placeId];
        local targetRegions = determineRegionFunction();
        if(targetRegions.len() == 0) return;

        //TODO finish this
        return;

        if(placeData.mHalf != null){
            mData_.halfX = roundAwayFromZero(placeData.mHalf.x);
            mData_.halfY = roundAwayFromZero(placeData.mHalf.z);
        }
        local radius = placeData.mRadius;

        for(local i = 0; i < 100; i++){
            local targetIdx = mNativeMapData_.randomIntMinMax(0, targetRegions.len()-1);
            local region = targetRegions[targetIdx];

            local point = ::MapGenHelpers.seedFindRandomPointInRegion(mNativeMapData_, region);
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

            _removePlacedItems(originX, originY);

            mPlacesCollisionWorld_.addCollisionPoint(originX, originY, radius);

            local placeData = {
                "originX": originX,
                "originY": originY,
                "originWrapped": point,
                "placeId": placeId,
                "region": region.id
            };

            mReturnPlaces_.append(placeData);
            return;
        }
    }

    function determinePlaces(){
        mReturnPlaces_ = [];
        mPlacesCollisionWorld_ = CollisionWorld(_COLLISION_WORLD_BRUTE_FORCE);

        mData_ = {
            //"region": RegionType.DESERT,
            "region": 4,
            "minVox": 100,
            "maxVox": 1500,
            "radius": 8,

            "centreX": 0,
            "centreY": 0,
            "halfX": 5,
            "halfY": 5,
        };

        placeLocation(3, _determineRegionBySize, _checkPlacementVoxelsAreLand)

        return mReturnPlaces_;
    }
}

function processStep(inputData, mapData, data){
    local gen = ::ScriptedMapGen(mapData);

    data.placeData <- gen.determinePlaces();
}