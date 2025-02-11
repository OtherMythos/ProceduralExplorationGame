/**
 * Map gen steps which are performed on the script side rather than forced into c++.
 */
::ScriptedMapGen <- {

    function placeGateway(mapData, nativeMapData, retPlaces){
        local point = mapData.gatewayPosition;
        local region = ::MapGenHelpers.getRegionForPoint(nativeMapData, point);

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": PlaceId.GATEWAY,
            "region": region
        };

        retPlaces.append(placeData);
    }
    function placeGoblinCampsites(mapData, nativeMapData, retPlaces){
        local targetRegions = [];
        foreach(i in mapData.regionData){
            if(i.total >= 100 && i.total <= 1500){
                if(i.type == 0){
                    targetRegions.append(i);
                }
            }
        }
        if(targetRegions.len() == 0) return;

        local targetIdx = nativeMapData.randomIntMinMax(0, targetRegions.len()-1);
        local region = targetRegions[targetIdx];

        local point = ::MapGenHelpers.seedFindRandomPointInRegion(nativeMapData, region);
        if(point == INVALID_WORLD_POINT) return;

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": PlaceId.GOBLIN_CAMP,
            "region": region.id
        };

        retPlaces.append(placeData);
    }
    function placeGarriton(mapData, nativeMapData, retPlaces){
        local targetRegions = [];
        foreach(i in mapData.regionData){
            if(i.total >= 100 && i.total <= 1500){
                if(i.type == 0){
                    targetRegions.append(i);
                }
            }
        }
        if(targetRegions.len() == 0) return;

        local targetIdx = nativeMapData.randomIntMinMax(0, targetRegions.len()-1);
        local region = targetRegions[targetIdx];

        local point = ::MapGenHelpers.seedFindRandomPointInRegion(nativeMapData, region);
        if(point == INVALID_WORLD_POINT) return;

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": PlaceId.GARRITON,
            "region": region.id
        };

        retPlaces.append(placeData);
    }
    function placeTemple(mapData, nativeMapData, retPlaces){
        local targetRegions = [];
        foreach(i in mapData.regionData){
            if(i.total >= 100 && i.total <= 1500){
                if(i.type == 0){
                    targetRegions.append(i);
                }
            }
        }
        if(targetRegions.len() == 0) return;

        local targetIdx = nativeMapData.randomIntMinMax(0, targetRegions.len()-1);
        local region = targetRegions[targetIdx];

        local point = ::MapGenHelpers.seedFindRandomPointInRegion(nativeMapData, region);
        if(point == INVALID_WORLD_POINT) return;

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": PlaceId.TEMPLE,
            "region": region.id
        };

        retPlaces.append(placeData);
    }
    function placeDustmiteNests(mapData, nativeMapData, retPlaces){
        local targetRegions = [];
        foreach(i in mapData.regionData){
            if(i.type == RegionType.DESERT){
                targetRegions.append(i);
            }
        }
        if(targetRegions.len() == 0) return;

        local targetIdx = nativeMapData.randomIntMinMax(0, targetRegions.len()-1);
        local region = targetRegions[targetIdx];

        local point = ::MapGenHelpers.seedFindRandomPointInRegion(nativeMapData, region);
        if(point == INVALID_WORLD_POINT) return;

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": PlaceId.DUSTMITE_NEST,
            "region": region.id
        };

        retPlaces.append(placeData);
    }
    function determinePlaces(mapData, nativeMapData, inputMapData){
        local retPlaces = [];

        placeGateway(mapData, nativeMapData, retPlaces);
        placeGoblinCampsites(mapData, nativeMapData, retPlaces);
        placeGoblinCampsites(mapData, nativeMapData, retPlaces);
        placeGoblinCampsites(mapData, nativeMapData, retPlaces);
        placeGoblinCampsites(mapData, nativeMapData, retPlaces);
        placeGarriton(mapData, nativeMapData, retPlaces);
        placeTemple(mapData, nativeMapData, retPlaces);

        placeDustmiteNests(mapData, nativeMapData, retPlaces);

        return retPlaces;
    }
}
