::LifetimeMock <- class{
    mCount = 10;
    function update(){
        printf("Updating %i", mCount);
        if(mCount > 0){
            mCount--;
            return true;
        }
        return false;
    }
}

_t("LifetimePool single value", "Check the lifetime pool can store a value and it is destroyed after updates.", function(){
    local pool = ::LifetimePool();

    local id = pool.store(::LifetimeMock());
    _test.assertEqual(pool.mActiveObjects_.len(), 1);
    _test.assertNotEqual(pool.mActiveObjects_[0], null);
    pool.update();
    _test.assertEqual(pool.mActiveObjects_.len(), 1);
    _test.assertNotEqual(pool.mActiveObjects_[0], null);

    for(local i = 0; i < 10; i++){
        pool.update();
    }

    _test.assertEqual(pool.mActiveObjects_.len(), 1);
    _test.assertEqual(pool.mFreeList_.len(), 1);
    _test.assertEqual(pool.mActiveObjects_[0], null);
});

_t("LifetimePool multi values", "Check the lifetime pool can store multiple values.", function(){
    local pool = ::LifetimePool();

    local id = pool.store(::LifetimeMock());
    for(local i = 0; i < 20; i++){
        pool.update();
    }
    _test.assertEqual(pool.mActiveObjects_.len(), 1);
    _test.assertEqual(pool.mFreeList_.len(), 1);
    _test.assertEqual(pool.mActiveObjects_[0], null);

    pool.store(::LifetimeMock());
    _test.assertEqual(pool.mActiveObjects_.len(), 1);
    _test.assertEqual(pool.mFreeList_.len(), 0);
    _test.assertNotEqual(pool.mActiveObjects_[0], null);
    pool.store(::LifetimeMock());
    pool.store(::LifetimeMock());

    _test.assertEqual(pool.mActiveObjects_.len(), 3);
    _test.assertEqual(pool.mFreeList_.len(), 0);
    _test.assertNotEqual(pool.mActiveObjects_[0], null);
    _test.assertNotEqual(pool.mActiveObjects_[1], null);
    _test.assertNotEqual(pool.mActiveObjects_[2], null);
    for(local i = 0; i < 20; i++){
        pool.update();
    }

    _test.assertEqual(pool.mActiveObjects_.len(), 3);
    _test.assertEqual(pool.mFreeList_.len(), 3);
});