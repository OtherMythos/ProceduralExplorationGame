::DeterminePathNodesMapGen <- class{

    mMapData_ = null;
    mPlaceData_ = null;
    mPathSpawnNodes_ = null;

    constructor(mapData, placeData){
        mMapData_ = mapData;
        mPlaceData_ = placeData;
    }

    function determinePathNodes(){
        mPathSpawnNodes_ = [];

        if(mPlaceData_ == null || mPlaceData_.len() == 0){
            return mPathSpawnNodes_;
        }

        //Iterate through placed places and collect path spawn nodes
        foreach(idx, placeInfo in mPlaceData_){
            local placeId = placeInfo.placeId;
            local placeDef = ::Places[placeId];

            if(placeDef == null) continue;

            //Read the meta data for the place to get path settings
            local metaJsonPath = format("%s/%s/meta.json", ::basePlacesPath, placeDef.getPlaceFileName());
            local placeMetaData = null;
            if(_mapGen.exists(metaJsonPath)){
                placeMetaData = _mapGen.readJSONAsTable(metaJsonPath);
            }

            //Check for path metadata
            local pathSpawns = 0;
            local canReceivePaths = false;
            local connectivity = 0;

            if(placeMetaData != null){
                if(placeMetaData.rawin("pathSpawns")){
                    pathSpawns = placeMetaData.pathSpawns;
                }
                if(placeMetaData.rawin("canReceivePaths")){
                    canReceivePaths = placeMetaData.canReceivePaths;
                }
                if(placeMetaData.rawin("pathConnectivity")){
                    connectivity = placeMetaData.pathConnectivity;
                }
            }

            if(pathSpawns <= 0) continue;

            //This place should spawn paths
            local nodeData = {
                "placeId": placeId,
                "originX": placeInfo.originX,
                "originY": placeInfo.originY,
                "region": placeInfo.region,
                "pathSpawns": pathSpawns,
                "canReceivePaths": canReceivePaths,
                "connectivity": connectivity
            };

            mPathSpawnNodes_.append(nodeData);
        }

        return mPathSpawnNodes_;
    }

    function storePathNodesInMapData(){
        local nodes = determinePathNodes();

        //Store using numbered entry system (like holes)
        mMapData_.pathSpawnNodeCount = nodes.len();

        foreach(idx, node in nodes){
            mMapData_._set("pathNode_originX_" + idx, node.originX);
            mMapData_._set("pathNode_originY_" + idx, node.originY);
            mMapData_._set("pathNode_placeId_" + idx, node.placeId);
            mMapData_._set("pathNode_region_" + idx, node.region);
            mMapData_._set("pathNode_pathSpawns_" + idx, node.pathSpawns);
            mMapData_._set("pathNode_canReceive_" + idx, node.canReceivePaths ? 1 : 0);
            mMapData_._set("pathNode_connectivity_" + idx, node.connectivity);
        }
    }
}

function processStep(inputData, mapData, data){
    //Get placed places from map gen data
    local placeData = null;
    if(data.rawin("placeData")){
        placeData = data.placeData;
    }

    local pathNodeGen = ::DeterminePathNodesMapGen(mapData, placeData);
    pathNodeGen.storePathNodesInMapData();
}
