function start(){
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

    local data = saveManager.readSaveAtPath("res://saves/basic");
    print(data);
}