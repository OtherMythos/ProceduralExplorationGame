//A test to check the entity target manager functions as intended.

::MockEntity <- class{
    mEID_ = 0;
    mAttackers_ = null;
    mPosition_ = null;
    constructor(){
        mEID_ = ::EIDCounter;
        ::EIDCounter++;
        mPosition_ = Vec3();

        mAttackers_ = {};
    }
    function getEID(){
        return mEID_;
    }
    function notifyAttackBegan(attacker){
        local attackerId = attacker.getEID();
        mAttackers_[attackerId] <- attacker;
        printf("===Test attack began for entity %i attacker %i", mEID_, attackerId);
    }
    function notifyAttackEnded(attacker){
        local attackerId = attacker.getEID();
        mAttackers_.rawdelete(attackerId);
        printf("===Test attack ended for entity %i attacker %i", mEID_, attackerId);
    }
    function isMidAttackWithAttacker(attackerId){
        return mAttackers_.rawin(attackerId);
    }
    function setPosition(pos){
        mPosition_ = pos;
    }
    function getPosition(){
        return mPosition_;
    }
};

function start(){
    ::EIDCounter <- 0;
    _doFile("res://../../../src/Logic/EntityTargetManager.nut")

    local tests = [
        test_targetRelease,
        test_entityDestroyed,
        test_entityDestroyedMultipleTargets,
        test_entityDestroyedWithinAttackRange
    ];
    foreach(c,i in tests){
        printf("====== test %i ======", c);
        i();
        print("======");
    }

    _test.endTest();
}

function test_targetRelease(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);

    _test.assertEqual(targetManager.mTargets_.len(), 1);
    _test.assertEqual(targetManager.mAggressors_.len(), 1);
    _test.assertEqual(targetManager.mTargets_[player.getEID()], targetEntity.getEID());
    _test.assertEqual(targetManager.mAggressors_[targetEntity.getEID()], player.getEID());

    targetManager.releaseTarget(player, targetId);

    _test.assertEqual(targetManager.mTargets_.len(), 0);
    _test.assertEqual(targetManager.mAggressors_.len(), 0);
}

function test_entityDestroyed(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);
    targetManager.notifyEntityDestroyed(targetEntity);

    _test.assertEqual(targetManager.mTargets_.len(), 0);
    _test.assertEqual(targetManager.mAggressors_.len(), 0);
}

function test_entityDestroyedMultipleTargets(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();
    local targetEntitySecond = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);
    local targetIdSecond = targetManager.targetEntity(targetEntitySecond, player);

    _test.assertEqual(targetManager.mTargets_.len(), 1);
    //The player is targeting two,
    _test.assertEqual(targetManager.mTargets_[player.getEID()].len(), 2);
    _test.assertEqual(targetManager.mAggressors_.rawin(player.getEID()), 0);
    _test.assertEqual(targetManager.mAggressors_[targetEntity.getEID()].len(), 1);
    _test.assertEqual(targetManager.mAggressors_[targetEntitySecond.getEID()].len(), 1);
    _test.assertEqual(targetManager.mAggressors_.len(), 2);

    targetManager.notifyEntityDestroyed(targetEntity);

    _test.assertEqual(targetManager.mTargets_.len(), 1);
    _test.assertEqual(targetManager.mAggressors_.len(), 1);
}

function test_entityDestroyedWithinAttackRange(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);
    local targetIdSecond = targetManager.targetEntity(player, targetEntity);

    player.setPosition(Vec3(1, 0, 0));
    targetEntity.setPosition(Vec3(1, 0, 0));

    targetManager.notifyEntityPositionChange(player);

    _test.assertEqual(targetManager.mTargets_.len(), 2);
    _test.assertEqual(targetManager.mAggressors_.len(), 2);

    _test.assertEqual(player.mAttackers_.len(), 1);
    _test.assertEqual(targetEntity.mAttackers_.len(), 1);


    targetManager.notifyEntityDestroyed(targetEntity);

    player.setPosition(Vec3(2, 0, 0));
    targetManager.notifyEntityPositionChange(player);

    _test.assertEqual(targetManager.mTargets_.len(), 0);
    _test.assertEqual(targetManager.mAggressors_.len(), 0);

    _test.assertEqual(player.mAttackers_.len(), 0);
}