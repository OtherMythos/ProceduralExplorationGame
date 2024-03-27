_t("createDestroyEntity", "Create an destroy entities as part of an EntityManager", function(){
    local manager = ::EntityManager.createEntityManager(null);

    local entity = manager.createEntity(Vec3());
    _test.assertEqual(entity, 0x0);
    local secondEntity = manager.createEntity(Vec3());
    _test.assertEqual(secondEntity, 0x1);

    manager.destroyEntity(entity);
    {
        local failed = false;
        try{
            //Check it can't be called twice.
            manager.destroyEntity(entity);
        }catch(e){
            failed = true;
        }
        _test.assertTrue(failed);
    }
    {
        local failed = false;
        try{
            //Check an entity from an invalid world can't be destroyed.
            manager.destroyEntity(1 << 60);
        }catch(e){
            failed = true;
        }
        _test.assertTrue(failed);
    }

    //Create another entity and check the version is increased.
    entity = manager.createEntity(Vec3());
    _test.assertEqual(entity, 0x40000000);

    //Destroy should not complain.
    _test.assertTrue(manager.entityValid(entity));
    manager.destroyEntity(entity);
    _test.assertFalse(manager.entityValid(entity));

});

_t("assignComponents", "Assign components to an entity, ensuring they can be queried properly", function(){
    local manager = ::EntityManager.createEntityManager(null);

    local entity = manager.createEntity(Vec3());

    manager.assignComponent(entity, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](10, null));

    _test.assertTrue(manager.hasComponent(entity, EntityComponents.COLLISION_POINT));
    local component = manager.getComponent(entity, EntityComponents.COLLISION_POINT);
    _test.assertNotEqual(component, null);
    _test.assertEqual(component.mPoint, 10);

    //Create a second entity and try the same thing.
    local second = manager.createEntity(Vec3(10, 20, 30));
    manager.assignComponent(second, EntityComponents.COLLISION_POINT, ::EntityManager.Components[EntityComponents.COLLISION_POINT](20, null));
    component = manager.getComponent(second, EntityComponents.COLLISION_POINT);
    _test.assertNotEqual(component, null);
    _test.assertEqual(component.mPoint, 20);

    manager.removeComponent(entity, EntityComponents.COLLISION_POINT);
    _test.assertFalse(manager.hasComponent(entity, EntityComponents.COLLISION_POINT));
});

_t("destroyAllEntities", "Check all entities can be destroyed at once.", function(){
    local manager = ::EntityManager.createEntityManager(null);

    local createEntity = function(entities, i){
        local entity = manager.createEntity(Vec3());
        local healthVal = i * 10;
        manager.assignComponent(entity, EntityComponents.HEALTH, ::EntityManager.Components[EntityComponents.HEALTH](healthVal));
        manager.assignComponent(entity, EntityComponents.SCENE_NODE, ::EntityManager.Components[EntityComponents.SCENE_NODE](null, false));

        _test.assertTrue(manager.hasComponent(entity, EntityComponents.HEALTH));
        local component = manager.getComponent(entity, EntityComponents.HEALTH);
        _test.assertNotEqual(component, null);
        _test.assertEqual(component.mHealth, healthVal);

        print(entity);
        entities.append(entity);
    }

    //Create two entities, each with a component to test the logic.
    local entities = [];
    for(local i = 0; i < 2; i++){
        createEntity(entities, i);
    }

    //Destroy one so there's one destroyed and one active.
    manager.destroyEntity(entities[0]);

    createEntity(entities, 0);

    manager.destroyAllEntities();

});

//TODO check that destroying an entity destroys all its components.