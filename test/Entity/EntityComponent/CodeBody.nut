::test_createDestroyEntity <- function(){
    local manager = ::EntityManager.createEntityManager();

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

}

::test_assignComponents <- function(){
    local manager = ::EntityManager.createEntityManager();

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
}

//TODO check that destroying an entity destroys all its components.