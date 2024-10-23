
_t("VersionPool single value", "Check the version pool can store a value and destroy.", function(){
    local pool = ::VersionPool();
    local val = Vec2(10, 20);

    local id = pool.store(val);
    _test.assertEqual(id, 0);
    _test.assertEqual(val, pool.get(id));
    pool.unstore(id);

    id = pool.store(val);
    _test.assertEqual(val, pool.get(id));
    _test.assertEqual(id, 1 << 32);
});

_t("VersionPool multi values", "Check the version pool can store multiple values.", function(){
    local pool = ::VersionPool();
    local valFirst = Vec2(10, 20);
    local valSecond = Vec2(30, 40);
    local valThird = Vec2(50, 60);

    local idFirst = pool.store(valFirst);
    local idSecond = pool.store(valSecond);
    local idThird = pool.store(valThird);

    _test.assertEqual(valFirst, pool.get(idFirst));
    _test.assertEqual(valSecond, pool.get(idSecond));
    _test.assertEqual(valThird, pool.get(idThird));
    _test.assertTrue(pool.valid(idFirst));
    _test.assertTrue(pool.valid(idSecond));
    _test.assertTrue(pool.valid(idThird));

    pool.unstore(idFirst);
    _test.assertFalse(pool.valid(idFirst));
    pool.unstore(idSecond);
    _test.assertFalse(pool.valid(idSecond));
    pool.unstore(idThird);
    _test.assertFalse(pool.valid(idThird));

    _test.assertEqual(pool.mFreeList_.len(), 3);
    local secondIdFirst = pool.store(valFirst);
    local secondIdSecond = pool.store(valSecond);
    local secondIdThird = pool.store(valThird);
    _test.assertEqual(pool.mFreeList_.len(), 0);

    _test.assertEqual(valFirst, pool.get(secondIdFirst));
    _test.assertEqual(valSecond, pool.get(secondIdSecond));
    _test.assertEqual(valThird, pool.get(secondIdThird));

    _test.assertTrue(pool.valid(secondIdFirst));
    _test.assertTrue(pool.valid(secondIdSecond));
    _test.assertTrue(pool.valid(secondIdThird));
});