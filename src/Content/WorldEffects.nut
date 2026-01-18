::WorldEffects <- array(WorldEffectId.MAX, null);

::WorldEffects[WorldEffectId.BROKEN_ROCK] = function(pos, parentSceneNode, world){
    local manager = world.getEntityManager();
    local zPos = world.getZForPos(pos);
    local targetPos = Vec3(pos.x, zPos + 0.3, pos.z);

    local en = manager.createEntity(targetPos);

    local effectNode = parentSceneNode.createChildSceneNode();
    effectNode.setPosition(targetPos);

    local pebblesParticleSystem = _scene.createParticleSystem("brokenRockPebbles");
    effectNode.attachObject(pebblesParticleSystem);

    local dustParticleSystem = _scene.createParticleSystem("brokenRockDust");
    effectNode.attachObject(dustParticleSystem);

    manager.assignComponent(en, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](effectNode, true));
    manager.assignComponent(en, EntityComponents.LIFETIME, ::EntityManager.Components[EntityComponents.LIFETIME](300));

    return en;
}
