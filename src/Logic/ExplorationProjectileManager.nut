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

    constructor(){
        mActiveProjectiles_ = {};
        mQueuedDestructionProjectiles_ = [];
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
            mActiveProjectiles_.rawdelete(i);
        }
        mQueuedDestructionProjectiles_.clear();
    }

    function spawnProjectile(projId, pos, dir, combatMove, collisionType=_COLLISION_ENEMY){
        local projData = ::Projectiles[projId];

        local senderInfo = {
            "func" : "baseDamage",
            "path" : "res://src/Logic/Scene/ExplorationDamageCallback.nut"
            "id" : mCurrentProjectileId_,
            "type" : collisionType,
            "event" : _COLLISION_ENTER
        };
        local shape = _physics.getCubeShape(projData.mSize);

        local damageSender = _physics.collision[DAMAGE].createSender(senderInfo, shape, pos);
        _physics.collision[DAMAGE].addObject(damageSender);

        local proj = Projectile(pos, dir, damageSender, combatMove, 6);

        mActiveProjectiles_.rawset(mCurrentProjectileId_, proj);
        mCurrentProjectileId_++;
    }
};