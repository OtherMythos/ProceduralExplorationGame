::EntityTargetManager <- class{

    mTargets_ = null;
    mAggressors_ = null;

    TARGET_DISTANCE = 5;

    constructor(){
        //A map containing an array. Entities which target another have their eID as key and an array containing all their targets.
        mTargets_ = {};
        //A map containing an array. Entities which are targeted can query an array of their aggressors.
        mAggressors_ = {};
        //Values are duplicated across two maps to speed up queries.
    }

    function _registerEntityToMap(key, entry, map){
        local outId = -1;
        if(map.rawin(entry)){
            local targetArray = map[key];
            assert(!targetArray.rawin(key));
            //TODO turn this into a system of determining holes in the array.
            outId = targetArray.len();
            targetArray.append(entry);
        }else{
            local targetArray = [entry];
            map[key] <- targetArray;
            outId = 0;
        }

        return outId;
    }
    function targetEntity(target, aggressor){
        local targetId = target.getEntity().getId();
        local aggressorId = aggressor.getEntity().getId();

        local targetArray = null;
        local targetTrackerId = _registerEntityToMap(aggressorId, target, mTargets_);
        _registerEntityToMap(targetId, aggressor, mAggressors_);

        return targetTrackerId;
    }

    function removeFromList_(list, id, inner){
        local targetList = list[id];
        targetList[inner] = null;
        local allNull = false;
        foreach(i in targetList){
            if(i != null){
                allNull = false;
                break;
            }
        }
        if(allNull){
            //Remove the list completely.
            list.rawdelete(id);
        }
    }
    function releaseTarget(aggressor, id){
        local aggressorId = aggressor.getEntity().getId();
        local list = mTargets_[aggressorId]
        assert(id < list.len());
        //TODO this might not want to be attack ended as the attack might not be in progress.
        list[id].notifyAttackEnded(aggressor);
        //list[id] = null;
        removeFromList_(mTargets_, aggressorId, id);
    }

    function releaseAggressor_(target, id){
        local targetId = target.getEntity().getId();
        local list = mAggressors_[targetId];
        assert(id < list.len());
        list[id].notifyAttackEnded(target);
        removeFromList_(mAggressors_, targetId, id);
    }

    function getTargetForEntity(entity){
        local list = mTargets_[entity.getEntity().getId()];
        foreach(i in list){
            if(i != null) return i;
        }
        return null;
    }

    function notifyEntityPositionChange(entity){
        local entityId = entity.getEntity().getId();

        //First check the targets to see if we're any closer to them.
        if(mTargets_.rawin(entityId)){
            local targetList = mTargets_[entityId];
            foreach(c,i in targetList){
                local closeToAttack = entityDetermineDistance(entity.getPosition(), i.getPosition());
                if(closeToAttack){
                    checkAttackForEntity(entity, i);
                    checkAttackForEntity(i, entity);
                    return;
                }
            }
        }

        //Secondly check through the aggressors to see if they should begin to attack.
        if(mAggressors_.rawin(entityId)){
            local targetList = mAggressors_[entityId];
            foreach(c,i in targetList){
                local closeToAttack = entityDetermineDistance(entity.getPosition(), i.getPosition());
                if(closeToAttack){
                    checkAttackForEntity(entity, i);
                    checkAttackForEntity(i, entity);
                    return;
                }
            }
        }
    }

    function checkAttackForEntity(entity, attacker){
        if(entity.mAttacker_ != null) return;
        entity.notifyAttackBegan(attacker);
    }

    function notifyEntityDestroyed(entity){
        local entityId = entity.getEntity().getId();
        if(mTargets_.rawin(entityId)){
            local targetList = mTargets_[entityId];
            foreach(c,i in targetList){
                local targetId = i.getEntity().getId();
                assert(mAggressors_.rawin(targetId));
                //mAggressors_[targetId].
                releaseTarget(entity, c);
            }
        }
        if(mAggressors_.rawin(entityId)){
            local list = mAggressors_[entityId];
            foreach(c,i in list){
                local targetId = i.getEntity().getId();
                //Can't guarantee it'll be in the list as it might've been removed above.
                //assert(mTargets_.rawin(targetId));
                //releaseAggressor(entity, c);
                releaseAggressor_(entity, c);
            }
        }
    }

    function entityDetermineDistance(first, second){
        local distance = first.distance(second);
        print(distance);
        return distance <= TARGET_DISTANCE;
    }
};