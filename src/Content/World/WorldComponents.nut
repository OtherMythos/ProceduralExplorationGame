::HotSpringsWorldGenComponent <- class extends ::WorldComponent{
    waterCount = 0;
    function update(){
        local playerPos = mWorld_.getPlayerPosition();
        local isInWater = mWorld_.getIsWaterForPosition(playerPos);
        if(isInWater){
            //print("in the hot spring");

            waterCount++;
            if(waterCount % 60 == 0){
                local entityManager = mWorld_.getEntityManager();
                ::_applyHealthChangeOther(entityManager, mWorld_.getPlayerEID(), 1);
            }

        }
    }
};
//NOTE temporary
::DebugCameraSpinComponent <- class extends ::WorldComponent{
    mRotationCounter_ = 0.0;

    function updateLogicPaused(){
        mRotationCounter_ += 0.01;
        if(mRotationCounter_ >= 1000.0){
            mRotationCounter_ = 0.0;
        }

        local angle = mRotationCounter_ * 2 * PI;
        local radius = mWorld_.mCurrentZoomLevel_;

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local playerPos = mWorld_.getPlayerPosition();
        local zPos = mWorld_.getZForPos(playerPos);
        local xOffset = cos(angle) * radius;
        local zOffset = sin(angle) * radius;

        parentNode.setPosition(Vec3(playerPos.x + xOffset, zPos + 20, playerPos.z + zOffset));
        camera.lookAt(playerPos.x, zPos, playerPos.z);
    }
};