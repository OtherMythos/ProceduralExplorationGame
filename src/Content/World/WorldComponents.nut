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