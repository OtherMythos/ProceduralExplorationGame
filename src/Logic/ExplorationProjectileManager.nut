::ExplorationProjectileManager <- class{

    Projectile = class{
        mPos_ = null;
        mDir_ = null;
        mPhysics_ = null;
        mLifetime_ = 10;
        mCombatMove_ = null;
        constructor(pos, dir, physicsShape, combatMove, lifetime = 10){
            mPos_ = pos;
            mDir_ = dir;
            mPhysics_ = physicsShape;
            mCombatMove_ = combatMove;
            mLifetime_ = lifetime;
        }
    };

    mCurrentProjectileId_ = 0;
    mActiveProjectiles_ = null;
    mQueuedDestructionProjectiles_ = null;
    mDamageWorld_ = null;
    mCreatorWorld_ = null;

    constructor(creatorWorld, damageWorld){
        mCreatorWorld_ = creatorWorld;
        mActiveProjectiles_ = {};
        mQueuedDestructionProjectiles_ = [];
        mDamageWorld_ = damageWorld;
    }

    function shutdown(){

    }

    function update(){
        foreach(c,i in mActiveProjectiles_){
            i.mLifetime_--;
            if(i.mLifetime_ <= 0){
                mQueuedDestructionProjectiles_.append(c);
                continue;
            }
        }

        foreach(i in mQueuedDestructionProjectiles_){
            destroyProjectile_(mActiveProjectiles_[i]);
            mActiveProjectiles_.rawdelete(i);
        }
        mQueuedDestructionProjectiles_.clear();
    }

    function destroyProjectile_(proj){
        mDamageWorld_.removeCollisionPoint(proj.mPhysics_);
    }

    function spawnProjectile(projId, pos, dir, combatMove, collisionType=_COLLISION_ENEMY){
        local en = mCreatorWorld_.mEntityFactory_.constructProjectile(projId, pos, dir, collisionType);

        return en;
        /*

        //local senderInfo = {
        //    "func" : "baseDamage",
        //    "path" : "res://src/Logic/Scene/ExplorationDamageCallback.nut"
        //    "id" : mCurrentProjectileId_,
        //    "type" : collisionType,
        //    "event" : _COLLISION_ENTER
        //};
        //local shape = _physics.getCubeShape(projData.mSize);

        //local damageSender = _physics.collision[DAMAGE].createSender(senderInfo, shape, pos);
        //_physics.collision[DAMAGE].addObject(damageSender);

        local collisionPoint = mDamageWorld_.addCollisionSender(CollisionWorldTriggerResponses.PROJECTILE_DAMAGE, mCurrentProjectileId_, pos.x, pos.z, projData.mSize.x, collisionType);

        local sceneNode = mCreatorWorld_.mParentNode_.createChildSceneNode();
        //sceneNode.set

        local proj = Projectile(pos, dir, collisionPoint, combatMove, 6, sceneNode);

        mActiveProjectiles_.rawset(mCurrentProjectileId_, proj);
        mCurrentProjectileId_++;
        */
    }
};