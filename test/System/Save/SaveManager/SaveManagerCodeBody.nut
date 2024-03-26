
::test_findMinimumParser <- function(){
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

::test_findParserChain <- function(){
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

::test_performSchemaCheck <- function(){
    local parser = SaveFileParser(0, 1, 0);
    parser.mJSONSchema_ = {
        "version": OBJECT_TYPE.STRING,
        "versionCount": OBJECT_TYPE.INTEGER,
        "meta": OBJECT_TYPE.STRING,

        "playerEXP": OBJECT_TYPE.INTEGER,
        "playerCoins": OBJECT_TYPE.INTEGER,

        "playtimeSeconds": OBJECT_TYPE.INTEGER
    };

    {
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0
        };

        _test.assertTrue(parser.performSchemaCheck(test));
    }

    { //Missing a value
        local test = {
            "version": "0.1.0",
            //"versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0
        };

        _test.assertFalse(parser.performSchemaCheck(test));
    }

    { //Values out of order
        local test = {
            "playerCoins": 0,

            "version": "0.1.0",
            "meta": "",
            "versionCount": 1,
            "playtimeSeconds": 0

            "playerEXP": 0,

        };

        _test.assertTrue(parser.performSchemaCheck(test));
    }

    { //Values with type mismatch.
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0
        };

        //Iterate the table and change the following values.
        local values = [
            null,
            10,
            1.010
            false,
            ["some", "stuff"]
        ];
        foreach(i in values){
            test.version = i;
            _test.assertFalse(parser.performSchemaCheck(test));
        }
    }
}

::test_performSchemaCheckNestedTables <- function(){
    local parser = SaveFileParser(0, 1, 0);
    parser.mJSONSchema_ = {
        "version": OBJECT_TYPE.STRING,
        "versionCount": OBJECT_TYPE.INTEGER,
        "meta": OBJECT_TYPE.STRING,

        "playerEXP": OBJECT_TYPE.INTEGER,
        "playerCoins": OBJECT_TYPE.INTEGER,

        "playtimeSeconds": OBJECT_TYPE.INTEGER

        "testTable": {
            "first": OBJECT_TYPE.INTEGER,
            "second": OBJECT_TYPE.INTEGER
        }
    };


    { //Missing table entry
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0
        };

        //It's missing the table entry so should fail.
        _test.assertFalse(parser.performSchemaCheck(test));
    }

    { //Not a table object
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0,

            "testTable": null
        };

        _test.assertFalse(parser.performSchemaCheck(test));
    }

    { //Table missing a value
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0,

            "testTable": {
                "first": 30
            }
        };

        _test.assertFalse(parser.performSchemaCheck(test));
    }

    { //All values present
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0,

            "testTable": {
                "first": 30,
                "second": 20
            }
        };

        _test.assertTrue(parser.performSchemaCheck(test));
    }

    { //One of the values is the wrong type.
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0,

            "testTable": {
                "first": false,
                "second": 20
            }
        };

        _test.assertFalse(parser.performSchemaCheck(test));
    }

    { //Nested tables
        local test = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,

            "playtimeSeconds": 0,

            "testTable": {
                "first": 10,
                "second": {
                    "other": false,
                    "second": true
                }
            }
        };

        _test.assertFalse(parser.performSchemaCheck(test));

        //Change the schema to accept those types and now things should work.
        parser.mJSONSchema_ = {
            "version": OBJECT_TYPE.STRING,
            "versionCount": OBJECT_TYPE.INTEGER,
            "meta": OBJECT_TYPE.STRING,

            "playerEXP": OBJECT_TYPE.INTEGER,
            "playerCoins": OBJECT_TYPE.INTEGER,

            "playtimeSeconds": OBJECT_TYPE.INTEGER

            "testTable": {
                "first": OBJECT_TYPE.INTEGER,
                "second": {
                    "other": OBJECT_TYPE.BOOL,
                    "second": OBJECT_TYPE.BOOL,
                }
            }
        };

        _test.assertTrue(parser.performSchemaCheck(test));
    }
}

::test_getPreviousParserForObject <- function(){
    local saveManager = ::SaveManager();
    saveManager.mParsers_ = genTestParsers();

    _test.assertEqual(saveManager.getPreviousParserForObject(1, 0, 0).getVersionString(), ::SaveHelpers.versionToString(0, 3, 2));
    _test.assertEqual(saveManager.getPreviousParserForObject(0, 3, 2).getVersionString(), ::SaveHelpers.versionToString(0, 3, 1));
    _test.assertEqual(saveManager.getPreviousParserForObject(2, 0, 0).getVersionString(), ::SaveHelpers.versionToString(1, 6, 0));
    _test.assertEqual(saveManager.getPreviousParserForObject(1, 3, 2).getVersionString(), ::SaveHelpers.versionToString(1, 3, 1));

}