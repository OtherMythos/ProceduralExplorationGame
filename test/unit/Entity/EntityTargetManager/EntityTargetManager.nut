//A test to check the entity target manager functions as intended.

::EIDCounter <- 0;

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

_t("targetRelease", "Check entities can be targeted and then released from the target", function(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);

    _test.assertEqual(targetManager.mTargets_.len(), 1);
    _test.assertEqual(targetManager.mAggressors_.len(), 1);
    _test.assertEqual(targetManager.mTargets_[player.getEID()][0].getEID(), targetEntity.getEID());
    _test.assertEqual(targetManager.mAggressors_[targetEntity.getEID()][0].getEID(), player.getEID());

    targetManager.releaseTarget(player, targetId);

    _test.assertEqual(targetManager.mTargets_.len(), 0);
    _test.assertEqual(targetManager.mAggressors_.len(), 0);
});

_t("Check Entity Destroyed", "Check the target manager can be notified of an entity's destruction and respond appropriately.", function(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);
    targetManager.notifyEntityDestroyed(targetEntity);

    _test.assertEqual(targetManager.mTargets_.len(), 0);
    _test.assertEqual(targetManager.mAggressors_.len(), 0);
});

_t("Entity Destroyed Multiple Targets", "Check that destroyed entities remove themselves from multiple targets.", function(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();
    local targetEntitySecond = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);
    local targetIdSecond = targetManager.targetEntity(targetEntitySecond, player);

    _test.assertEqual(targetManager.mTargets_.len(), 1);
    //The player is targeting two,
    _test.assertEqual(targetManager.mTargets_[player.getEID()].len(), 2);
    _test.assertFalse(targetManager.mAggressors_.rawin(player.getEID()));
    _test.assertEqual(targetManager.mAggressors_[targetEntity.getEID()].len(), 1);
    _test.assertEqual(targetManager.mAggressors_[targetEntitySecond.getEID()].len(), 1);
    _test.assertEqual(targetManager.mAggressors_.len(), 2);

    targetManager.notifyEntityDestroyed(targetEntity);

    _test.assertEqual(targetManager.mTargets_.len(), 1);
    _test.assertEqual(targetManager.mAggressors_.len(), 1);
});

_t("Entity Destroyed Within Attack Range", "Check that when an entity is destroyed within the attack range the targets are updated", function(){
    local targetManager = EntityTargetManager();
    local player = MockEntity();
    local targetEntity = MockEntity();

    local targetId = targetManager.targetEntity(targetEntity, player);
    local targetIdSecond = targetManager.targetEntity(player, targetEntity);

    player.setPosition(::Vec3_UNIT_X);
    targetEntity.setPosition(::Vec3_UNIT_X);

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
});