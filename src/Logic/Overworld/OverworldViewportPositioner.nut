//Handles all viewport positioning logic for the overworld
//Manages camera placement, ray casting, edge detection, and optimal zoom calculations
::OverworldViewportPositioner <- {

    mWorld_ = null
    mParentSceneNode_ = null

    //Panel information for calculating camera zoom
    mPanelPosition_ = null
    mPanelSize_ = null

    //Edge voxel information for viewport collision checking
    mEdgeVoxels_ = null  //Table with keys: "top", "bottom", "left", "right" containing world space positions

    //Initialise the positioner with required references
    function initialise(world, parentSceneNode){
        mWorld_ = world;
        mParentSceneNode_ = parentSceneNode;
        mEdgeVoxels_ = null;
    }

    //Set the panel position and size for viewport calculations
    function setPanelBounds(pos, size){
        mPanelPosition_ = pos;
        mPanelSize_ = size;
    }

    //Calculate the optimal camera position for viewing the entire overworld
    //This is the main entry point - call this once to position the camera
    function calculateAndApplyOptimalCameraZoom_(camera, targetHeight){
        if(mPanelPosition_ == null || mPanelSize_ == null) return null;

        local aabb = calculateOverworldAABB_();
        if(aabb == null) return null;

        //Calculate and cache edge voxels for viewport collision checking
        calculateAndCacheEdgeVoxels_();

        //Calculate optimal zoom
        local cameraData = calculateOptimalCameraZoom_(camera, mPanelPosition_, mPanelSize_, aabb, targetHeight);

        return cameraData;
    }

    //Calculate the merged AABB of all regions in the world
    function calculateOverworldAABB_(){
        if(!mWorld_ || !mWorld_.mRegionEntries_) return null;

        local minBounds = null;
        local maxBounds = null;

        foreach(c,i in mWorld_.mRegionEntries_){
            local aabb = i.calculateAABB();
            if(aabb == null) continue;

            local centre = aabb.getCentre();
            local halfSize = aabb.getHalfSize();
            local min = centre - halfSize;
            local max = centre + halfSize;

            if(minBounds == null){
                minBounds = min.copy();
                maxBounds = max.copy();
            }else{
                if(min.x < minBounds.x) minBounds.x = min.x;
                if(min.y < minBounds.y) minBounds.y = min.y;
                if(min.z < minBounds.z) minBounds.z = min.z;

                if(max.x > maxBounds.x) maxBounds.x = max.x;
                if(max.y > maxBounds.y) maxBounds.y = max.y;
                if(max.z > maxBounds.z) maxBounds.z = max.z;
            }
        }

        if(minBounds == null || maxBounds == null){
            return null;
        }

        return {
            "min": minBounds,
            "max": maxBounds,
            "centre": (minBounds + maxBounds) * 0.5,
            "halfSize": (maxBounds - minBounds) * 0.5
        };
    }

    //Cast a ray from the given viewport coordinates and return the intersection with the ground
    //Uses a plane that extends far in front and behind the camera to catch all angles
    function castRayToGround_(camera, viewportX, viewportY){
        local ray = camera.getCameraToViewportRay(viewportX, viewportY);

        //Try multiple Y planes to find an intersection
        //Start with Y=0 (typical ground level)
        local testPlanes = [
            Plane(::Vec3_UNIT_Y, ::Vec3_ZERO),           //Y = 0
            Plane(::Vec3_UNIT_Y, Vec3(0, -100, 0)),     //Y = -100
            Plane(::Vec3_UNIT_Y, Vec3(0, 100, 0)),      //Y = 100
        ];

        foreach(plane in testPlanes){
            local dist = ray.intersects(plane);
            if(dist != false && dist > 0.0){
                return ray.getPoint(dist);
            }
        }

        return null;
    }

    //Get the four corners of the viewport and cast rays to determine the 2D visibility box
    //Returns {min: Vec3, max: Vec3} representing the XZ bounds of what's visible
    function calculateVisibilityBoxForPanel_(camera, panelPos, panelSize){
        //Normalise panel coordinates to viewport coordinates (0.0 to 1.0)
        local topLeftX = panelPos.x / ::drawable.x;
        local topLeftY = panelPos.y / ::drawable.y;
        local bottomRightX = (panelPos.x + panelSize.x) / ::drawable.x;
        local bottomRightY = (panelPos.y + panelSize.y) / ::drawable.y;

        //Clamp to valid viewport range
        topLeftX = topLeftX < 0.0 ? 0.0 : topLeftX > 1.0 ? 1.0 : topLeftX;
        topLeftY = topLeftY < 0.0 ? 0.0 : topLeftY > 1.0 ? 1.0 : topLeftY;
        bottomRightX = bottomRightX < 0.0 ? 0.0 : bottomRightX > 1.0 ? 1.0 : bottomRightX;
        bottomRightY = bottomRightY < 0.0 ? 0.0 : bottomRightY > 1.0 ? 1.0 : bottomRightY;

        //Cast rays from the four corners
        local topLeft = castRayToGround_(camera, topLeftX, topLeftY);
        local topRight = castRayToGround_(camera, bottomRightX, topLeftY);
        local bottomLeft = castRayToGround_(camera, topLeftX, bottomRightY);
        local bottomRight = castRayToGround_(camera, bottomRightX, bottomRightY);

        if(topLeft == null || topRight == null || bottomLeft == null || bottomRight == null){
            return null;
        }

        //Find the XZ bounds of these four points
        local minX = topLeft.x;
        local maxX = topLeft.x;
        local minZ = topLeft.z;
        local maxZ = topLeft.z;

        foreach(point in [topRight, bottomLeft, bottomRight]){
            if(point.x < minX) minX = point.x;
            if(point.x > maxX) maxX = point.x;
            if(point.z < minZ) minZ = point.z;
            if(point.z > maxZ) maxZ = point.z;
        }

        return {
            "min": Vec3(minX, 0, minZ),
            "max": Vec3(maxX, 0, maxZ)
        };
    }

    //Check if the visibility box contains the target AABB
    function visibilityBoxContainsAABB_(visBox, aabb){
        return visBox.min.x <= aabb.min.x &&
               visBox.min.z <= aabb.min.z &&
               visBox.max.x >= aabb.max.x &&
               visBox.max.z >= aabb.max.z;
    }

    //Helper function to check if a position has land (non-zero value)
    function hasLand(x, y){
        //TODO find a way to do this without the vec2.
        local native = ::currentNativeMapData;
        return native.getAltitudeForPos(Vec3(x, 0, y)) >= 100;
    }

    //Calculate and cache edge voxels for the four sides of the overworld
    //Returns a table with keys "top", "bottom", "left", "right" containing Vec3 world positions
    function calculateAndCacheEdgeVoxels_(){
        if(!mWorld_ || !mWorld_.mMapData_) return;

        local mapData = mWorld_.mMapData_;
        local width = mapData.width;
        local height = mapData.height;

        mEdgeVoxels_ = {};

        //Map coordinate system: top-left is (0, 600), bottom-right is (600, 0)
        //Convert grid indices to world coordinates: x stays same, y becomes (height - 1 - gridY)

        //Find top edge (largest y in world space, smallest gridY, scan from left to right)
        local topPos = null;
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local worldY = -(height - 1 - y);
                if(hasLand(x, worldY)){
                    topPos = Vec3(x, 0, worldY);
                    break;
                }
            }
            if(topPos != null) break;
        }
        mEdgeVoxels_.top <- topPos;

        //Find bottom edge (smallest y in world space, largest gridY, scan from left to right)
        local bottomPos = null;
        for(local y = height-1; y >= 0; y--){
            for(local x = 0; x < width; x++){
                local worldY = -(height - 1 - y);
                if(hasLand(x, worldY)){
                    bottomPos = Vec3(x, 0, worldY);
                    break;
                }
            }
            if(bottomPos != null) break;
        }
        mEdgeVoxels_.bottom <- bottomPos;

        //Find left edge (smallest x in world space, smallest x index, scan from top to bottom)
        local leftPos = null;
        for(local x = 0; x < width; x++){
            for(local y = 0; y < height; y++){
                local worldY = -(height - 1 - y);
                if(hasLand(x, worldY)){
                    leftPos = Vec3(x, 0, worldY);
                    break;
                }
            }
            if(leftPos != null) break;
        }
        mEdgeVoxels_.left <- leftPos;

        //Find right edge (largest x in world space, largest x index, scan from top to bottom)
        local rightPos = null;
        for(local x = width-1; x >= 0; x--){
            for(local y = 0; y < height; y++){
                local worldY = -(height - 1 - y);
                if(hasLand(x, worldY)){
                    rightPos = Vec3(x, 0, worldY);
                    break;
                }
            }
            if(rightPos != null) break;
        }
        mEdgeVoxels_.right <- rightPos;
    }

    //Check if the four edge voxels are all visible within the viewport
    function edgeVoxelsVisible_(camera, panelPos, panelSize){
        if(mEdgeVoxels_ == null) return false;

        //Calculate panel bounds in normalised viewport coordinates
        local panelMinX = panelPos.x / ::drawable.x;
        local panelMinY = panelPos.y / ::drawable.y;
        local panelMaxX = (panelPos.x + panelSize.x) / ::drawable.x;
        local panelMaxY = (panelPos.y + panelSize.y) / ::drawable.y;

        //Helper function to check if a world point is visible within panel bounds
        local isPointVisible = function(worldPos){
            if(worldPos == null) return false;

            //Get the screen-space position using the camera's projection
            local screenPos = camera.getWorldPosInWindow(worldPos);
            if(screenPos == null) return false;

            //screenPos is in normalised coordinates (-1 to 1), convert to viewport (0 to 1)
            local viewportX = (screenPos.x + 1.0) * 0.5;
            local viewportY = (-screenPos.y + 1.0) * 0.5;

            //Check if viewport position is within panel bounds
            return viewportX >= panelMinX && viewportX <= panelMaxX &&
                   viewportY >= panelMinY && viewportY <= panelMaxY;
        };

        //Check all four edges - return false if ANY edge is outside the bounds
        return isPointVisible(mEdgeVoxels_.top) &&
               isPointVisible(mEdgeVoxels_.bottom) &&
               isPointVisible(mEdgeVoxels_.left) &&
               isPointVisible(mEdgeVoxels_.right);
    }

    //Create debug cubes at each edge voxel position for visualisation
    function createDebugEdgeCubes_(){
        if(mEdgeVoxels_ == null) return;

        foreach(c,i in mEdgeVoxels_){
            local pos = i;

            if(pos == null) continue;

            //Create a small cube at this position
            local node = mParentSceneNode_.createChildSceneNode();
            node.attachObject(_scene.createItem("cube"));
            node.setPosition(pos);

            node.setScale(5, 5, 5);  //Make cubes visible at this scale
            if(c == "bottom"){
                node.setScale(5, 20, 5);
            }
        }
    }

    //Binary search to find a distance where the entire AABB fits in the viewport
    function binarySearchFitDistance_(camera, panelPos, panelSize, aabb, cameraX, lookAtPos, targetHeight, minDist, maxDist){
        local tolerance = 1.0;
        local iterations = 0;
        local maxIterations = 32;

        while((maxDist - minDist) > tolerance && iterations < maxIterations){
            iterations++;
            local midDist = (minDist + maxDist) * 0.5;

            //Calculate camera position
            local camPos = Vec3(cameraX, targetHeight, aabb.centre.z + midDist);

            //Temporarily set camera to test this position
            camera.getParentNode().setPosition(camPos);
            camera.lookAt(lookAtPos);

            //Check if the visibility box contains the entire AABB
            local visBox = calculateVisibilityBoxForPanel_(camera, panelPos, panelSize);
            if(visBox == null){
                minDist = midDist;
                continue;
            }

            if(visibilityBoxContainsAABB_(visBox, aabb)){
                //The AABB fits, try smaller distance (move closer)
                maxDist = midDist;
            }else{
                //The AABB doesn't fit, need larger distance (move further away)
                minDist = midDist;
            }
        }

        return (minDist + maxDist) * 0.5;
    }

    //Iteratively adjust camera position and look-at to centre the ray on landmass centre
    function iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, inOutCamPos, inOutLookAt, rayHitTolerance, stepSize){
        //Calculate the centre of the viewport in normalised coordinates
        local panelCentreX = (panelPos.x + panelSize.x * 0.5) / ::drawable.x;
        local panelCentreY = (panelPos.y + panelSize.y * 0.5) / ::drawable.y;

        //Clamp to valid viewport range
        panelCentreX = panelCentreX < 0.0 ? 0.0 : panelCentreX > 1.0 ? 1.0 : panelCentreX;
        panelCentreY = panelCentreY < 0.0 ? 0.0 : panelCentreY > 1.0 ? 1.0 : panelCentreY;

        local iterations = 0;
        local maxAdjustIterations = 64;
        local currentStepSize = stepSize;

        while(iterations < maxAdjustIterations){
            iterations++;

            //Set camera to current position
            camera.getParentNode().setPosition(inOutCamPos);
            camera.lookAt(inOutLookAt);

            //Cast a ray to the viewport centre
            local centreRayHit = castRayToGround_(camera, panelCentreX, panelCentreY);
            if(centreRayHit == null){
                break;
            }

            //Calculate distance from ray hit to landmass centre (in XZ plane)
            local hitDiff = centreRayHit - aabb.centre;
            local hitDistFromCentre = Vec2(hitDiff.x, hitDiff.z).length();

            if(hitDistFromCentre < rayHitTolerance){
                //Ray is hitting close enough to the centre
                break;
            }

            //Adjust position to move towards the hit point
            local adjustDir = hitDiff * -1.0;
            adjustDir.y = 0.0;  //Don't adjust height
            if(adjustDir.length() > 0.0){
                adjustDir = adjustDir * (1.0 / adjustDir.length());
            }

            local diff = adjustDir * currentStepSize;
            inOutCamPos = inOutCamPos + diff;
            inOutLookAt = inOutLookAt + diff;

            //Reduce step size as we get closer
            currentStepSize = currentStepSize * 0.95;
        }

        return {
            "cameraPos": inOutCamPos,
            "lookAtPos": inOutLookAt
        };
    }

    //Binary search to find a distance along a direction where the entire AABB fits in the viewport
    function binarySearchDistanceAlongDirection_(camera, panelPos, panelSize, aabb, lookAtPos, direction, startDist, maxDist, moveCloser){
        local minDist = startDist;
        local maxDist_local = maxDist;
        local tolerance = 1.0;
        local iterations = 0;
        local maxIterations = 32;

        while((maxDist_local - minDist) > tolerance && iterations < maxIterations){
            iterations++;
            local midDist = (minDist + maxDist_local) * 0.5;

            //Position camera at this distance along the direction
            local testCamPos = lookAtPos + direction * midDist;

            //Set camera to test position
            camera.getParentNode().setPosition(testCamPos);
            camera.lookAt(lookAtPos);

            //Check if the visibility box contains the entire AABB
            local visBox = calculateVisibilityBoxForPanel_(camera, panelPos, panelSize);
            if(visBox == null){
                if(moveCloser){
                    minDist = midDist;
                }else{
                    maxDist_local = midDist;
                }
                continue;
            }

            if(visibilityBoxContainsAABB_(visBox, aabb)){
                //The AABB fits
                if(moveCloser){
                    //Try moving closer
                    maxDist_local = midDist;
                }else{
                    //Try moving further away
                    minDist = midDist;
                }
            }else{
                //The AABB doesn't fit
                if(moveCloser){
                    //Need to move further away
                    minDist = midDist;
                }else{
                    //Need to move back in
                    maxDist_local = midDist;
                }
            }
        }

        return (minDist + maxDist_local) * 0.5;
    }

    //Binary search to find the optimal camera zoom distance
    //Stage 1: Fit entire overworld in view
    //Stage 2: Adjust Z to centre the ray on landmass centre
    //Returns the camera position and look-at point that fits the entire overworld
    function calculateOptimalCameraZoom_(camera, panelPos, panelSize, aabb, targetHeight){
        if(aabb == null) return null;

        //Camera X position aligned with centre of landmass
        local cameraX = aabb.centre.x;
        local lookAtPos = aabb.centre;

        //Stage 1: Find distance that fits entire AABB in view
        local fitDistance = binarySearchFitDistance_(camera, panelPos, panelSize, aabb, cameraX, lookAtPos, targetHeight, 1.0, 2000.0);
        local cameraPos = Vec3(cameraX, targetHeight, aabb.centre.z + fitDistance);
        local cameraLookAt = lookAtPos;

        //Stage 2: Adjust position to centre the ray
        local centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, cameraPos, cameraLookAt, 50.0, 100.0);
        cameraPos = centredResult.cameraPos;
        cameraLookAt = centredResult.lookAtPos;

        //Stage 3: Move camera closer while maintaining the angle
        local cameraDir = cameraPos - cameraLookAt;
        local cameraDist = cameraDir.length();
        if(cameraDist > 0.0){
            cameraDir = cameraDir * (1.0 / cameraDist);
        }else{
            return null;
        }

        local closestDist = binarySearchDistanceAlongDirection_(camera, panelPos, panelSize, aabb, cameraLookAt, cameraDir, 1.0, cameraDist, true);
        local finalCamPos = cameraLookAt + cameraDir * closestDist;

        //Stage 4: Adjust to re-centre the landmass in the viewport
        centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, finalCamPos, cameraLookAt, 50.0, 50.0);
        finalCamPos = centredResult.cameraPos;
        cameraLookAt = centredResult.lookAtPos;

        //Stage 5: Move camera back out until landmass fits viewport again
        local finalCameraDir = finalCamPos - cameraLookAt;
        local finalCameraDist = finalCameraDir.length();
        if(finalCameraDist > 0.0){
            finalCameraDir = finalCameraDir * (1.0 / finalCameraDist);
        }else{
            return null;
        }

        local farthestDist = binarySearchDistanceAlongDirection_(camera, panelPos, panelSize, aabb, cameraLookAt, finalCameraDir, finalCameraDist, finalCameraDist * 3.0, false);
        finalCamPos = cameraLookAt + finalCameraDir * farthestDist;

        //Stage 6: Adjust camera position to re-centre the landmass in the viewport
        centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, finalCamPos, cameraLookAt, 50.0, 100.0);
        finalCamPos = centredResult.cameraPos;
        cameraLookAt = centredResult.lookAtPos;

        finalCamPos.y += 200;

        //Iteratively move camera closer/further based on edge voxel visibility
        //until all four edges fit within the viewport bounds
        local stepSize = 300.0;
        local maxSteps = 32;

        for(local i = 0; i < maxSteps; i++){
            //Adjust camera to centre
            centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, finalCamPos, cameraLookAt, 50.0, 100.0);
            finalCamPos = centredResult.cameraPos;
            cameraLookAt = centredResult.lookAtPos;

            //Check if all edge voxels are visible within bounds
            camera.getParentNode().setPosition(finalCamPos);
            camera.lookAt(cameraLookAt);

            local edgesVisible = edgeVoxelsVisible_(camera, panelPos, panelSize);

            if(edgesVisible){
                //All edges are visible, try moving closer
                local direction = (finalCamPos - cameraLookAt).normalisedCopy();
                finalCamPos = finalCamPos - direction * stepSize;
            }else{
                //Edges are not all visible, move further away
                local direction = (finalCamPos - cameraLookAt).normalisedCopy();
                finalCamPos = finalCamPos + direction * stepSize;
            }

            //Reduce step size for next iteration
            stepSize = stepSize * 0.85;
        }

        //Final adjustment to centre
        centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, finalCamPos, cameraLookAt, 50.0, 100.0);
        finalCamPos = centredResult.cameraPos;
        cameraLookAt = centredResult.lookAtPos;

        //Calculate final position
        return {
            "cameraPos": finalCamPos,
            "lookAtPos": cameraLookAt,
            "distance": (finalCamPos - cameraLookAt).length()
        };
    }
};
