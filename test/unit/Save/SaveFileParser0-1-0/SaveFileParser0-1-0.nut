
_t("Parse Basic File", "Ensure a simple and complete save file can be parsed as expected.", function(){
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

});

_t("Check 'validatePlayerName()'", "Ensure 'validatePlayerName()' returns the correct modifications to the player name", function(){
    local saveManager = ::SaveManager();
    local parser = saveManager.getParserObject(0, 1, 0);

    local values = [
        "testName",
        "value1234",
        "       testValue",
        "testValue       ",
    ];
    foreach(i in values){
        _test.assertNotEqual(null, parser.validatePlayerName(i));
    }
    values = [
        "testName\nsecond",
        "value1234$$$111",
        "       testValue@@",
        "テスト",
    ];
    foreach(i in values){
        _test.assertEqual(null, parser.validatePlayerName(i));
    }
});