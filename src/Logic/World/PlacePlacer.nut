//Class to assist inserting places into a world.
::PlacePlacer <- class{

    function placeIntoWorld(placeData, placeDefine, node, world, regionEntry, c=0){
        local placeFile = placeDefine.getPlaceFileName();
        local pos = Vec3(placeData.originX, 0, -placeData.originY);

            local insertNode = node.createChildSceneNode();
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

            //Check if place has a meta.json and parse it
            local metaPath = "res://build/assets/places/"+placeFile+"/meta.json";
            local shouldSpawnPlaceDescription = true;
            if(_system.exists(metaPath)){
                local metaTable = _system.readJSONAsTable(metaPath);
                if(metaTable.rawin("disablePlaceName") && metaTable.disablePlaceName){
                    shouldSpawnPlaceDescription = false;
                }
            }

            //Spawn the place description trigger
            if(shouldSpawnPlaceDescription){
                world.mEntityFactory_.constructPlaceDescriptionTrigger(pos, placeData.placeId);
            }

            local pId = placeData.placeId;
            if(pId == PlaceId.GARRITON || pId == PlaceId.GRAVEYARD){
                local blockerNode = node.createChildSceneNode();
                world.mEntityFactory_.constructEnemyCollisionBlocker(blockerNode, pos, placeDefine.mRadius * 1.5);
            }

            //Add the bounding box for debugging
            //TODO turn that into a developer profile.
            /*
            local debugNode = insertNode.createChildSceneNode();
            debugNode.setPosition(placeDefine.mCentre);
            debugNode.attachObject(_scene.createItem("lineBox"));
            debugNode.setScale(placeDefine.mHalf);
            */
    }

};