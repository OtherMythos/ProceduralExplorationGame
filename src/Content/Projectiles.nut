enum ProjectileId{
    NONE,

    FIREBALL,
    AREA,

    MAX
};

::ProjectileDef <- class{
    mDamage = 0;
    mSize = null;
    constructor(damage, size=null){
        mDamage = damage;
        mSize = size;
    }
};

::Projectiles <- array(ProjectileId.MAX, null);

::Projectiles[ProjectileId.NONE] = ProjectileDef(10);
::Projectiles[ProjectileId.FIREBALL] = ProjectileDef(10, Vec3(1, 1, 1));
::Projectiles[ProjectileId.AREA] = ProjectileDef(10, Vec3(5, 5, 5));