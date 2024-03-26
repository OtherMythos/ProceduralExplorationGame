function start(){
    _doFile("res://../../../../../src/Helpers.nut")
    _doFile("res://../../../../../src/Constants.nut")
    _doFile("res://../../../../../src/System/Save/SaveConstants.nut")
    _doFile("res://../../../../../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("res://../../../../../src/System/Save/SaveManager.nut")

    local tests = [
        test_parseBasicFile,
        test_parseV010File,
        test_getDefaultData
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}

function test_parseBasicFile(){
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

function test_parseV010File(){
    local saveManager = ::SaveManager();

    //The system should work the old file type up to be the latest type.
    local data = saveManager.readSaveAtPath("res://../SaveFileParser0-1-0/saves/basic");
    _test.assertTrue(data.rawin("inventory"));
    _test.assertEqual(typeof data.rawget("inventory"), /*OBJECT_TYPE.ARRAY*/ "array");
}

function test_getDefaultData(){
    local saveManager = ::SaveManager();
    local parser = saveManager.getParserObject(0, 3, 0);

    local data = parser.getDefaultData();
    _test.assertTrue(data.rawin("inventory"));
    _test.assertEqual(typeof data.rawget("inventory"), /*OBJECT_TYPE.ARRAY*/ "array");
    _test.assertEqual(data.rawget("version"), "0.3.0");
}