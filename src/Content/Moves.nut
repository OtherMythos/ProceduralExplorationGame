enum MoveId{
    NONE,

    FIREBALL,
    FIRE_AREA,

    MAX
};

function fireAreaAttack(frame){
    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
    currentWorld.mProjectileManager_.spawnProjectile(ProjectileId.FIRE_AREA, currentWorld.getPlayerPosition(), null, ::Combat.CombatMove(10), _COLLISION_ENEMY);
    return true;
}

::MoveDef <- class{
    mName_ = null;
    mCooldown_ = 10;
    mProjectile_ = null;
    mPerformanceFunction_ = null;
    constructor(name, cooldown=10, projectile=null, performanceFunction=null){
        mName_ = name;
        mCooldown_ = cooldown;
        mProjectile_ = projectile;
        mPerformanceFunction_ = performanceFunction;
    }
    function getName(){
        return mName_;
    }
    function getCooldown(){
        return mCooldown_;
    }
    function getProjectile(){
        return mProjectile_;
    }
    function getPerformanceFunction(){
        return mPerformanceFunction_;
    }
};

::MovePerformance <- class{
    mMoveDef_ = null;
    mFrame_ = 0;

    constructor(moveDef){
        mMoveDef_ = moveDef;
    }

    function update(){
        local f = mMoveDef_.getPerformanceFunction();
        if(f == null) return true;
        local ret = f(mFrame_);
        mFrame_++;
        return ret;
    }
}

::Moves <- array(MoveId.MAX, null);

::Moves[MoveId.NONE] = MoveDef("None");
::Moves[MoveId.FIREBALL] = MoveDef("Fireball", 50, ProjectileId.FIREBALL);
::Moves[MoveId.FIRE_AREA] = MoveDef("Fire Area", 50, ProjectileId.FIRE_AREA, fireAreaAttack);