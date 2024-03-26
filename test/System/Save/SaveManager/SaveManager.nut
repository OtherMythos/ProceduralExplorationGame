function start(){
    _doFile("res://../../../../src/Constants.nut")
    _doFile("res://../../../../src/Helpers.nut")
    _doFile("res://../../../../src/System/Save/SaveConstants.nut")
    _doFile("res://../../../../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("res://../../../../src/System/Save/SaveManager.nut")

    _doFile("res://SaveManagerCodeBody.nut")

    ::genTestParsers <- function(){
        return [
            SaveFileParser(0, 1, 0),
            SaveFileParser(0, 2, 0),
            SaveFileParser(0, 3, 0),
            SaveFileParser(0, 3, 1),
            SaveFileParser(0, 3, 2),
            SaveFileParser(1, 0, 0),
            SaveFileParser(1, 1, 0),
            SaveFileParser(1, 2, 0),
            SaveFileParser(1, 3, 0),
            SaveFileParser(1, 3, 1),
            SaveFileParser(1, 3, 2),
            SaveFileParser(1, 6, 0),
            SaveFileParser(2, 0, 0),
        ];
    }

    local tests = [
        test_findMinimumParser,
        test_findParserChain,
        test_performSchemaCheck,
        test_performSchemaCheckNestedTables,
        test_getPreviousParserForObject
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}
