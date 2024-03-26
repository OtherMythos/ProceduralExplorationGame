function start(){
    _doFile("res://../../../../../src/Helpers.nut")
    _doFile("res://../../../../../src/Constants.nut")
    _doFile("res://../../../../../src/System/Save/SaveConstants.nut")
    _doFile("res://../../../../../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("res://../../../../../src/System/Save/SaveManager.nut")

    _doFile("res://SaveFileParser0-3-0CodeBody.nut");

    local tests = [
        test_parseBasicFile,
        test_parseV010File,
        test_getDefaultData,
        test_performDataCheck,
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}