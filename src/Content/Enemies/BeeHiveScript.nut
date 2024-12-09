::BeeHiveScript <- class{

    mTotalBeesToSpawn_ = 2;
    mBeesToSpawn_ = null;
    mEid_ = null;

    mActiveBees_ = null;

    constructor(eid){
        mBeesToSpawn_ = mTotalBeesToSpawn_;
        mEid_ = eid;
        mActiveBees_ = [];
    }

    function update(eid){
        foreach(i in mActiveBees_){
            if(!i.valid()) continue;
            i.refreshLifetime();
        }
    }

    function destroyed(eid, reason){
        if(reason == EntityDestroyReason.NO_HEALTH){
            spawnBee();
        }
        //TODO This is responsible for calling destruction for models, which breaks from the ECS design pattern.
        ::Base.mExplorationLogic.notifyEnemyDestroyed(eid);
    }

    function spawnBee(){
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        local targetPos = world.getEntityManager().getPosition(mEid_);
        local enemy = world.createEnemy(EnemyId.BEE, targetPos);
        registerBee(enemy);
    }

    function registerBee(beeEntry){
        mActiveBees_.append(beeEntry);
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

        foreach(i in mActiveBees_){
            if(!i.valid()) continue;
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local beeEntity = i.getEID();

            local manager = world.getEntityManager();
            if(!manager.entityValid(beeEntity)) return;
            assert(manager.hasComponent(beeEntity, EntityComponents.SCRIPT));
            local comp = manager.getComponent(beeEntity, EntityComponents.SCRIPT);
            comp.mScript.receiveHiveAttacked();
        }
    }

};
