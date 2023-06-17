//A test to check the entity target manager functions as intended.

::MockEntity <- class{
    mEID_ = 0;
    mAttackers_ = null;
    constructor(){
        mEID_ = ::EIDCounter;
        ::EIDCounter++;

        mAttackers_ = {};
    }
    function getEID(){
        return mEID_;
    }
    function notifyAttackBegan(attacker){
        local attackerId = attacker.getEID();
        mAttackers_[attackerId] <- attacker;
    }
    function notifyAttackEnded(attacker){
        local attackerId = attacker.getEID();
        mAttackers_.rawdelete(attackerId);
    }
    function isMidAttackWithAttacker(attackerId){
        return mAttackers_.rawin(attackerId);
    }
};

function start(){
    ::EIDCounter <- 0;
    _doFile("res://../../../src/Logic/EntityTargetManager.nut")

    local tests = [
        test_targetRelease,
        test_entityDestroyed
    ];
    foreach(i in tests){
        print("======");
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