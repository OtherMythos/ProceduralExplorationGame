/**
 * Entity component system implementation.
 */

enum EntityComponents{

    COLLISION_POINT,
    COLLISION_POINT_TWO,
    COLLISION_POINT_THREE,
    COLLISION_POINT_FOUR,
    COLLISION_POINT_FIVE,
    LIFETIME,
    ANIMATION,
    BILLBOARD,
    SPOKEN_TEXT,
    HEALTH,
    SCRIPT,
    SPOILS,
    PROXIMITY,
    DIALOG,
    TRAVERSABLE_TERRAIN,
    COLLISION_DETECTION,
    INVENTORY_ITEMS,
    SCENE_NODE,
    DATABLOCK,
    MOVEMENT,
    STATUS_AFFLICTION,
    STATUS_AFFLICTION_IMMUNITY,
    GIZMO,
    DATABLOCK_ANIMATOR,
    COMPASS_INDICATOR,
    MOVEMENT_PARTICLES,
    POSITION_LIMITER,
    SEPARATION_RADIUS,
    LIMIT_TO_REGION,

    MAX

};

enum EntityDestroyReason{
    NONE,
    LIFETIME,
    NO_HEALTH,
    DESTROY_ALL,
    CONSUMED
};

enum SpoilsComponentType{
    SPOILS_DATA,
    PERCENTAGE,
    GIVE_ITEM,
    EXP_TRAIL,
    ADD_HEALTH,
    GIVE_MONEY,
    SPAWN_EXP_ORBS,
    PICK_KEEP_PLACED_ITEM,
    GIVE_ORB,
    SINGLE_ENEMY
};
enum ProximityComponentType{
    PLAYER,
};

enum CompassIndicatorType{
    PLAYER,
    ENEMY,
    NPC,
    ITEM
};

::EntityManager <- {

    MAX_MANAGERS = 0xF
    mCurrentManagers = 0

    function createEntityManager(creatorWorld){
        local manager = EntityManager(mCurrentManagers, creatorWorld);
        mCurrentManagers++;

        return manager;
    }

};

EntityManager.ComponentPool <- class{
    mComps_ = null;
    mFreeList_ = null;
    mCompLookup_ = null;
    constructor(){
        mComps_ = [];
        mFreeList_ = [];
        mCompLookup_ = {};
    }

    function accomodateComponent(eid, component){
        component.eid = eid;
        local idx = 0;
        if(mFreeList_.len() <= 0){
            idx = mComps_.len();
            mComps_.append(component);
        }else{
            idx = mFreeList_.top();
            mFreeList_.pop();
            mComps_[idx] = component;
        }

        mCompLookup_.rawset(eid, idx);
    }

    function removeComponent(eid){
        local compIdx = findCompForEid(eid);
        assert(compIdx != null);
        local outComp = mComps_[compIdx];
        mComps_[compIdx] = null;
        mFreeList_.append(compIdx);

        mCompLookup_.rawdelete(eid);

        return outComp;
    }

    function findCompForEid(eid){
        local idx = mCompLookup_.rawget(eid);
        return idx;
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

    mCreatorWorld_ = null;

    constructor(id, creatorWorld){
        mId = id;
        mCreatorWorld_ = creatorWorld;
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
                destroyEntity(i.eid, EntityDestroyReason.LIFETIME);
            }
        }
        foreach(i in mComponents_[EntityComponents.SPOKEN_TEXT].mComps_){
            if(i == null) continue;
            i.mLifetime--;
            if(i.mLifetime <= 0){
                processSpokenTextComponentCleanup_(i);
                removeComponent(i.eid, EntityComponents.SPOKEN_TEXT);
            }
        }
        foreach(i in mComponents_[EntityComponents.SCRIPT].mComps_){
            if(i == null) continue;
            i.mScript.update(i.eid);
        }
        foreach(i in mComponents_[EntityComponents.MOVEMENT].mComps_){
            if(i == null) continue;
            moveEntity(i.eid, i.mDirection);
        }
        foreach(i in mComponents_[EntityComponents.STATUS_AFFLICTION].mComps_){
            if(i == null) continue;

            local removed = false;
            foreach(ac,a in i.mAfflictions){
                assert(entityValid(i.eid));
                if(a == null) continue;
                if(a.mTime % 10 == 0){
                    ::_applyDamageOther(this, i.eid, 1);
                }
                //Now damage has been applied there's a chance the entity is now invalid.
                if(!entityValid(i.eid)) return;

                a.mTime++;
                if(a.mTime >= a.mLifetime){
                    i.mAfflictions[ac] = null;
                    printf("Status condition for entity %i ended", i.eid);
                    mCreatorWorld_.processStatusAfflictionChange_(i.eid);
                    removed = true;
                }
            }
            //Check if the component needs to be removed
            if(removed){
                local found = false;
                foreach(a in i.mAfflictions){
                    if(a != null){
                        found = true;
                        break;
                    }
                }
                if(!found){
                    removeComponent(i.eid, EntityComponents.STATUS_AFFLICTION);
                    //mCreatorWorld_.processStatusAfflictionChange_(i.eid);
                }
            }
        }
        foreach(i in mComponents_[EntityComponents.GIZMO].mComps_){
            if(i == null) continue;
            foreach(y in i.mGizmo){
                if(y == null) continue;
                y.update();
            }
        }
        foreach(i in mComponents_[EntityComponents.DATABLOCK_ANIMATOR].mComps_){
            if(i == null) continue;
            i.mAnim = ::accelerationClampCoordinate_(i.mAnim, 0.0, 0.05);

            local comp = getComponent(i.eid, EntityComponents.DATABLOCK);
            comp.mDiffuseOverrideStrength = i.mAnim;
            comp.refreshDiffuseModifiers();
            if(i.mAnim <= 0){
                removeComponent(i.eid, EntityComponents.DATABLOCK_ANIMATOR);
            }
        }
        foreach(i in mComponents_[EntityComponents.MOVEMENT_PARTICLES].mComps_){
            if(i == null) continue;
            i.mParticleSystem.setEmitting(i.mPositionChangedThisFrame);
            i.mPositionChangedThisFrame = false;
        }

        processProximityComponent_();
    }

    function entityValid(eid){
        local world = (eid >> 60) & 0xF;
        if(world != mId) return false;
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) return false;

        return true;
    }

    function isPlayerEntity(eid){
        return ((eid & 0xFFFFFFFFFFFFFFF) == 0);
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

        local outId = (mId << 60) | (entityVersion << 30) | entityIdx;

        print("Created entity with id " + outId);
        return outId;
    }

    function destroyEntity(eid, destroyReason=EntityDestroyReason.NONE){
        // NOTE: The duplication exists because Squirrel doesn't allow a way to inline this and it's a hot path
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        processEntityDestruction_(eid, idx, destroyReason);

        mVersions_[idx]++;
        mEntityComponentHashes_[idx] = null;
        mFreeList_.append(idx);
    }
    function destroyAllEntities(){
        foreach(c,i in mEntityComponentHashes_){
            if(i == null) continue;
            local eid = (c & 0x3FFFFFFF) | ((mVersions_[c] << 30)) | (mId << 60);

            processEntityDestruction_(eid, c, EntityDestroyReason.DESTROY_ALL);
            mEntityComponentHashes_[c] = null;
            mVersions_[c]++;
            mFreeList_.append(c);
        }
        foreach(c,i in mEntityComponentHashes_){
            assert(i == null);
        }
    }

    function assignComponent(eid, compType, component){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //

        assert(!hasComponent(eid, compType));
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

    function checkEntityPositionPotential(eid, newPos){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //
        local oldPos = mEntityPositions_[idx];
        return processEntityPositionPotential_(eid, idx, newPos, oldPos);
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

    function moveEntity(eid, direction){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //
        mEntityPositions_[idx] += direction;
        processPositionChange_(eid, idx, mEntityPositions_[idx]);
    }

    function moveEntityCheckPotential(eid, direction){
        //
        local world = (eid >> 60) & 0xF;
        if(world != mId) throw "Entity does not belong to this world.";
        local version = (eid >> 30) & 0x3FFFFFFF;
        local idx = eid & 0x3FFFFFFF;
        if(mVersions_[idx] != version) throw "Entity is invalid";
        //
        local oldPos = mEntityPositions_[idx];
        local newPos = (oldPos + direction);
        newPos = processEntityPositionPotential_(eid, idx, newPos, oldPos);
        mEntityPositions_[idx] = newPos;

        processPositionChange_(eid, idx, newPos);
    }

    //Helper function to check if a position is valid
    function checkPositionValid_(pos, idx, collisionRadius, collisionHash, ignorePoint, eid){
        //Check traversable terrain
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.TRAVERSABLE_TERRAIN)){
            local c = mComponents_[EntityComponents.TRAVERSABLE_TERRAIN].getCompForEid(eid);
            local traverse = mCreatorWorld_.getTraverseTerrainForPosition(pos);
            if((c.mTraversableTerrain & traverse) == 0){
                return false;
            }
        }
        //Check collision world
        if(collisionRadius != null){
            local w = mCreatorWorld_.getCollisionDetectionWorld();
            if(w.checkCollisionPoint(pos.x, pos.z, collisionRadius, collisionHash, ignorePoint)){
                return false;
            }
        }
        //Check region limit
        if((mEntityComponentHashes_[idx] & (1 << EntityComponents.LIMIT_TO_REGION)) != 0){
            local regionComp = mComponents_[EntityComponents.LIMIT_TO_REGION].getCompForEid(eid);
            local newRegion = mCreatorWorld_.getRegionForPosition(pos);
            if(newRegion != null && newRegion != regionComp.mRegionId){
                return false;
            }
        }
        return true;
    }

    function processEntityPositionPotential_(eid, idx, newPos, oldPos){
        local targetPos = newPos;
        local collisionRadius = null;
        local collisionHash = 0xFF;
        local ignorePoint = null;

        //Check collision detection component for radius and hash
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_DETECTION)){
            local c = mComponents_[EntityComponents.COLLISION_DETECTION].getCompForEid(eid);
            collisionRadius = c.mRadius;
            collisionHash = c.mHash;
            ignorePoint = c.mIgnorePoint;
        }

        //Check position limiter component to prevent moving too far from a set position
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.POSITION_LIMITER)){
            local c = mComponents_[EntityComponents.POSITION_LIMITER].getCompForEid(eid);
            local newPos2D = targetPos.xz();
            if(c.mCentre.distance(newPos2D) > c.mRadius){
                targetPos = oldPos;
            }
        }

        //First try the desired position
        if(checkPositionValid_(targetPos, idx, collisionRadius, collisionHash, ignorePoint, eid)){
            return targetPos;
        }

        //If collision occurred, try sliding along walls
        //Try moving only on X-axis (slide along Z walls)
        local slideX = Vec3(newPos.x, oldPos.y, oldPos.z);
        if(checkPositionValid_(slideX, idx, collisionRadius, collisionHash, ignorePoint, eid)){
            return slideX;
        }

        //Try moving only on Z-axis (slide along X walls)
        local slideZ = Vec3(oldPos.x, oldPos.y, newPos.z);
        if(checkPositionValid_(slideZ, idx, collisionRadius, collisionHash, ignorePoint, eid)){
            return slideZ;
        }

        //No valid sliding position found, return old position (hard stop)
        return oldPos;
    }

    function processPositionChange_(eid, idx, newPos){
        //TODO build up a system where the billboards don't get positioned each from by the scene node.
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.SCENE_NODE)){
            mComponents_[EntityComponents.SCENE_NODE].getCompForEid(eid).mNode.setPosition(newPos);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_POINT)){
            local comp = mComponents_[EntityComponents.COLLISION_POINT].getCompForEid(eid);
            comp.mCreator.setPositionForPoint(comp.mPoint, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_POINT_TWO)){
            local comp = mComponents_[EntityComponents.COLLISION_POINT_TWO].getCompForEid(eid);
            comp.mCreatorFirst.setPositionForPoint(comp.mPointFirst, newPos.x, newPos.z);
            comp.mCreatorSecond.setPositionForPoint(comp.mPointSecond, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_POINT_THREE)){
            local comp = mComponents_[EntityComponents.COLLISION_POINT_THREE].getCompForEid(eid);
            comp.mCreatorFirst.setPositionForPoint(comp.mPointFirst, newPos.x, newPos.z);
            comp.mCreatorSecond.setPositionForPoint(comp.mPointSecond, newPos.x, newPos.z);
            comp.mCreatorThird.setPositionForPoint(comp.mPointThird, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_POINT_FOUR)){
            local comp = mComponents_[EntityComponents.COLLISION_POINT_FOUR].getCompForEid(eid);
            comp.mCreatorFirst.setPositionForPoint(comp.mPointFirst, newPos.x, newPos.z);
            comp.mCreatorSecond.setPositionForPoint(comp.mPointSecond, newPos.x, newPos.z);
            comp.mCreatorThird.setPositionForPoint(comp.mPointThird, newPos.x, newPos.z);
            comp.mCreatorFourth.setPositionForPoint(comp.mPointFourth, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COLLISION_POINT_FIVE)){
            local comp = mComponents_[EntityComponents.COLLISION_POINT_FIVE].getCompForEid(eid);
            comp.mCreatorFirst.setPositionForPoint(comp.mPointFirst, newPos.x, newPos.z);
            comp.mCreatorSecond.setPositionForPoint(comp.mPointSecond, newPos.x, newPos.z);
            comp.mCreatorThird.setPositionForPoint(comp.mPointThird, newPos.x, newPos.z);
            comp.mCreatorFourth.setPositionForPoint(comp.mPointFourth, newPos.x, newPos.z);
            comp.mCreatorFifth.setPositionForPoint(comp.mPointFifth, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.GIZMO)){
            local gizmos = mComponents_[EntityComponents.GIZMO].getCompForEid(eid).mGizmo;
            foreach(g in gizmos){
                if(g == null) continue;
                g.setPosition(newPos)
            }
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.SPOKEN_TEXT)){
            local comp = mComponents_[EntityComponents.SPOKEN_TEXT].getCompForEid(eid);
            if(comp.mSceneNode != null){
                comp.mSceneNode.setPosition(newPos + Vec3(0, comp.mYOffset, 0));
            }
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.COMPASS_INDICATOR)){
            local comp = mComponents_[EntityComponents.COMPASS_INDICATOR].getCompForEid(eid);
            comp.mCreator.setPositionForPoint(comp.mPoint, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.SEPARATION_RADIUS)){
            local comp = mComponents_[EntityComponents.SEPARATION_RADIUS].getCompForEid(eid);
            mCreatorWorld_.mSeparationCollisionWorld_.setPositionForPoint(comp.mPointId, newPos.x, newPos.z);
        }
        if(mEntityComponentHashes_[idx] & (1<<EntityComponents.MOVEMENT_PARTICLES)){
            local comp = mComponents_[EntityComponents.MOVEMENT_PARTICLES].getCompForEid(eid);
            comp.mPositionChangedThisFrame = true;
        }
    }

    function processEntityDestruction_(eid, idx, reason){
        print("Destroying entity with eid " + eid);
        local currentHash = mEntityComponentHashes_[idx];
        for(local i = 0; i < EntityComponents.MAX; i++){
            if(currentHash & (1 << i)){
                local component = mComponents_[i].removeComponent(eid);
                assert(component.eid == eid);
                //Check if any logic has to be performed on the component.
                //TODO convert to a switch statement.
                if(i == EntityComponents.SCENE_NODE){
                    if(component.mDestroyOnDestruction){
                        component.mNode.destroyNodeAndChildren();
                    }
                }
                else if(i == EntityComponents.COLLISION_POINT){
                    component.mCreator.removeCollisionPoint(component.mPoint);
                }
                else if(i == EntityComponents.COLLISION_POINT_TWO){
                    component.mCreatorFirst.removeCollisionPoint(component.mPointFirst);
                    component.mCreatorSecond.removeCollisionPoint(component.mPointSecond);
                }
                else if(i == EntityComponents.COLLISION_POINT_THREE){
                    component.mCreatorFirst.removeCollisionPoint(component.mPointFirst);
                    component.mCreatorSecond.removeCollisionPoint(component.mPointSecond);
                    component.mCreatorThird.removeCollisionPoint(component.mPointThird);
                }
                else if(i == EntityComponents.COLLISION_POINT_FOUR){
                    component.mCreatorFirst.removeCollisionPoint(component.mPointFirst);
                    component.mCreatorSecond.removeCollisionPoint(component.mPointSecond);
                    component.mCreatorThird.removeCollisionPoint(component.mPointThird);
                    component.mCreatorFourth.removeCollisionPoint(component.mPointFourth);
                }
                else if(i == EntityComponents.COLLISION_POINT_FIVE){
                    component.mCreatorFirst.removeCollisionPoint(component.mPointFirst);
                    component.mCreatorSecond.removeCollisionPoint(component.mPointSecond);
                    component.mCreatorThird.removeCollisionPoint(component.mPointThird);
                    component.mCreatorFourth.removeCollisionPoint(component.mPointFourth);
                    component.mCreatorFifth.removeCollisionPoint(component.mPointFifth);
                }
                else if(i == EntityComponents.SCRIPT){
                    if("destroyed" in component.mScript){
                        component.mScript.destroyed(eid, reason);
                    }
                }
                else if(i == EntityComponents.BILLBOARD){
                    ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(component.mBillboard);
                }
                else if(i == EntityComponents.SPOKEN_TEXT){
                    processSpokenTextComponentCleanup_(component);
                }
                else if(i == EntityComponents.DATABLOCK){
                    ::DatablockManager.removeDatablock(component.mDatablock);
                }
                else if(i == EntityComponents.SPOILS){
                    local actuate = false;
                    if(component.mActuateReason == null){
                        actuate = (reason != EntityDestroyReason.LIFETIME && reason != EntityDestroyReason.DESTROY_ALL);
                    }else{
                        actuate = (reason == component.mActuateReason);
                    }

                    if(actuate){
                        mCreatorWorld_.actuateSpoils(eid, component, mEntityPositions_[idx]);
                    }
                }
                else if(i == EntityComponents.GIZMO){
                    foreach(g in component.mGizmo){
                        if(g == null) continue;
                        g.destroy();
                    }
                    component.mGizmo = null;
                }
                else if(i == EntityComponents.COMPASS_INDICATOR){
                    mCreatorWorld_.destroyCompassIndicator_(component.mPoint);
                    component.mCreator.removeCollisionPoint(component.mPoint);
                }
                else if(i == EntityComponents.SEPARATION_RADIUS){
                    mCreatorWorld_.removeSeparationPoint_(component.mPointId);
                }
            }
        }
    }

    function processSpokenTextComponentCleanup_(component){
        ::Base.mExplorationLogic.mGui_.mWorldMapDisplay_.mBillboardManager_.untrackNode(component.mBillboardIdx);
        if(component.mSceneNode != null){
            component.mSceneNode.destroyNodeAndChildren();
        }
    }

    function processProximityComponent_(){
        local playerPos = mCreatorWorld_.getPlayerPosition();
        //TODO could optimise this by including dirty flags.
        foreach(i in mComponents_[EntityComponents.PROXIMITY].mComps_){
            if(i == null) continue;
            local eid = i.eid;
            local currentPosition = mEntityPositions_[eid & 0x3FFFFFFF];
            local distance = currentPosition.distance(playerPos);
            i.mDistance = distance;
            if(i.mCallback != null){
                i.mCallback(this, eid, distance);
            }
        }
    }

};