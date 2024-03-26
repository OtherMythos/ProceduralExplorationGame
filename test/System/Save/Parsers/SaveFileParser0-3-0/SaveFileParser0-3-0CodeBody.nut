
::test_parseBasicFile <- function(){
    local saveManager = ::SaveManager();

    //Parse the basic file and ensure it
    local data = saveManager.readSaveAtPath("res://saves/basic");

    local brokenFunctions = [
        "res://saves/failSchema",
    ];
    foreach(i in brokenFunctions){
        local failed = false;
        try{
            saveManager.readSaveAtPath(i);
        }catch(e){
            failed = true;
        }

        _test.assertTrue(failed);
    }

}

::test_parseV010File <- function(){
    local saveManager = ::SaveManager();

    //The system should work the old file type up to be the latest type.
    local data = saveManager.readSaveAtPath("res://../SaveFileParser0-1-0/saves/basic");
    _test.assertTrue(data.rawin("inventory"));
    _test.assertEqual(typeof data.rawget("inventory"), /*OBJECT_TYPE.ARRAY*/ "array");
}

::test_getDefaultData <- function(){
    local saveManager = ::SaveManager();
    local parser = saveManager.getParserObject(0, 3, 0);

    local data = parser.getDefaultData();
    _test.assertTrue(data.rawin("inventory"));
    _test.assertEqual(typeof data.rawget("inventory"), /*OBJECT_TYPE.ARRAY*/ "array");
    _test.assertEqual(data.rawget("version"), "0.3.0");
}

::test_performDataCheck <- function(){
    local saveManager = ::SaveManager();
    local parser = saveManager.getParserObject(0, 3, 0);

    local testData = {};
    //Lower
    testData.inventory <- array(10);
    testData.playerEquipped <- array(2);
    parser.performDataCheck(testData);
    _test.assertEqual(testData.inventory.len(), 35);
    _test.assertEqual(testData.playerEquipped.len(), EquippedSlotTypes.MAX);
    //Higher
    testData.inventory <- array(100);
    testData.playerEquipped <- array(100);
    parser.performDataCheck(testData);
    _test.assertEqual(testData.inventory.len(), 35);
    _test.assertEqual(testData.playerEquipped.len(), EquippedSlotTypes.MAX);
    //entries contain only integers or nulls
    testData.inventory <- array(20, false);
    testData.playerEquipped <- array(30, false);
    parser.performDataCheck(testData);
    foreach(c,i in testData.playerEquipped){
        _test.assertTrue(typeof i == OBJECT_TYPE.INTEGER || typeof i == OBJECT_TYPE.NULL);
    }
    foreach(c,i in testData.inventory){
        _test.assertTrue(typeof i == OBJECT_TYPE.INTEGER || typeof i == OBJECT_TYPE.NULL);
    }

}