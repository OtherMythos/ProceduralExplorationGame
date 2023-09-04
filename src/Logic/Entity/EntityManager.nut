/**
 * Entity component system implementation.
 */

enum EntityComponents{

    COLLISION_POINT,
    SCENE_NODE,
    LIFETIME,
    ANIMATION,
    BILLBOARD,
    HEALTH,

    MAX

};

::EntityManager <- {

    MAX_MANAGERS = 0xF
    mCurrentManagers = 0

    function createEntityManager(){
        local manager = EntityManager(mCurrentManagers);
        mCurrentManagers++;

        return manager;
    }

};

EntityManager.ComponentPool <- class{
    mComps_ = null;
    mFreeList_ = null;
    constructor(){
        mComps_ = [];
        mFreeList_ = [];
    }

    function accomodateComponent(eid, component){
        component.eid = eid;
        if(mFreeList_.len() <= 0){
            mComps_.append(component);
        }else{
            local idx = mFreeList_.top();
            mFreeList_.pop();
            mComps_[idx] = component;
        }
    }

    function removeComponent(eid){
        local compIdx = findCompForEid(eid);
        assert(compIdx != null);
        local outComp = mComps_[compIdx];
        mComps_[compIdx] = null;
        mFreeList_.append(compIdx);

        return outComp;
    }

    function findCompForEid(eid){
        foreach(c,i in mComps_){
            if(i == null) continue;
            if(i.eid == eid) return c;
        }
        return null;
    }
    function getCompForEid(eid){
        return mComps_[findCompForEid(eid)];
    }
}

EntityManager.EntityManager <- class{

    mId = 0;

    mEntityComponentHashes_ = null;
    mEntityPositions_ = null;
    mVersions_ = null;
    mFreeList_ = null;
    mComponents_ = null;

    constructor(id){
        mId = id;
        mEntityComponentHashes_ = [];
        mEntityPositions_ = [];
        mVersions_ = [];
        mFreeList_ = [];
        mComponents_ = array(EntityComponents.MAX);

        for(local i = 0; i < EntityComponents.MAX; i++){
            local pool = EntityManager.ComponentPool();
            mComponents_[i] = pool;
        }
    }

    function update(){
        foreach(i in mComponents_[EntityComponents.LIFETIME].mComps_){
            if(i == null) continue;
            i.mLifetime--;
            if(i.mLifetime <= 0){
                destroyEntity(i.eid);
            }
        }
    }

    function entityValid(eid){
        local world = (eid >> 60) & 0xF;
        if(world != mId) return false;
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) return false;

        return true;
    }

    function createEntity(position){
        local entityIdx = -1;
        local entityVersion = 0;
        if(mFreeList_.len() <= 0){
            entityIdx = mEntityComponentHashes_.len();
            entityVersion = 0;
            mEntityComponentHashes_.append(0);
            mEntityPositions_.append(position);
            mVersions_.append(0);
        }else{
            //Use the value from the freelist.
            entityIdx = mFreeList_.top();
            mFreeList_.pop();
            mEntityComponentHashes_[entityIdx] = 0;
            mEntityPositions_[entityIdx] = position;
            entityVersion = mVersions_[entityIdx];
        }
        assert(entityIdx != -1);

        return (mId << 60) | (entityVersion << 30) | entityIdx;
    }

    function destroyEntity(eid){
        // NOTE: The duplication exists because Squirrel doesn't allow a way to inline this and it's a hot path
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        processEntityDestruction_(eid, idx);

        mVersions_[idx]++;
        mEntityComponentHashes_[idx] = null;
        mFreeList_.append(idx);
    }

    function assignComponent(eid, compType, component){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        assignComponent_(idx, eid, compType, component);
    }

    function assignComponent_(idx, eid, compType, component){
        mEntityComponentHashes_[idx] = mEntityComponentHashes_[idx] | (1 << compType);
        mComponents_[compType].accomodateComponent(eid, component);
    }

    function hasComponent(eid, compType){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        return (mEntityComponentHashes_[idx] & (1<<compType)) != 0;
    }

    function getComponent(eid, compType){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        return mComponents_[compType].getCompForEid(eid);
    }

    function removeComponent(eid, compType){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        mComponents_[compType].removeComponent(eid);
        mEntityComponentHashes_[idx] = (mEntityComponentHashes_[idx]) & ~(1 << compType);
    }

    function getPosition(eid){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //
        return mEntityPositions_[idx];
    }

    function setEntityPosition(eid, targetPos){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //
        mEntityPositions_[idx] = targetPos;
        processPositionChange_(eid, idx, targetPos);
    }

    function moveTowards(eid, targetPos, anim){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //
        local pos = mEntityPositions_[idx];
        pos.moveTowards(targetPos, anim);
        processPositionChange_(eid, idx, pos);
    }

    function processPositionChange_(eid, idx, newPos){
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.SCENE_NODE)){
            mComponents_[EntityComponents.SCENE_NODE].getCompForEid(eid).mNode.setPosition(newPos);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_POINT)){
            local comp = mComponents_[EntityComponents.COLLISION_POINT].getCompForEid(eid);
            comp.mCreator.mCollisionWorld_.setPositionForPoint(comp.mPoint, newPos.x, newPos.z);
        }
    }

    function processEntityDestruction_(eid, idx){
        local currentHash = mEntityComponentHashes_[idx];
        for(local i = 0; i < EntityComponents.MAX; i++){
            if(currentHash & (1 << i)){
                local component = mComponents_[i].removeComponent(eid);
                //Check if any logic has to be performed on the component.
                if(i == EntityComponents.SCENE_NODE){
                    if(component.mDestroyOnDestruction){
                        component.mNode.destroyNodeAndChildren();
                    }
                }
                else if(i == EntityComponents.COLLISION_POINT){
                    component.mCreator.removeCollisionPoint(component.mPoint);
                }
            }
        }
    }

};