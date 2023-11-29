//A test to check the entity component system.

function start(){
    ::EIDCounter <- 0;
    _doFile("res://../../../src/Logic/Entity/EntityManager.nut");
    _doFile("res://../../../src/Logic/Entity/EntityComponent.nut");
    //Have to separate this out so I have access to the constants.
    _doFile("res://CodeBody.nut");

    local tests = [
        test_createDestroyEntity,
        test_assignComponents,
        test_destroyAllEntities
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}
