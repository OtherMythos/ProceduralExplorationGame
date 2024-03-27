
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