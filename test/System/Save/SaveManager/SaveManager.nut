function start(){
    _doFile("res://../../../../src/Constants.nut")
    _doFile("res://../../../../src/System/Save/Parsers/SaveFileParser.nut")
    _doFile("res://../../../../src/System/Save/SaveManager.nut")

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
        test_findParserChain
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}

function test_findMinimumParser(){
    local saveManager = ::SaveManager();
    local mockParsers = genTestParsers();

    _test.assertEqual(1, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(0, 2, 0), mockParsers));
    _test.assertEqual(5, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(1, 0, 0), mockParsers));
    _test.assertEqual(2, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(0, 3, 0), mockParsers));
    _test.assertEqual(3, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(0, 3, 1), mockParsers));
    _test.assertEqual(4, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(0, 3, 2), mockParsers));
    //If 1.4.0 didn't come with a parser change then assume it's still compatable with the previous version.
    _test.assertEqual(10, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(1, 4, 0), mockParsers));
    _test.assertEqual(4, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(0, 4, 0), mockParsers));
    _test.assertEqual(12, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(2, 0, 0), mockParsers));
    _test.assertEqual(12, saveManager.findMinimumParser_(::SaveHelpers.hashVersion(5, 0, 0), mockParsers));
}

function test_findParserChain(){
    local saveManager = ::SaveManager();
    local mockParsers = [
        SaveFileParser(0, 1, 0),
        SaveFileParser(0, 2, 0),
        SaveFileParser(0, 3, 1),
        SaveFileParser(1, 0, 0),
    ];

    local chain = saveManager.findParserChain_(::SaveHelpers.hashVersion(0, 2, 0), mockParsers);
    _test.assertEqual(chain.len(), 3);
    _test.assertEqual(chain[0].getHashVersion(), ::SaveHelpers.hashVersion(0, 2, 0));
    _test.assertEqual(chain[1].getHashVersion(), ::SaveHelpers.hashVersion(0, 3, 1));
    _test.assertEqual(chain[2].getHashVersion(), ::SaveHelpers.hashVersion(1, 0, 0));

    chain = saveManager.findParserChain_(::SaveHelpers.hashVersion(0, 4, 0), mockParsers);
    //Starting with version 4 it should be able to identify that it can parse with version 0.3.1
    _test.assertEqual(chain.len(), 2);
    _test.assertEqual(chain[0].getHashVersion(), ::SaveHelpers.hashVersion(0, 3, 1));
    _test.assertEqual(chain[1].getHashVersion(), ::SaveHelpers.hashVersion(1, 0, 0));
}