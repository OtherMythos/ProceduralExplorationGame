function start(){
    _doFile("res://../../../src/Constants.nut")
    _doFile("res://../../../src/Content/Places.nut")
    _doFile("res://../../../src/Content/Enemies.nut")
    _doFile("res://../../../src/Content/CombatData.nut")
    _doFile("res://../../../src/System/PlayerStats.nut")

    local tests = [
        test_getLevelForEXP,
        test_getEXPForLevel,
        test_getPercentageEXP
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}

function test_getLevelForEXP(){
    local stats = PlayerStats();

    _test.assertEqual(1, stats.getLevelForEXP_(0));
    _test.assertEqual(2, stats.getLevelForEXP_(stats.EXP_LEVELS[1]));
    _test.assertEqual(3, stats.getLevelForEXP_(stats.EXP_LEVELS[2]));
}

function test_getEXPForLevel(){
    local stats = PlayerStats();

    //Realistically though there is no level 0.
    _test.assertEqual(stats.EXP_LEVELS[0], stats.getEXPForLevel(0));

    _test.assertEqual(stats.EXP_LEVELS[0], stats.getEXPForLevel(1));
    _test.assertEqual(stats.EXP_LEVELS[1], stats.getEXPForLevel(2));
    _test.assertEqual(stats.EXP_LEVELS[2], stats.getEXPForLevel(3));
}

function test_getPercentageEXP(){

    local stats = PlayerStats();

    _test.assertEqual(0.0, stats.getPercentageEXP(0));
    _test.assertEqual(0.5, stats.getPercentageEXP(stats.EXP_LEVELS[2]+(stats.EXP_LEVELS[3]-stats.EXP_LEVELS[2])/2));
    _test.assertEqual(0.5, stats.getPercentageEXP(stats.EXP_LEVELS[3]+(stats.EXP_LEVELS[4]-stats.EXP_LEVELS[3])/2));
}