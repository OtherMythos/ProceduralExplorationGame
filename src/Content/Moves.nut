enum MoveId{
    NONE,

    AREA,
    FIREBALL,

    MAX
};

::MoveDef <- class{
    mName_ = null;
    mCooldown_ = 10;
    mProjectile_ = null;
    constructor(name, cooldown=10, projectile=null){
        mName_ = name;
        mCooldown_ = cooldown;
        mProjectile_ = projectile;
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
};

::Moves <- array(MoveId.MAX, null);

::Moves[MoveId.NONE] = MoveDef("None");
::Moves[MoveId.AREA] = MoveDef("Area", 10, ProjectileId.AREA);
::Moves[MoveId.FIREBALL] = MoveDef("Fireball", 50, ProjectileId.FIREBALL);