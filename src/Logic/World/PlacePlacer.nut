//Class to assist inserting places into a world.
::PlacePlacer <- class{

    function placeIntoWorld(placeData, placeDefine, node, world, regionEntry, c=0){
        local placeFile = placeDefine.getPlaceFileName();
        local placeEntry = null;
        local pos = Vec3(placeData.originX, 0, -placeData.originY);
        //TODO eventually depreciate and remove the placement function logic.
        if(placeFile != null){
            local insertNode = node.createChildSceneNode();
            insertNode.setPosition(pos);
            local sceneFile = _scene.parseSceneFile("res://build/assets/places/"+placeFile+"/scene.avScene");
            local animData = _gameCore.insertParsedSceneFileGetAnimInfo(sceneFile, insertNode, world.getCollisionDetectionWorld());
            assert(animData == null);
            for(local i = 0; i < node.getNumChildren(); i++){
                local child = node.getChild(i);
                local childPos = child.getPositionVec3();
                childPos.y = world.getZForPos(childPos);
                child.setPosition(childPos);
            }
            regionEntry.pushFuncPlace(placeData.placeId, pos);
        }else{
            local placementFunction = placeDefine.getPlacementFunction();
            //NOTE replaced c with 0 here
            placeEntry = (placeDefine.getPlacementFunction())(world, world.mEntityFactory_, node, placeData, c);
            if(placeDefine.getRegionAppearFunction() != null){
                regionEntry.pushFuncPlace(placeData.placeId, pos);
            }
        }

        return placeEntry;
    }

};