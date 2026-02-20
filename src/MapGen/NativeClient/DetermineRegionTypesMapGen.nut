::DetermineRegionsMapGenStep <- class{

    mMapData_ = null;

    constructor(mapData){
        mMapData_ = mapData;
    }

    function processStep(){
        local freeRegions = [];
        //Mark regions 0, 1, 2 as free for assignment
        freeRegions.append(0);
        freeRegions.append(1);
        freeRegions.append(2);

        local blacklistedRegions = [];

        //Place large region types
        local regionsToAdd = [
            RegionType.CHERRY_BLOSSOM_FOREST,
            RegionType.WORM_FIELDS,
            RegionType.GEOTHERMAL_PLANES
        ];

        foreach(regionType in regionsToAdd){
            if(freeRegions.len() == 0) break;

            local targetIdx = mMapData_.randomIntMinMax(0, freeRegions.len() - 1);
            local regionId = freeRegions[targetIdx];

            //Set the region type
            mMapData_.setRegionType(regionId, regionType);

            //Mark certain types as expandable
            if(regionType == RegionType.DESERT || regionType == RegionType.MUSHROOM_FOREST || regionType == RegionType.GEOTHERMAL_PLANES || regionType == RegionType.WORM_FIELDS){
                mMapData_.setRegionMeta(regionId, RegionMeta.EXPANDABLE);
            }

            blacklistedRegions.append(regionId);
            freeRegions.remove(targetIdx);
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
                    local total = mMapData_.getRegionTotal(i);
                    local concavity = mMapData_.getRegionConcavity(i);

                    if(regionType == RegionType.HOT_SPRINGS){
                        if(total > 500 && total < 2000 && concavity >= 180){
                            availableRegions.append(i);
                        }
                    }else{
                        if(total > 300 && total < 800 && concavity >= 180){
                            availableRegions.append(i);
                        }
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
    local step = ::DetermineRegionsMapGenStep(mapData);
    return step.processStep();
}
