::BeeHiveScript <- class{

    mTotalBeesToSpawn_ = 2;
    mBeesToSpawn_ = null;
    mEid_ = null;

    constructor(eid){
        mBeesToSpawn_ = mTotalBeesToSpawn_;
        mEid_ = eid;
    }

    function update(eid){

    }

    function destroyed(eid){
        spawnBee();
        //TODO This is responsible for calling destruction for models, which breaks from the ECS design pattern.
        ::Base.mExplorationLogic.notifyEnemyDestroyed(eid);
    }

    function spawnBee(){
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        local targetPos = world.getEntityManager().getPosition(mEid_);
        world.createEnemy(EnemyId.BEE, targetPos);
    }

    function healthChange(newHealth, percentage, difference){
        print("Bee hive health changed");
        local threshold = 1.0 / mTotalBeesToSpawn_.tofloat();
        for(local i = 1; i < mBeesToSpawn_+1; i++){
            if(percentage < i * threshold){
                mBeesToSpawn_--;
                spawnBee();

                return;
            }
        }
    }

};
