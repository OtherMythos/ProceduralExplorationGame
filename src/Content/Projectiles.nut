enum ProjectileId{
    NONE,
    FIREBALL,
    AREA,

    MAX
};

::ProjectileDef <- class{
    mDamage_ = 0;
    constructor(damage){
        mDamage_ = damage;
    }
};

::Projectiles <- array(ProjectileId.MAX, null);

::Projectiles[ProjectileId.NONE] = ProjectileDef(10);