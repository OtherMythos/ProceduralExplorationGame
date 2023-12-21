function start(){
    _doFile("res://../../../../../src/System/Save/SaveConstants.nut")
    _doFile("res://../../../../../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("res://../../../../../src/System/Save/SaveManager.nut")

    local tests = [
        test_parseBasicFile
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

    //Assume it doesn't throw an error.
    local data = saveManager.readSaveAtPath("res://saves/basic");

    local brokenFunctions = [
        "res://saves/brokenJSON",
        "res://saves/valueTypeMismatch",
        "res://saves/extraValues",
        "res://saves/invalidVersion"
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