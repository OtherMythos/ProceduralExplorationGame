::DetermineRegionsMapGenStep <- class{

    mMapData_ = null;

    constructor(mapData){
        mMapData_ = mapData;
    }

    function shouldMarkExpandable(regionType){
        switch(regionType){
            case RegionType.DESERT:
            case RegionType.MUSHROOM_FOREST:
            case RegionType.GEOTHERMAL_PLANES:
            case RegionType.WORM_FIELDS:
            case RegionType.SWAMP:
                return true;
            default:
                return false;
        }
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

    function pickRandomRegionTypes(count){
        local allRegionTypes = [
            RegionType.CHERRY_BLOSSOM_FOREST,
            RegionType.DESERT,
            RegionType.SWAMP,
            RegionType.GEOTHERMAL_PLANES,
            RegionType.MUSHROOM_FOREST,
            RegionType.WORM_FIELDS
        ];

        local selectedTypes = [];
        local usedIndices = [];

        for(local i = 0; i < count && i < allRegionTypes.len(); i++){
            local randomIdx = mMapData_.randomIntMinMax(0, allRegionTypes.len() - 1);

            //Ensure we don't pick duplicates
            local isUsed = false;
            foreach(usedIdx in usedIndices){
                if(usedIdx == randomIdx){
                    isUsed = true;
                    break;
                }
            }

            if(!isUsed){
                selectedTypes.append(allRegionTypes[randomIdx]);
                usedIndices.append(randomIdx);
            }else{
                i--; //Retry this iteration
            }
        }

        return selectedTypes;
    }

    function processStep(){
        local freeRegions = [];
        //Mark regions 0, 1, 2 as free for assignment
        freeRegions.append(0);
        freeRegions.append(1);
        freeRegions.append(2);

        local blacklistedRegions = [];

        //Place large region types - pick 3 random types from available biomes
        local regionsToAdd = pickRandomRegionTypes(3);

        foreach(regionType in regionsToAdd){
            if(freeRegions.len() == 0) break;

            local targetIdx = mMapData_.randomIntMinMax(0, freeRegions.len() - 1);
            local regionId = freeRegions[targetIdx];

            //Set the region type
            mMapData_.setRegionType(regionId, regionType);

            //Mark certain types as expandable
            if(shouldMarkExpandable(regionType)){
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
    local step = ::DetermineRegionsMapGenStep(mapData);
    return step.processStep();
}
