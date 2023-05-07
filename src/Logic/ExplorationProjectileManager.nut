::ExplorationProjectileManager <- class{

    ProjectileDef = class{
        mPos_ = null;
        mDir_ = null;
        mPhysics_ = null;
        mLifetime_ = 10;
        constructor(pos, dir, physicsShape, lifetime = 10){
            mPos_ = pos;
            mDir_ = dir;
            mPhysics_ = physicsShape;
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

    function spawnProjectile(projId, pos, dir){
        local mesh = _mesh.create("cube");
        mesh.setPosition(pos);
        mesh.setScale(0.1, 0.1, 0.1);

        local senderInfo = {
            "func" : "baseDamage",
            "path" : "res://src/Logic/Scene/ExplorationDamageCallback.nut"
            "id" : mCurrentProjectileId_,
            "type" : _COLLISION_ENEMY,
            "event" : _COLLISION_ENTER
        };
        local shape = _physics.getCubeShape(1.1, 1.1, 1.1);

        local damageSender = _physics.collision[DAMAGE].createSender(senderInfo, shape, pos);
        _physics.collision[DAMAGE].addObject(damageSender);

        local proj = ProjectileDef(pos, dir, damageSender, 6);

        mActiveProjectiles_.rawset(mCurrentProjectileId_, proj);
        mCurrentProjectileId_++;
    }
};