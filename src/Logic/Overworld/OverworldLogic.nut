enum OverworldStates{
    NONE,

    ZOOMED_OUT,
    ZOOMED_IN,
    REGION_UNLOCK,
    TITLE_SCREEN,

    MAX
};

::OverworldLogic <- {

    mWorld_ = null
    mParentSceneNode_ = null
    mCompositor_ = null
    mRenderableSize_ = null
    mStateMachine_ = null

    mOverworldRegionMeta_ = null

    mCurrentCameraPosition_ = null
    mCurrentCameraLookAt_ = null

    mActiveCount_ = 0

    //Panel information for calculating camera zoom
    mPanelPosition_ = null
    mPanelSize_ = null

    //Edge voxel information for viewport collision checking
    mEdgeVoxels_ = null  //Table with keys: "top", "bottom", "left", "right" containing world space positions

    function loadMeta(){
        local regionMeta = _system.readJSONAsTable("res://build/assets/overworld/overworld/meta.json");
        mOverworldRegionMeta_ = regionMeta;
    }

    function requestSetup(){
        local active = isActive();
        mActiveCount_++;
        if(active) return;

        setup_();
    }

    function requestShutdown(){
        mActiveCount_--;
        if(isActive()) return;

        shutdown_();
    }

    function requestState(state){
        mStateMachine_.setState(state);
    }

    function isActive(){
        return mActiveCount_ > 0;
    }

    function setup_(){

        print("Setting up overworld");

        mStateMachine_ = OverworldStateMachine(this);

        mParentSceneNode_ = _scene.getRootSceneNode().createChildSceneNode();
        /*
        local node = mParentSceneNode_.createChildSceneNode();
        local item = _gameCore.createVoxMeshItem("playerHead.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        node.attachObject(item);
        */
        //node.setScale(0.1, 0.1, 0.1);

        mRenderableSize_ = ::drawable * ::resolutionMult;
        setupCompositor_();

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        camera.setFarClipDistance(4000);

        local preparer = ::OverworldPreparer();
        mWorld_ = ::Overworld(0, preparer);
        //local dummy = _gameCore.getDummyMapGen();
        local dummy = _gameCore.loadOverworld("overworld");
        local nativeData = dummy.data;
        local data = nativeData.explorationMapDataToTable();
        data.rawset("placeData", []);
        data.playerStart <- 0;
        mWorld_.setup();
        mWorld_.resetSession(data, nativeData);

        //Calculate and cache edge voxels for viewport collision checking
        calculateAndCacheEdgeVoxels_();
        //createDebugEdgeCubes_();
    }

    function getCompositorDatablock(){
        return ::CompositorManager.getDatablockForCompositor(mCompositor_);
    }

    function setRenderableSize(pos, size){
        mRenderableSize_ = size;
        mPanelPosition_ = pos;
        mPanelSize_ = size;
        if(!isActive()) return;

        local datablock = getCompositorDatablock();
        {
            local calcWidth = size.x / ::drawable.x;
            local calcHeight = size.y / ::drawable.y;

            local calcX = pos.x / ::drawable.x;
            local calcY = pos.y / ::drawable.y;

            local mAnimMatrix_ = [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ];

            mAnimMatrix_[0] = calcWidth;
            mAnimMatrix_[5] = calcHeight;
            mAnimMatrix_[3] = calcX;
            mAnimMatrix_[7] = calcY;
            datablock.setEnableAnimationMatrix(0, true);
            datablock.setAnimationMatrix(0, mAnimMatrix_);
        }
    }

    function setMapPositionFromPress(pos){
        if(pos == null) return;
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        local ray = camera.getCameraToViewportRay(pos.x, pos.y);
        local testPlane = Plane(::Vec3_UNIT_Y, ::Vec3_ZERO)
        local dist = ray.intersects(testPlane);
        if(dist != false){
            local worldPoint = ray.getPoint(dist);
            mWorld_.mCameraPosition_ = worldPoint;
        }
    }

    function unlockRegion(regionId){
        ::Base.mPlayerStats.incrementRegionIdDiscovery(regionId);
        requestState(OverworldStates.REGION_UNLOCK);

        ::SaveManager.writeSaveAtPath("user://" + ::Base.mPlayerStats.getSaveSlot(), ::Base.mPlayerStats.getSaveData());
    }

    function setTitleScreenMode(){
        requestState(OverworldStates.TITLE_SCREEN);
    }

    function calculateOverworldCentre_(){
        //Calculate the merged AABB of all regions to find the center
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
            return Vec3(0.0, 0.0, 0.0);
        }

        return (minBounds + maxBounds) * 0.5;
    }

    function shutdownCompositor_(){
        ::CompositorManager.destroyCompositorWorkspace(mCompositor_);
    }

    function setupCompositor_(){
        {
            local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
            local size = ::drawable * ::resolutionMult;
            _gameCore.setupCompositorDefs(size.x.tointeger(), size.y.tointeger());
        }
        mCompositor_ = ::CompositorManager.createCompositorWorkspace("renderWindowWorkspaceGameplayTexture", mRenderableSize_, CompositorSceneType.OVERWORLD, true, false);
    }

    function getCurrentSelectedRegion(){
        return mWorld_.getCurrentSelectedRegion();
    }

    function update(){
        if(!isActive()) return;
        mWorld_.update();
        mStateMachine_.update();
    }

    function shutdown_(){
        mParentSceneNode_.destroyNodeAndChildren();
        mWorld_.shutdown();
        shutdownCompositor_()

        print("Shutting down overworld");
    }

    function applyCameraDelta(delta){
        mStateMachine_.notify(delta);
    }

    function applyZoomDelta(delta){
        mWorld_.applyZoomDelta(delta);
    }

    //Calculate the optimal camera position for viewing the entire overworld
    //This should be called once the world is loaded to establish the base camera position
    function calculateAndApplyOptimalCameraZoom_(){
        if(!isActive()) return;
        if(mPanelPosition_ == null || mPanelSize_ == null) return;

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        local aabb = calculateOverworldAABB_();
        if(aabb == null) return;

        //Target height for the camera (adjust as needed)
        local targetHeight = 700.0;

        //Calculate optimal zoom
        local cameraData = calculateOptimalCameraZoom_(camera, mPanelPosition_, mPanelSize_, aabb, targetHeight);
        if(cameraData != null){
            mCurrentCameraPosition_ = cameraData.cameraPos;
            mCurrentCameraLookAt_ = cameraData.lookAtPos;

        }
    }

    function calculateOverworldAABB_(){
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

        local mapData = mWorld_.mMapData_;
        local width = mapData.width;
        local height = mapData.height;
        //local vals = mapData.vals;

        //if(x < 0 || x >= width || y < 0 || y >= height) return false;
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

        //Calculate panel bounds in normalized viewport coordinates
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

            //screenPos is in normalized coordinates (-1 to 1), convert to viewport (0 to 1)
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

    //Create debug cubes at each edge voxel position for visualization
    function createDebugEdgeCubes_(){
        if(mEdgeVoxels_ == null) return;

        foreach(c,i in mEdgeVoxels_){
        //for(local i = 0; i < edgeLabels.len(); i++){
            //local label = edgeLabels[i];
            local pos = i;

            if(pos == null) continue;

            //Create a small cube at this position
            //local nodeName = "DebugEdgeCube_" + label;
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

    //Iteratively adjust camera position and look-at to center the ray on landmass centre
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
    //Stage 2: Adjust Z to center the ray on landmass centre
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

        //Stage 2: Adjust position to center the ray
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

        //Stage 4: Adjust to re-center the landmass in the viewport
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

        //Stage 6: Adjust camera position to re-center the landmass in the viewport
        centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, finalCamPos, cameraLookAt, 50.0, 100.0);
        finalCamPos = centredResult.cameraPos;
        cameraLookAt = centredResult.lookAtPos;

        finalCamPos.y += 200;

        //Iteratively move camera closer/further based on edge voxel visibility
        //until all four edges fit within the viewport bounds
        local stepSize = 300.0;
        local maxSteps = 32;

        for(local i = 0; i < maxSteps; i++){
            //Adjust camera to center
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

        //Final adjustment to center
        centredResult = iterativelyAdjustToCenter_(camera, panelPos, panelSize, aabb, finalCamPos, cameraLookAt, 50.0, 100.0);
        finalCamPos = centredResult.cameraPos;
        cameraLookAt = centredResult.lookAtPos;

        //Calculate final position
        //if(finalCamPos.length() > 2000.0){
        //    return null;
        //}

        return {
            "cameraPos": finalCamPos,
            "lookAtPos": cameraLookAt,
            "distance": (finalCamPos - cameraLookAt).length()
        };
    }

}
::OverworldLogic.OverworldStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(OverworldStates.MAX);
    function getLogic(){
        return mData_;
    }
    function getWorld(){
        return mData_.mWorld_;
    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.ZOOMED_OUT] = class extends ::Util.SimpleState{
    mAnim_ = 1.0;
    mInitialised_ = false;

    function start(data){
        mAnim_ = 0.0;
        mInitialised_ = false;
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        //Calculate optimal camera on first update if not yet done
        if(!mInitialised_){
            data.getLogic().calculateAndApplyOptimalCameraZoom_();
            mInitialised_ = true;
        }

        //Use calculated camera position, or fallback to hardcoded values if calculation failed
        local camPos = data.getLogic().mCurrentCameraPosition_;
        local camLookAt = data.getLogic().mCurrentCameraLookAt_;

        if(camPos == null){
            camPos = Vec3(300, 700, 1500);
        }
        if(camLookAt == null){
            camLookAt = Vec3(300, 0, 200);
        }

        if(data.getLogic().mCurrentCameraPosition_ == null){
            data.getLogic().mCurrentCameraPosition_ = camPos;
        }
        if(data.getLogic().mCurrentCameraLookAt_ == null){
            data.getLogic().mCurrentCameraLookAt_ = camLookAt;
        }

        mAnim_ = ::accelerationClampCoordinate_(mAnim_, 0.8, 0.02);
        local a = mAnim_ / 0.8;
        local animPos = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraPosition_, camPos, a);
        local animLookAt = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraLookAt_, camLookAt, a);
        camera.getParentNode().setPosition(animPos);
        camera.lookAt(animLookAt);

        if(mAnim_ >= 0.8){
            data.getLogic().mCurrentCameraPosition_ = camPos;
            data.getLogic().mCurrentCameraLookAt_ = camLookAt;
        }
    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.ZOOMED_IN] = class extends ::Util.SimpleState{
    mAnim_ = 1.0;
    function start(data){
        //local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        //camera.getParentNode().setPosition(0, 150, 300);
        //camera.lookAt(0, 0, 0);
        mAnim_ = 0.0;

        local overworld = data.getWorld();
        overworld.setOverworldSelectionActive(true);
    }

    function end(data){
        local overworld = data.getWorld();
        overworld.setOverworldSelectionActive(false);
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        local overworld = data.getWorld();
        local target = overworld.getTargetCameraPosition();
        local lookAtTarget = overworld.getCameraPosition();
        mAnim_ = ::accelerationClampCoordinate_(mAnim_, 0.8, 0.02);
        local a = mAnim_ / 0.8;
        local animPos = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraPosition_, target, a);
        local animLookAt = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraLookAt_, lookAtTarget, a);
        camera.getParentNode().setPosition(animPos);
        camera.lookAt(animLookAt);

        //data.getLogic().mCurrentCameraPosition_ = target;
        //data.getLogic().mCurrentCameraLookAt_ = lookAtTarget;

        if(mAnim_ >= 0.8){
            data.getLogic().mCurrentCameraPosition_ = target;
            data.getLogic().mCurrentCameraLookAt_ = lookAtTarget;
        }
    }

    function notify(obj, data){
        obj.getWorld().applyMovementDelta(data);
        //mWorld_.applyMovementDelta(delta);
    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.REGION_UNLOCK] = class extends ::Util.SimpleState{
    mStage_ = 0;
    mAnim_ = 0.0;

    mAnimCamPos_ = null;
    mAnimCamLookAt_ = null;

    function start(data){
        local overworld = data.getWorld();
        mAnim_ = 0.0;

        local regionId = overworld.getCurrentSelectedRegion();
        local aabb = overworld.getAABBForRegion(regionId);
        local halfBounds = aabb.getHalfSize();
        local centre = aabb.getCentre();
        local targetPos = centre.copy();
        targetPos.z += halfBounds.z * 6;
        targetPos.y += 40 * 4;
        mAnimCamPos_ = targetPos;
        //mAnimCamPos_.z += 40;
        mAnimCamLookAt_ = centre;
    }

    function end(data){
        local overworld = data.getWorld();
    }

    function update(data){
        if(mStage_ == 0){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

            mAnim_ = ::accelerationClampCoordinate_(mAnim_, 1.0, 0.03);
            local a = ::Easing.easeInQuart(mAnim_);

            local animPos = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraPosition_, mAnimCamPos_, a);
            local animLookAt = ::calculateSimpleAnimation(data.getLogic().mCurrentCameraLookAt_, mAnimCamLookAt_, a);
            camera.getParentNode().setPosition(animPos);
            camera.lookAt(animLookAt);

            if(mAnim_ >= 1.0){
                mAnim_ = 0.0;
                mStage_++;
            }
        }
        else if(mStage_ == 1){
            mAnim_ = ::accelerationClampCoordinate_(mAnim_, 1.0, 0.008);

            local overworld = data.getWorld();
            overworld.updateRegionDiscoveryAnimation(overworld.getCurrentSelectedRegion(), mAnim_);

            if(mAnim_ >= 1.0){
                mAnim_ = 0.0;
                mStage_++;
            }
        }
        else if(mStage_ == 2){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

            mAnim_ = ::accelerationClampCoordinate_(mAnim_, 1.0, 0.06);
            local animPos = ::calculateSimpleAnimation(mAnimCamPos_, data.getLogic().mCurrentCameraPosition_, mAnim_);
            local animLookAt = ::calculateSimpleAnimation(mAnimCamLookAt_, data.getLogic().mCurrentCameraLookAt_, mAnim_);
            camera.getParentNode().setPosition(animPos);
            camera.lookAt(animLookAt);

            if(mAnim_ >= 1.0){
                return OverworldStates.ZOOMED_IN;
            }
        }

    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.TITLE_SCREEN] = class extends ::Util.SimpleState{
    mStage_ = 0;
    mTime_ = 0.0;
    mOrbitRadius_ = 500.0;
    mOrbitHeight_ = 200.0;
    mOrbitSpeed_ = 1.0;
    mCentrePosition_ = null;
    mOrbitAngleRange_ = PI / 2.0;

    mTargetPosition_ = null;
    mMovementTime_ = 0.0;
    mMovementDuration_ = 5.0;
    mStartCentrePosition_ = null;

    mInitialOrbitRadius_ = 2000.0;
    mZoomInDuration_ = 4.0;
    mZoomAnimTime_ = 0.0;

    function start(data){
        mStage_ = 0;
        mTime_ = 0.0;
        mZoomAnimTime_ = 0.0;
        mCentrePosition_ = data.getLogic().calculateOverworldCentre_();
        mStartCentrePosition_ = mCentrePosition_.copy();
        pickNewTargetRegion_(data);
    }

    function pickNewTargetRegion_(data){
        local regionEntries = data.getWorld().mRegionEntries_;
        if(regionEntries.len() == 0){
            mTargetPosition_ = mCentrePosition_.copy();
            return;
        }

        //Update start position to current position for smooth transition (only if target exists)
        if(mStartCentrePosition_ != null && mTargetPosition_ != null){
            mStartCentrePosition_ = ::calculateSimpleAnimation(mStartCentrePosition_, mTargetPosition_, 1.0);
        }

        //Pick a random region
        local regionArray = [];
        foreach(c,i in regionEntries){
            if(i != null){
                regionArray.append(i);
            }
        }

        if(regionArray.len() > 0){
            local randomRegion = regionArray[_random.randIndex(regionArray)];
            local aabb = randomRegion.calculateAABB();
            if(aabb != null){
                mTargetPosition_ = aabb.getCentre();
            }else{
                mTargetPosition_ = mCentrePosition_.copy();
            }
        }else{
            mTargetPosition_ = mCentrePosition_.copy();
        }

        mMovementTime_ = 0.0;
    }

    function update(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);

        //Stage 0: Zoom in from wide view
        if(mStage_ == 0){
            mZoomAnimTime_ += 0.02;

            if(mZoomAnimTime_ >= mZoomInDuration_){
                mZoomAnimTime_ = mZoomInDuration_;
                mStage_ = 1;
            }

            local zoomProgress = mZoomAnimTime_ / mZoomInDuration_;
            zoomProgress = ::Easing.easeInOutQuad(zoomProgress);

            local currentOrbitRadius = ::mix(mInitialOrbitRadius_, mOrbitRadius_, zoomProgress);

            //Apply sin wave for smooth oscillation within the segment
            local oscillation = sin(mTime_ * mOrbitSpeed_);
            local angle = oscillation * mOrbitAngleRange_ * 0.5;

            //Start from a position inside/beyond the ocean edges
            local oceanOffsetRadius = mInitialOrbitRadius_ * 1.2;
            local startAngle = -PI / 4.0;
            local startCamX = sin(startAngle) * oceanOffsetRadius + mCentrePosition_.x;
            local startCamZ = cos(startAngle) * oceanOffsetRadius + mCentrePosition_.z;
            local startCamPos = Vec3(startCamX, mCentrePosition_.y + mOrbitHeight_, startCamZ);

            //Calculate camera position in an arc with interpolated radius
            local camX = sin(angle) * currentOrbitRadius + mCentrePosition_.x;
            local camZ = cos(angle) * currentOrbitRadius + mCentrePosition_.z;
            local camPos = Vec3(camX, mCentrePosition_.y + mOrbitHeight_, camZ);

            //Interpolate from the ocean position to the final position
            local finalCamPos = ::calculateSimpleAnimation(startCamPos, camPos, zoomProgress);

            camera.getParentNode().setPosition(finalCamPos);
            camera.lookAt(mCentrePosition_);

            mTime_ += 0.001;
        }
        //Stage 1: Move around and explore
        else if(mStage_ == 1){
            mTime_ += 0.001;
            mMovementTime_ += 0.02;

            //Check if we need to pick a new target
            if(mMovementTime_ >= mMovementDuration_){
                pickNewTargetRegion_(data);
            }

            //Apply easing to the movement progress
            local movementProgress = mMovementTime_ / mMovementDuration_;
            movementProgress = ::Easing.easeInOutQuad(movementProgress);

            //Interpolate centre position towards target
            local currentCentre = ::calculateSimpleAnimation(mStartCentrePosition_, mTargetPosition_, movementProgress);

            //Apply sin wave for smooth oscillation within the segment
            local oscillation = sin(mTime_ * mOrbitSpeed_);
            local angle = oscillation * mOrbitAngleRange_ * 0.5;

            //Calculate camera position in an arc around the current centre
            local camX = sin(angle) * mOrbitRadius_ + currentCentre.x;
            local camZ = cos(angle) * mOrbitRadius_ + currentCentre.z;
            local camPos = Vec3(camX, currentCentre.y + mOrbitHeight_, camZ);

            //Look at the current centre
            local lookAtPos = currentCentre.copy();

            camera.getParentNode().setPosition(camPos);
            camera.lookAt(lookAtPos);
        }
    }
};

::OverworldLogic.loadMeta();