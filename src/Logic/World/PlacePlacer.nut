//Class to assist inserting places into a world.
::PlacePlacer <- class{

    function placeIntoWorld(placeData, placeDefine, node, world, regionEntry, c=0){
        local placeFile = placeDefine.getPlaceFileName();
        local placeEntry = null;
        local pos = Vec3(placeData.originX, 0, -placeData.originY);
        local insertNode = null;
        //TODO eventually depreciate and remove the placement function logic.
        if(placeFile != null){
            insertNode = node.createChildSceneNode();
            local insertPos = pos - placeDefine.mCentre;
            insertPos.y = 0;
            insertNode.setPosition(insertPos);
            local sceneFile = _scene.parseSceneFile("res://build/assets/places/"+placeFile+"/scene.avScene");
            local animData = _gameCore.insertParsedSceneFileGetAnimInfo(sceneFile, insertNode, world.getCollisionDetectionWorld());
            assert(animData == null);
            for(local i = 0; i < insertNode.getNumChildren(); i++){
                local child = insertNode.getChild(i);
                local originalPos = child.getPositionVec3();
                local worldPos = insertPos + originalPos;
                local newPos = originalPos;
                newPos.y = world.getZForPos(worldPos);
                child.setPosition(newPos);
            }
            regionEntry.pushFuncPlace(placeData.placeId, pos);

            //Add the bounding box for debugging
            //TODO turn that into a developer profile.
            /*
            local debugNode = insertNode.createChildSceneNode();
            debugNode.setPosition(placeDefine.mCentre);
            debugNode.attachObject(_scene.createItem("lineBox"));
            debugNode.setScale(placeDefine.mHalf);
            */
        }else{
            insertNode = node.createChildSceneNode();
            local placementFunction = placeDefine.getPlacementFunction();
            //NOTE replaced c with 0 here
            placeEntry = (placeDefine.getPlacementFunction())(world, world.mEntityFactory_, insertNode, placeData, c);
            if(placeDefine.getRegionAppearFunction() != null){
                regionEntry.pushFuncPlace(placeData.placeId, pos);
            }
        }

        return [placeEntry, insertNode];
    }

};