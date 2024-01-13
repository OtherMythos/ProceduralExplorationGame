::VisitedWorldScriptObject <- {
    function worldActiveChange(world, active){
        if(!active) return;
        world.createEnemy(EnemyId.GOBLIN, Vec3(20, 0, 0));
        world.mEntityFactory_.constructChestObject(Vec3(world.mMapData_.width/2, 0, -world.mMapData_.height/2));
        //world.mEntityFactory_.constructEXPOrb(Vec3(10, 0, 0));

    }

    function update(world){
    }
};