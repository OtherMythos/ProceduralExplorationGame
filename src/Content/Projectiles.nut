enum ProjectileId{
    NONE,

    FIREBALL,
    AREA,
    FIRE_AREA,

    MAX
};

::ProjectileDef <- class{
    mDamage = 0;
    mSize = null;
    mMesh = null;
    mLifetime = 100;
    constructor(damage, size=null, mesh=null, lifetime=100){
        mDamage = damage;
        mSize = size;
        mMesh = mesh;
        mLifetime = lifetime;
    }
};

::Projectiles <- array(ProjectileId.MAX, null);

::Projectiles[ProjectileId.NONE] = ProjectileDef(10);
::Projectiles[ProjectileId.FIREBALL] = ProjectileDef(10, Vec3(0.5, 0.5, 0.5), "cube");
::Projectiles[ProjectileId.AREA] = ProjectileDef(10, Vec3(5, 5, 5));
::Projectiles[ProjectileId.FIRE_AREA] = ProjectileDef(10, Vec3(10, 10, 10), "Cylinder.mesh", 2);