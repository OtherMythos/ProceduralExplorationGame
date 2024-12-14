
_t("getLevelForEXP", "Check the function 'getLevelForEXP' returns the correct level for various exp values.", function(){
    local stats = PlayerStats();

    _test.assertEqual(1, stats.getLevelForEXP_(0));
    _test.assertEqual(2, stats.getLevelForEXP_(stats.EXP_LEVELS[1]));
    _test.assertEqual(3, stats.getLevelForEXP_(stats.EXP_LEVELS[2]));
});

_t("getEXPForLevel", "Check the function 'getEXPForLevel' returns the correct minimum EXP for the provided level.", function(){
    local stats = PlayerStats();

    //Realistically though there is no level 0.
    _test.assertEqual(stats.EXP_LEVELS[0], stats.getEXPForLevel(0));

    _test.assertEqual(stats.EXP_LEVELS[0], stats.getEXPForLevel(1));
    _test.assertEqual(stats.EXP_LEVELS[1], stats.getEXPForLevel(2));
    _test.assertEqual(stats.EXP_LEVELS[2], stats.getEXPForLevel(3));
});

_t("getPercentageEXP", "Check the function 'getPercentageEXP' returns an accurate percentage for an amount of EXP.", function(){
    local stats = PlayerStats();

    _test.assertEqual(0.0, stats.getPercentageEXP(0));
    _test.assertEqual(0.5, stats.getPercentageEXP(stats.EXP_LEVELS[2]+(stats.EXP_LEVELS[3]-stats.EXP_LEVELS[2])/2));
    _test.assertEqual(0.5, stats.getPercentageEXP(stats.EXP_LEVELS[3]+(stats.EXP_LEVELS[4]-stats.EXP_LEVELS[3])/2));
});

_t("getLevelForCount", "Check the function 'getLevelForCount' returns the expected level for various counts", function(){
    local stats = PlayerStats();

    _test.assertEqual(0, stats.getLevelForCount(0));

    _test.assertEqual(1, stats.getLevelForCount(1));

    _test.assertEqual(2, stats.getLevelForCount(2));
    _test.assertEqual(2, stats.getLevelForCount(3));

    _test.assertEqual(3, stats.getLevelForCount(4));
    _test.assertEqual(3, stats.getLevelForCount(5));
    _test.assertEqual(3, stats.getLevelForCount(6));
    _test.assertEqual(3, stats.getLevelForCount(7));

    _test.assertEqual(4, stats.getLevelForCount(8));
    _test.assertEqual(4, stats.getLevelForCount(9));
    _test.assertEqual(4, stats.getLevelForCount(10));
    _test.assertEqual(4, stats.getLevelForCount(11));
    _test.assertEqual(4, stats.getLevelForCount(12));
    _test.assertEqual(4, stats.getLevelForCount(13));
    _test.assertEqual(4, stats.getLevelForCount(14));
    _test.assertEqual(4, stats.getLevelForCount(15));

    _test.assertEqual(5, stats.getLevelForCount(16));
});

_t("getTotalForLevel", "Check the function 'getTotalForLevel'", function(){
    local stats = PlayerStats();

    _test.assertEqual(0, stats.getTotalForLevel(0));

    _test.assertEqual(1, stats.getTotalForLevel(1));

    _test.assertEqual(2, stats.getTotalForLevel(2));

    _test.assertEqual(4, stats.getTotalForLevel(3));

    _test.assertEqual(8, stats.getTotalForLevel(4));
});

_t("getLevelTotalForCount", "Check the function 'getLevelTotalForCount'", function(){
    local stats = PlayerStats();

    _test.assertEqual(0, stats.getLevelTotalForCount(0));
    _test.assertEqual(1, stats.getLevelTotalForCount(1));

    _test.assertEqual(2, stats.getLevelTotalForCount(2));

    _test.assertEqual(4, stats.getLevelTotalForCount(5));

    _test.assertEqual(8, stats.getLevelTotalForCount(8));
    _test.assertEqual(8, stats.getLevelTotalForCount(9));
});

_t("getLevelTotalForCount", "Check the function 'getLevelTotalForCount'", function(){
    local stats = PlayerStats();

    _test.assertEqual(0, stats.getLevelTotalForCount(0));
    _test.assertEqual(1, stats.getLevelTotalForCount(1));

    _test.assertEqual(2, stats.getLevelTotalForCount(2));

    _test.assertEqual(4, stats.getLevelTotalForCount(5));

    _test.assertEqual(8, stats.getLevelTotalForCount(8));
    _test.assertEqual(8, stats.getLevelTotalForCount(9));
});

_t("getBiomeDiscoveredData", "Check the function 'getBiomeDiscoveredData'", function(){
    local stats = PlayerStats();

    {
        local d = {
            "foundAmount": 1
        };
        local data = stats.getBiomeDiscoveredData(d);
        print(_prettyPrint(data));
        _test.assertEqual(data.level, 1);
    }
    {
        local d = {
            "foundAmount": 2
        };
        local data = stats.getBiomeDiscoveredData(d);
        print(_prettyPrint(data));
        _test.assertEqual(data.level, 2);
        _test.assertEqual(data.percentageFuture, 0.5);
        _test.assertEqual(data.percentageCurrent, 0);
    }
    {
        local d = {
            "foundAmount": 3
        };
        local data = stats.getBiomeDiscoveredData(d);
        print(_prettyPrint(data));
        _test.assertEqual(data.level, 2);
        _test.assertEqual(data.percentageFuture, 1.0);
        _test.assertEqual(data.percentageCurrent, 0.5);
    }
    {
        local d = {
            "foundAmount": 4
        };
        local data = stats.getBiomeDiscoveredData(d);
        print(_prettyPrint(data));
        _test.assertEqual(data.level, 3);
        _test.assertEqual(data.percentageFuture, 0.25);
        _test.assertEqual(data.percentageCurrent, 0);
    }
    {
        local d = {
            "foundAmount": 5
        };
        local data = stats.getBiomeDiscoveredData(d);
        print(_prettyPrint(data));
        _test.assertEqual(data.level, 3);
        _test.assertEqual(data.percentageFuture, 0.50);
        _test.assertEqual(data.percentageCurrent, 0.25);
    }

});