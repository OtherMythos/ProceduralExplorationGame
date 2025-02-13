/**
 * Map gen steps which are performed on the script side rather than forced into c++.
 */
::ScriptedMapGen <- class{

    mMapData_ = null;
    mNativeMapData_ = null;
    mReturnPlaces_ = null;
    mPlacesCollisionWorld_ = null;
    mData_ = null;

    constructor(mapData, nativeMapData){
        mMapData_ = mapData;
        mNativeMapData_ = nativeMapData;
    }

    function placeGateway(){
        local point = mMapData_.gatewayPosition;
        local region = ::MapGenHelpers.getRegionForPoint(mNativeMapData_, point);

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": PlaceId.GATEWAY,
            "region": region
        };

        mReturnPlaces_.append(placeData);
    }

    function _determineRegionBySize(){
        local targetRegions = [];
        local min = mData_.minVox;
        local max = mData_.maxVox;
        foreach(i in mMapData_.regionData){
            if(i.total >= min && i.total <= max){
                if(i.type == 0){
                    targetRegions.append(i);
                }
            }
        }
        return targetRegions;
    }

    function _determineRegionByType(){
        local targetRegions = [];
        local r = mData_.region;
        foreach(i in mMapData_.regionData){
            if(i.type == r){
                targetRegions.append(i);
            }
        }
        return targetRegions;
    }

    function _checkPlacementVoxelsAreLand(x, y){
        local w = mData_.floorWidth;
        local h = mData_.floorHeight;
        for(local yy = y - h; yy < y + h; yy++){
            for(local xx = x - w; xx < x + w; xx++){
                //Optimistaion, remove the vec3 wrapper.
                if(mNativeMapData_.getIsWaterForPos(Vec3(xx, 0, -yy))) return false;
            }
        }

        return true;
    }

    function _removePlacedItems(x, y){
        local totalWidth = mMapData_.width;
        local w = mData_.floorWidth;
        local h = mData_.floorHeight;
        for(local yy = y - h; yy < y + h; yy++){
            for(local xx = x - w; xx < x + w; xx++){
                mMapData_.placedItemsBuffer.seek((xx + yy * totalWidth) * 2);
                local val = mMapData_.placedItemsBuffer.readn('w');
                if(val != 0xFFFF){
                    mMapData_.placedItems[val] = null;
                }
            }
        }
    }

    function placeLocation(placeId, determineRegionFunction, checkPlacement){
        local targetRegions = determineRegionFunction();
        if(targetRegions.len() == 0) return;

        local radius = mData_.radius;

        for(local i = 0; i < 100; i++){
            local targetIdx = mNativeMapData_.randomIntMinMax(0, targetRegions.len()-1);
            local region = targetRegions[targetIdx];

            local point = ::MapGenHelpers.seedFindRandomPointInRegion(mNativeMapData_, region);
            if(point == INVALID_WORLD_POINT) continue;

            local originX = (point >> 16) & 0xFFFF;
            local originY = point & 0xFFFF;
            if(mPlacesCollisionWorld_.checkCollisionPoint(originX, originY, radius)) continue;

            if(checkPlacement != null){
                if(!checkPlacement(originX, originY)) continue;
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
            "region": RegionType.DESERT,
            "minVox": 100,
            "maxVox": 1500,
            "radius": 50,
            "floorWidth": 8,
            "floorHeight": 8,
        };

        placeGateway();
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.GOBLIN_CAMP, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.GARRITON, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.TEMPLE, _determineRegionBySize, _checkPlacementVoxelsAreLand);
        placeLocation(PlaceId.DUSTMITE_NEST, _determineRegionByType, _checkPlacementVoxelsAreLand);

        local retPlaces = mReturnPlaces_;
        mReturnPlaces_ = null;

        return retPlaces;
    }
}
