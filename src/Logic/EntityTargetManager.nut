::EntityTargetManager <- class{

    mTargets_ = null;
    mAggressors_ = null;

    TARGET_DISTANCE = 7;

    constructor(){
        //A map containing an array. Entities which target another have their eID as key and an array containing all their targets.
        mTargets_ = {};
        //A map containing an array. Entities which are targeted can query an array of their aggressors.
        mAggressors_ = {};
        //Values are duplicated across two maps to speed up queries.
    }

    function _registerEntityToMap(key, entry, map){
        local outId = -1;
        if(map.rawin(key)){
            local targetArray = map[key];
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
        local targetId = target.getEID();
        local aggressorId = aggressor.getEID();

        local targetArray = null;
        local targetTrackerId = _registerEntityToMap(aggressorId, target, mTargets_);
        _registerEntityToMap(targetId, aggressor, mAggressors_);

        printf("===Targeting entity %i for aggressor %i", targetId, aggressorId);

        return targetTrackerId;
    }

    function removeFromList_(list, id, inner){
        printf("===Removing entry %i from list", inner);
        local targetList = list[id];
        targetList[inner] = null;
        local allNull = true;
        foreach(i in targetList){
            if(i != null){
                allNull = false;
                break;
            }
        }
        if(allNull){
            //Remove the list completely.
            printf("===Destroying contents of list");
            list.rawdelete(id);
        }
    }
    function releaseTargetFromAggressor_(aggressor, targetId){
        local aggressorId = aggressor.getEID();
        printf("===attempting to release target %i", aggressorId);
        if(!mTargets_.rawin(aggressorId)) return;
        local targetList = mTargets_[aggressorId];
        foreach(c,i in targetList){
            if(i == null) continue;
            if(i.getEID() == targetId){
                printf("===found target to release %i", c);
                releaseTarget(aggressor, c);
                return;
            }
        }
    }
    function releaseTarget(aggressor, id){
        local aggressorId = aggressor.getEID();
        local list = mTargets_[aggressorId]
        assert(id >= 0 && id < list.len());
        printf("===Releasing target %i for aggressor %i", aggressorId, list[id].getEID());
        //TODO this might not want to be attack ended as the attack might not be in progress.
        checkEndAttackForEntity(list[id], aggressor);
        //list[id].notifyAttackEnded(aggressor);
        //list[id] = null;
        local entityIndex = findEntityIndexInList(mAggressors_[list[id].getEID()], aggressorId);
        assert(entityIndex != null);
        releaseAggressor_(list[id], entityIndex);
        removeFromList_(mTargets_, aggressorId, id);

    }

    function findEntityIndexInList(list, eid){
        foreach(c,i in list){
            if(i == null) continue;
            if(i.getEID() == eid) return c;
        }
        return null;
    }
    function releaseAggressor_(target, id){
        local targetId = target.getEID();
        printf("===Releasing aggressor %i for target %i", targetId, id);
        local list = mAggressors_[targetId];
        assert(id < list.len());
        checkEndAttackForEntity(list[id], target);
        //list[id].notifyAttackEnded(target);
        removeFromList_(mAggressors_, targetId, id);
    }

    function getTargetForEntity(entity){
        local list = mTargets_[entity.getEID()];
        foreach(i in list){
            if(i != null) return i;
        }
        return null;
    }

    function checkCloseToAttackForList(list, entity, entityId, helper){
        foreach(c,i in list){
            if(i == null) continue;
            local closeToAttack = entityDetermineDistance(entity.getPosition(), i.getPosition());
            if(closeToAttack){
                printf("===List length %i %s", list.len(), helper);
                checkAttackForEntity(entity, i);
                checkAttackForEntity(i, entity);
                //break;
            }else{
                //If this couple is too far away, check if they were previously in combat.
                checkEndAttackForEntity(entity, i);
                checkEndAttackForEntity(i, entity);
            }
        }
    }
    function notifyEntityPositionChange(entity){
        local entityId = entity.getEID();

        //First check the targets to see if we're any closer to them.
        if(mTargets_.rawin(entityId)){
            local targetList = mTargets_[entityId];
            checkCloseToAttackForList(targetList, entity, entityId, "targets");
        }

        //Secondly check through the aggressors to see if they should begin to attack.
        if(mAggressors_.rawin(entityId)){
            local targetList = mAggressors_[entityId];
            checkCloseToAttackForList(targetList, entity, entityId, "aggressors");
        }
    }

    function checkEndAttackForEntity(entity, attacker){
        if(!entity.isMidAttackWithAttacker(attacker.getEID())) return;
        entity.notifyAttackEnded(attacker);
    }
    function checkAttackForEntity(entity, attacker){
        if(entity.isMidAttackWithAttacker(attacker.getEID())) return;
        entity.notifyAttackBegan(attacker);
    }

    function notifyEntityDestroyed(entity){
        local entityId = entity.getEID();
        printf("===Entity %i deceased", entityId);
        if(mAggressors_.rawin(entityId)){
            local list = mAggressors_[entityId];
            printf("===Aggressor list length %i", list.len());
            foreach(c,i in list){
                //local aggressorId = i.getEID();
                //Can't guarantee it'll be in the list as it might've been removed above.
                //assert(mTargets_.rawin(targetId));
                //releaseAggressor(entity, c);

                //Let anyone aggressing (targeting) against us know this entity has died.
                releaseTargetFromAggressor_(i, entityId);
                //releaseAggressor_(entity, c);
            }
        }else{
            printf("===NO aggressors for id %i", entityId);
        }
        if(mTargets_.rawin(entityId)){
            local targetList = mTargets_[entityId];
            foreach(c,i in targetList){
                local targetId = i.getEID();
                assert(mAggressors_.rawin(targetId));
                //mAggressors_[targetId].
                releaseTarget(entity, c);
            }
        }
    }

    function entityDetermineDistance(first, second){
        local distance = first.distance(second);
        //print(distance);
        return distance <= TARGET_DISTANCE;
    }
};