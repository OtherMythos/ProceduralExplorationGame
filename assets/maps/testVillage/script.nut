::VisitedWorldScriptObject <- {
    function worldActiveChange(world, active){
        if(!active) return;
        //world.mEntityFactory_.constructEnemy(EnemyId.GOBLIN, Vec3(20, 0, 0), world.mGui_);
        world.mEntityFactory_.constructChestObject(Vec3(20, 0, -10));
        //world.mEntityFactory_.constructEXPOrb(Vec3(10, 0, 0));
    }

    function update(world){
    }
};