::DetermineSmallerRegionsMapGenStep <- class{

    mMapData_ = null;

    constructor(mapData){
        mMapData_ = mapData;
    }

    function isValidRegionForType(regionType, total, concavity){
        switch(regionType){
            case RegionType.HOT_SPRINGS:
                return total > 500 && total < 2000 && concavity >= 180;
            case RegionType.MUSHROOM_CLUSTER:
                return total > 300 && total < 800 && concavity >= 180;
            default:
                return false;
        }
    }

    function processStep(){
        local blacklistedRegions = [];

        //Collect all regions that have been assigned types already
        for(local i = 0; i < mMapData_.getNumRegions(); i++){
            local regionTypeVal = mMapData_.getRegionType(i);
            if(regionTypeVal != RegionType.NONE){
                blacklistedRegions.append(i);
            }
        }

        //Place small region types with specific criteria
        local smallRegionsToAdd = [
            RegionType.HOT_SPRINGS,
            RegionType.MUSHROOM_CLUSTER
        ];

        foreach(regionType in smallRegionsToAdd){
            local availableRegions = [];

            for(local i = 0; i < mMapData_.getNumRegions(); i++){
                //Check if this region is blacklisted
                local isBlacklisted = false;
                foreach(blacklistedId in blacklistedRegions){
                    if(blacklistedId == i){
                        isBlacklisted = true;
                        break;
                    }
                }
                if(isBlacklisted) continue;

                local regionTypeVal = mMapData_.getRegionType(i);
                if(regionTypeVal == RegionType.NONE){
                    local placeCount = mMapData_.getRegionPlaceCount(i);
                    if(placeCount > 0) continue;

                    local total = mMapData_.getRegionTotal(i);
                    local concavity = mMapData_.getRegionConcavity(i);

                    if(isValidRegionForType(regionType, total, concavity)){
                        availableRegions.append(i);
                    }
                }
            }

            if(availableRegions.len() > 0){
                local targetIdx = mMapData_.randomIntMinMax(0, availableRegions.len() - 1);
                local regionId = availableRegions[targetIdx];

                mMapData_.setRegionType(regionId, regionType);
                mMapData_.setRegionMeta(regionId, RegionMeta.MAIN_REGION);
                blacklistedRegions.append(regionId);
            }
        }

        return true;
    }
};

function processStep(inputData, mapData, data){
    local step = ::DetermineSmallerRegionsMapGenStep(mapData);
    return step.processStep();
}
